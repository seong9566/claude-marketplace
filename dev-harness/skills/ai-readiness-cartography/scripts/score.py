#!/usr/bin/env python3
"""AI-Readiness Cartography — repo scorer (v2 rubric, 100 points, 7 categories).

Audits a repository against the 7-category AI-Ready rubric and emits structured
findings, ROI-ranked actions, and a JSON scorecard suitable for the dashboard
template at assets/template.html.

Usage:
    python score.py [repo_path]                # default: .
    python score.py /path/to/repo --json out.json
    python score.py . --markdown               # human-readable to stdout (default)

Pure stdlib — no external dependencies.
"""
from __future__ import annotations

import argparse
import html
import json
import os
import re
import subprocess
import sys
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

# ----------------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------------
IGNORE_DIRS = {
    "node_modules", ".venv", "venv", ".git", ".next", "dist", "build",
    "__pycache__", ".turbo", ".ruff_cache", ".pytest_cache", ".mypy_cache",
    "target", "out", "coverage", ".cache", ".idea", ".vscode",
    # personal fork: .NET / Flutter / iOS / Ruby vendor & build output
    "bin", "obj", "packages", "actions-runner",
    "Pods", "Carthage", "DerivedData", ".symlinks", ".dart_tool", "vendor",
}
CODE_EXTS = {".py", ".ts", ".tsx", ".js", ".jsx", ".go", ".rs", ".java", ".kt", ".rb", ".php", ".sql", ".swift", ".cs", ".dart"}
# generated/codegen files — never hand-edited, so excluded from "god file split" detection
GENERATED_SUFFIXES = (
    ".g.dart", ".freezed.dart", ".gr.dart", ".config.dart", ".gen.dart", ".mocks.dart",
    ".pb.dart", ".pbenum.dart", ".pbjson.dart", ".pbserver.dart",
    ".designer.cs", ".g.cs", ".generated.cs", ".feature.cs",
)
CONTEXT_FILES = ("CLAUDE.md", "AGENTS.md", "README.md")
PRIMARY_CONTEXT = ("CLAUDE.md", "AGENTS.md")  # anything stronger than README

# personal fork: docs/ guide libraries & ADR stores act as context in lieu of per-folder CLAUDE.md
GUIDE_LIB_DIRS = ("docs/flutter_kit", "docs/architecture", "docs/guides", "docs/guide")
ADR_DIRS = ("docs/adr", "docs/decisions", "adr")

# Heuristic regex
RE_PATH_REF = re.compile(
    r"(?<![A-Za-z0-9_/])"
    r"((?:\.{1,2}/|\.?[A-Za-z0-9_]+/)[A-Za-z0-9_./-]+\.(?:py|ts|tsx|js|jsx|mjs|md|sql|json|yaml|yml|toml|html|css|sh|go|rs|java|kt|rb|php|dart|cs|swift))"
)
RE_BASH_FENCE = re.compile(r"```(?:bash|sh|shell|zsh|console)\s*\n([\s\S]*?)```", re.IGNORECASE)
RE_NON_OBVIOUS = re.compile(r"\b(Why:|Note:|Gotcha|Warning|Don't|Caveat|Important:|반드시|주의)", re.IGNORECASE)
RE_REL_LINK = re.compile(r"\[[^\]]+\]\((?!https?://)([^)]+)\)")
RE_DEPS_HEADING = re.compile(r"^#+\s.*(depend|cross[- ]module|imports?|see also|related)", re.IGNORECASE | re.MULTILINE)
RE_PURPOSE_HEADING = re.compile(r"^#+\s.*(purpose|owns?|configures?|overview)", re.IGNORECASE | re.MULTILINE)
RE_PATTERN_HEADING = re.compile(r"^#+\s.*(pattern|how to|common change|workflow|recipe)", re.IGNORECASE | re.MULTILINE)
RE_MERMAID = re.compile(r"```mermaid", re.IGNORECASE)
# TRUE absolute / home paths only — the leading / or ~/ must be at a token boundary
# (not preceded by a word char, ., /, ~, : or -), so internal slashes of a relative
# path like lib/app/x.dart and URL scheme slashes (https://) are NOT matched.
RE_ABS_PATH = re.compile(r"(?<![\w./~:-])(?:/|~/)[\w./-]+\.[A-Za-z0-9]+")
# dependency / call-flow indicators (EN + KO) for guide corpus
RE_FLOW_HINT = re.compile(r"(depends? on|cross[- ]module|호출\s*흐름|호출흐름|데이터\s*흐름|의존|→|컨트롤러?\s*→|controller\s*→)", re.IGNORECASE)


# ----------------------------------------------------------------------------
# Data classes
# ----------------------------------------------------------------------------
@dataclass
class Module:
    path: Path
    rel: str
    code_files: int
    has_context: bool
    context_file: Path | None = None
    context_kind: str = ""  # "CLAUDE.md" | "AGENTS.md" | "README.md" | ""


@dataclass
class CategoryScore:
    name: str
    score: int
    max: int
    evidence: dict[str, Any] = field(default_factory=dict)
    sub_scores: dict[str, int] = field(default_factory=dict)
    findings: list[str] = field(default_factory=list)
    applicable_max: int | None = None  # None → use `max`; lower when sub-checks are N/A
    na: bool = False                   # category not applicable to this workflow (excluded from denom)

    def denom(self) -> int:
        return self.max if self.applicable_max is None else self.applicable_max


@dataclass
class Action:
    title: str
    category: str
    effort: str            # S / M / L
    effort_hours: float
    impact: str            # human-readable
    impact_score: int      # 1-10
    priority: float        # impact / effort_hours


@dataclass
class Report:
    meta: dict[str, Any]
    total: int
    grade: str
    grade_color: str
    categories: dict[str, CategoryScore]
    insights: list[str]
    actions: list[Action]
    extras: dict[str, Any]


# ----------------------------------------------------------------------------
# Discovery
# ----------------------------------------------------------------------------
def walk_files(root: Path) -> list[Path]:
    out: list[Path] = []
    for r, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS and not d.startswith(".")]
        for f in files:
            out.append(Path(r) / f)
    return out


def find_core_modules(repo: Path) -> list[Module]:
    """Top-level + apps/* + packages/* + services/* code-bearing dirs."""
    candidates: list[Path] = []

    # top-level dirs
    for d in sorted(repo.iterdir()):
        if not d.is_dir():
            continue
        if d.name in IGNORE_DIRS or d.name.startswith("."):
            continue
        candidates.append(d)

    # monorepo level
    for parent_name in ("apps", "packages", "services"):
        parent = repo / parent_name
        if parent.exists() and parent.is_dir():
            # remove the parent from candidates if there
            candidates = [c for c in candidates if c != parent]
            for d in sorted(parent.iterdir()):
                if d.is_dir() and d.name not in IGNORE_DIRS:
                    candidates.append(d)

    modules: list[Module] = []
    for d in candidates:
        code_count = 0
        for r, dirs, files in os.walk(d):
            dirs[:] = [x for x in dirs if x not in IGNORE_DIRS and not x.startswith(".")]
            for f in files:
                if Path(f).suffix in CODE_EXTS:
                    code_count += 1
        if code_count == 0:
            continue
        ctx_file, ctx_kind = pick_context_file(d)
        modules.append(Module(
            path=d,
            rel=str(d.relative_to(repo)),
            code_files=code_count,
            has_context=ctx_file is not None,
            context_file=ctx_file,
            context_kind=ctx_kind,
        ))
    return modules


def pick_context_file(d: Path) -> tuple[Path | None, str]:
    for name in CONTEXT_FILES:
        p = d / name
        if p.exists():
            return p, name
    return None, ""


def find_all_context_files(repo: Path) -> list[Path]:
    out: list[Path] = []
    for r, dirs, files in os.walk(repo):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS and not d.startswith(".")]
        for f in files:
            if f in CONTEXT_FILES:
                out.append(Path(r) / f)
    return out


def find_root_claude(repo: Path) -> Path | None:
    p = repo / "CLAUDE.md"
    return p if p.exists() else None


def count_lines(p: Path) -> int:
    try:
        return len(p.read_text(errors="ignore").splitlines())
    except Exception:
        return 0


def read_text(p: Path) -> str:
    try:
        return p.read_text(errors="ignore")
    except Exception:
        return ""


def file_mtime(p: Path) -> float:
    try:
        return p.stat().st_mtime
    except Exception:
        return 0.0


def detect_context_layer(repo: Path) -> dict[str, Any]:
    """Guide libraries (docs/flutter_kit, docs/architecture …) & ADR stores that
    serve as the context layer in lieu of per-folder CLAUDE.md."""
    guides: list[tuple[str, int]] = []
    for rel in GUIDE_LIB_DIRS:
        d = repo / rel
        if d.is_dir():
            md = list(d.rglob("*.md"))
            if md:
                guides.append((rel, len(md)))
    adr: list[tuple[str, int]] = []
    for rel in ADR_DIRS:
        d = repo / rel
        if d.is_dir():
            files = [p for p in d.glob("*.md") if p.name.lower() not in ("readme.md", "_template.md")]
            if files:
                adr.append((rel, len(files)))
    return {
        "guides": guides,
        "adr": adr,
        "guide_doc_count": sum(n for _, n in guides),
        "adr_count": sum(n for _, n in adr),
    }


def guide_corpus(repo: Path, ctx_layer: dict[str, Any]) -> str:
    """Concatenated text of all guide-library docs (for C/D heuristics)."""
    parts: list[str] = []
    for rel, _ in ctx_layer["guides"]:
        for p in (repo / rel).rglob("*.md"):
            parts.append(read_text(p))
    return "\n".join(parts)


def hub_context_files(repo: Path) -> list[Path]:
    """B (Context Document Quality) measures the agent-facing HUB doc(s) — the files
    an agent loads first (root CLAUDE.md / AGENTS.md, or README as fallback). Guide-
    library depth is credited in C/D, not B; averaging B's per-doc checks (bash blocks,
    key files…) across every guide & tooling README only dilutes a real signal."""
    hub = [repo / n for n in ("CLAUDE.md", "AGENTS.md") if (repo / n).exists()]
    if not hub and (repo / "README.md").exists():
        hub = [repo / "README.md"]
    return hub


# documentation placeholders — not real paths, must not count as hallucinations
PLACEHOLDER_TOKENS = ("xxx", "yyy", "...", "<", ">", "{", "}", "your_", "example", "path/to", "도메인", "{domain}")


def check_refs(repo: Path, files: list[Path]) -> tuple[int, list[tuple[Path, str]]]:
    """E1 reference accuracy, FP-hardened:
    - absolute/home paths verified on disk, then masked so the relative scan can't grab
      a fragment of them (external PM-vault handoff path);
    - documentation placeholders (test/xxx.dart …) skipped;
    - a ref resolves if it exists repo-relative, file-relative, OR as a suffix of any
      tracked path (project-subfolder-relative bases that CLAUDE.md documents, e.g.
      .NET `Commons/…` measured from the project folder, not the repo root)."""
    repo_files = {p.relative_to(repo).as_posix() for p in walk_files(repo)}

    def resolvable(ref: str, base: Path) -> bool:
        if any(c.exists() for c in (repo / ref, base / ref)):
            return True
        return ref in repo_files or any(fp.endswith("/" + ref) for fp in repo_files)

    total = 0
    bad: list[tuple[Path, str]] = []
    for p in files:
        text = read_text(p)
        for m in RE_ABS_PATH.finditer(text):
            raw = m.group(0)
            total += 1
            if not Path(raw).expanduser().exists():
                bad.append((p, raw))
        masked = RE_ABS_PATH.sub(" ", text)
        for ref in set(RE_PATH_REF.findall(masked)):
            if any(tok in ref.lower() for tok in PLACEHOLDER_TOKENS):
                continue
            total += 1
            if not resolvable(ref, p.parent):
                bad.append((p, ref))
    return total, bad


# ----------------------------------------------------------------------------
# A. Navigation Coverage
# ----------------------------------------------------------------------------
def score_a(modules: list[Module], root_claude: Path | None, ctx_layer: dict[str, Any]) -> CategoryScore:
    total = max(1, len(modules))
    covered = sum(1 for m in modules if m.has_context)
    per_folder = covered / total

    # personal fork: a guide library + root CLAUDE.md hub provides navigation in lieu
    # of per-folder CLAUDE.md. Credit it so single-app repos aren't scored 0.
    guide_cov = 0.0
    gdc = ctx_layer["guide_doc_count"]
    if gdc >= 1 and root_claude is not None:
        guide_cov = min(0.85, 0.5 + 0.05 * gdc)
    coverage = max(per_folder, guide_cov)

    pts = round(coverage * 15)
    if root_claude is None:
        pts = max(0, pts - 2)
    pts = max(0, min(15, pts))

    findings: list[str] = []
    if guide_cov > per_folder:
        findings.append(
            f"per-folder CLAUDE.md 대신 가이드 라이브러리({', '.join(rel for rel, _ in ctx_layer['guides'])}, "
            f"{gdc}문서)로 내비게이션 — root CLAUDE.md 허브가 인덱싱한다고 가정"
        )
    elif coverage < 1.0:
        gap_modules = [m.rel for m in modules if not m.has_context]
        findings.append(f"context 미보유 핵심 module {len(gap_modules)}개: {', '.join(gap_modules[:6])}")
    if root_claude is None:
        findings.append("root CLAUDE.md 부재 — 진입점 브리핑 없음")

    return CategoryScore(
        name="AI Navigation & Coverage",
        score=pts,
        max=15,
        evidence={
            "core_modules": total,
            "covered_modules": covered,
            "per_folder_coverage": round(per_folder, 3),
            "guide_coverage": round(guide_cov, 3),
            "coverage_ratio": round(coverage, 3),
            "root_claude": str(root_claude.name) if root_claude else None,
        },
        findings=findings,
    )


# ----------------------------------------------------------------------------
# B. Context Document Quality
# ----------------------------------------------------------------------------
def score_b(context_files: list[Path], repo: Path) -> CategoryScore:
    if not context_files:
        return CategoryScore(name="Context Document Quality", score=0, max=20,
                             evidence={"context_files": 0},
                             findings=["context file 자체가 없음"])

    n = len(context_files)
    sub: dict[str, int] = {}

    # B1 Conciseness — 25-35 lines target. Score = 4 * fraction within sane band.
    line_counts = [count_lines(p) for p in context_files]
    concise = sum(1 for ln in line_counts if 10 <= ln <= 80) / n
    sub["B1_Conciseness"] = round(4 * concise)
    over_long = [(p, ln) for p, ln in zip(context_files, line_counts) if ln > 100]

    # B2 Quick Commands — bash fence presence
    quick = sum(1 for p in context_files if RE_BASH_FENCE.search(read_text(p))) / n
    sub["B2_QuickCommands"] = round(4 * quick)

    # B3 Key Files — 3-5 path refs ideal
    key_ratio = 0.0
    for p in context_files:
        text = read_text(p)
        refs = RE_PATH_REF.findall(text)
        uniq = len(set(refs))
        if uniq >= 3:
            key_ratio += 1
        elif uniq >= 1:
            key_ratio += 0.5
    sub["B3_KeyFiles"] = round(4 * key_ratio / n)

    # B4 Non-Obvious patterns
    nonobvious = sum(1 for p in context_files if RE_NON_OBVIOUS.search(read_text(p))) / n
    sub["B4_NonObvious"] = round(4 * nonobvious)

    # B5 See Also / cross refs
    crossref = sum(1 for p in context_files if RE_REL_LINK.search(read_text(p))) / n
    sub["B5_CrossRefs"] = round(4 * crossref)

    pts = sum(sub.values())
    pts = max(0, min(20, pts))

    findings: list[str] = []
    if over_long:
        findings.append(
            f"conciseness 초과(>100 lines) context {len(over_long)}건: "
            + ", ".join(f"{p.relative_to(repo)} ({ln})" for p, ln in over_long[:4])
        )
    if sub["B2_QuickCommands"] < 3:
        findings.append("bash 코드블록이 부족 — quick command 보강 필요")
    if sub["B3_KeyFiles"] < 3:
        findings.append("핵심 파일 경로 인용 부족 — 3-5개 명시 권장")
    if sub["B4_NonObvious"] < 3:
        findings.append("Why/Note/Gotcha 같은 hidden rule 마커 부족")
    if sub["B5_CrossRefs"] < 3:
        findings.append("관련 module / context 간 cross-link 부족")

    return CategoryScore(
        name="Context Document Quality",
        score=pts,
        max=20,
        evidence={
            "context_files": n,
            "max_lines": max(line_counts),
            "min_lines": min(line_counts),
        },
        sub_scores=sub,
        findings=findings,
    )


# ----------------------------------------------------------------------------
# C. Tribal Knowledge Externalization (Five-Question Framework)
# ----------------------------------------------------------------------------
def score_c(modules: list[Module], repo: Path, ctx_layer: dict[str, Any]) -> CategoryScore:
    # Tribal store: MEMORY.md / ADR / decisions / .claude memory
    has_memory = (repo / "MEMORY.md").exists()
    claude_mem_dir_hits = list(repo.glob(".claude/memory*"))
    has_adr = ctx_layer["adr_count"] > 0
    has_tribal_store = has_memory or has_adr or bool(claude_mem_dir_hits)

    # personal fork: Q1-Q4 evaluated over the whole context corpus (per-module context
    # files + root CLAUDE.md + guide-library docs), not just per-folder CLAUDE.md.
    corpus_parts: list[str] = []
    for m in modules:
        if m.context_file:
            corpus_parts.append(read_text(m.context_file))
    rc = find_root_claude(repo)
    if rc:
        corpus_parts.append(read_text(rc))
    corpus_parts.append(guide_corpus(repo, ctx_layer))
    blob = "\n".join(corpus_parts)
    low = blob.lower()

    q1 = bool(RE_PURPOSE_HEADING.search(blob) or "owns" in low or "configures" in low or "역할" in blob)
    q2 = bool(RE_PATTERN_HEADING.search(blob) or "패턴" in blob)
    nonobvious_hits = len(RE_NON_OBVIOUS.findall(blob))
    deps = bool(RE_DEPS_HEADING.search(blob) or RE_FLOW_HINT.search(blob))

    sub = {
        "C_Q1_Owns": 4 if q1 else 0,
        "C_Q2_Patterns": 4 if q2 else 0,
        "C_Q3_NonObvious": 4 if nonobvious_hits >= 3 else (2 if nonobvious_hits >= 1 else 0),
        "C_Q4_Dependencies": 4 if deps else 0,
        "C_Q5_TribalStore": 4 if has_tribal_store else 0,
    }
    pts = max(0, min(20, sum(sub.values())))

    findings: list[str] = []
    if not has_tribal_store:
        findings.append("MEMORY.md / docs/adr / docs/decisions 부재 — tribal knowledge 외부화 store 없음")
    if not deps:
        findings.append("cross-module 의존/호출 흐름 서술이 컨텍스트 코퍼스에 없음")
    if not q2:
        findings.append("common modification patterns / 패턴 가이드 부재")

    return CategoryScore(
        name="Tribal Knowledge Externalization",
        score=pts,
        max=20,
        evidence={
            "memory_md": has_memory,
            "adr": has_adr,
            "adr_count": ctx_layer["adr_count"],
            "guide_doc_count": ctx_layer["guide_doc_count"],
            "nonobvious_markers": nonobvious_hits,
        },
        sub_scores=sub,
        findings=findings,
    )


# ----------------------------------------------------------------------------
# D. Cross-Module Dependency & Data Flow Mapping
# ----------------------------------------------------------------------------
def score_d(repo: Path, context_files: list[Path], ctx_layer: dict[str, Any]) -> CategoryScore:
    # personal fork: docs/architecture/ as a DIRECTORY (not just a single file), and
    # the flutter_kit architecture guide, both count as a dependency/data-flow map.
    has_arch = any((repo / p).exists() for p in (
        "ARCHITECTURE.md", "docs/architecture.md", "docs/ARCHITECTURE.md",
        "docs/dependency-graph.md", "docs/data-flow.md",
    )) or (repo / "docs" / "architecture").is_dir() \
        or (repo / "docs" / "flutter_kit" / "flutter-architecture").is_dir()

    gcorpus = guide_corpus(repo, ctx_layer)
    has_mermaid = any(RE_MERMAID.search(read_text(p)) for p in context_files) or bool(RE_MERMAID.search(gcorpus))
    deps_in_ctx = sum(1 for p in context_files if RE_DEPS_HEADING.search(read_text(p)) or RE_FLOW_HINT.search(read_text(p)))
    deps_in_guides = bool(RE_DEPS_HEADING.search(gcorpus) or RE_FLOW_HINT.search(gcorpus))

    # personal fork: .NET solution (.sln) and Flutter workspace (pubspec/melos) make the
    # dependency graph derivable, same as a JS monorepo workspace.
    has_workspace = any((repo / f).exists() for f in (
        "turbo.json", "nx.json", "pnpm-workspace.yaml", "lerna.json", "melos.yaml",
    )) or bool(list(repo.glob("*.sln"))) or (repo / "pubspec.yaml").exists()

    pts = 0
    if has_arch:
        pts += 6
    if has_mermaid:
        pts += 3
    if deps_in_ctx >= max(1, len(context_files) // 2) or deps_in_guides:
        pts += 4
    elif deps_in_ctx >= 1:
        pts += 2
    if has_workspace:
        pts += 2  # graph derivable
    pts = max(0, min(15, pts))

    findings: list[str] = []
    if not has_arch:
        findings.append("ARCHITECTURE.md / docs/architecture / dependency map 부재")
    if not has_mermaid:
        findings.append("mermaid 다이어그램 없음 — 시각적 의존도 표현 부재")
    if deps_in_ctx == 0 and not deps_in_guides:
        findings.append("컨텍스트·가이드 어디에도 cross-module 의존/호출 흐름 서술 없음")

    return CategoryScore(
        name="Cross-Module Dependency Mapping",
        score=pts,
        max=15,
        evidence={
            "architecture_doc": has_arch,
            "mermaid_diagrams": has_mermaid,
            "context_with_deps_section": deps_in_ctx,
            "guide_has_flow": deps_in_guides,
            "workspace_or_solution": has_workspace,
        },
        findings=findings,
    )


# ----------------------------------------------------------------------------
# E. Verification & Quality Gates
# ----------------------------------------------------------------------------
def score_e(repo: Path, context_files: list[Path]) -> CategoryScore:
    sub: dict[str, int] = {}

    # E1 Reference accuracy (FP-safe: absolute/home paths verified, then masked)
    total_refs, bad_refs = check_refs(repo, context_files)
    if total_refs == 0:
        sub["E1_RefAccuracy"] = 2  # neutral — nothing to verify
    else:
        accuracy = (total_refs - len(bad_refs)) / total_refs
        sub["E1_RefAccuracy"] = round(5 * accuracy)

    # E2 Critic / review infra — N/A for this workflow.
    # File-based critic (CODEOWNERS/PR template) doesn't fit a near-solo repo whose
    # independent review is the Codex-PR-review process (no in-repo signal). Excluded
    # from the denominator (applicable_max below) instead of scored 0.

    # E3 Task validation commands actually exist (personal fork: + .NET / Flutter)
    have_pkg_json = (repo / "package.json").exists()
    have_pyproject = (repo / "pyproject.toml").exists() or any(repo.glob("**/pyproject.toml"))
    have_make = (repo / "Makefile").exists()
    have_dotnet = bool(list(repo.glob("*.sln"))) or bool(list(repo.glob("**/*.csproj")))
    have_flutter = (repo / "pubspec.yaml").exists()
    have_workflows = (repo / ".github" / "workflows").exists()
    e3 = 0
    if have_pkg_json or have_pyproject or have_make or have_dotnet or have_flutter:
        e3 += 2
    if have_workflows:
        e3 += 1
    if have_dotnet or have_flutter:
        e3 += 1  # typed build = strong task validation
    sub["E3_TaskValidation"] = min(4, e3)

    # E4 Prompt / agent eval tests
    has_evals = any((repo / p).exists() for p in ("evals", "benchmarks", "agent-evals", "prompts/test", "tests/agent"))
    sub["E4_PromptTests"] = 2 if has_evals else 0

    pts = max(0, min(11, sum(sub.values())))  # applicable max = 11 (E2 excluded)

    findings: list[str] = []
    if bad_refs:
        sample = ", ".join(f"{p.name}: {ref}" for p, ref in bad_refs[:4])
        findings.append(f"hallucinated path {len(bad_refs)}건 (총 {total_refs} 참조 중) — 예: {sample}")
    findings.append("E2(CODEOWNERS/PR템플릿) = N/A — 독립 리뷰는 Codex PR 리뷰 프로세스(repo 내 신호 없음)")
    if not has_evals:
        findings.append("agent eval / prompt test 디렉터리 없음 (E4)")

    return CategoryScore(
        name="Verification & Quality Gates",
        score=pts,
        max=15,
        applicable_max=11,
        evidence={
            "ref_total": total_refs,
            "ref_broken": len(bad_refs),
            "e2_status": "N/A (process-based review)",
            "ci_workflows": have_workflows,
            "dotnet_build": have_dotnet,
            "flutter_build": have_flutter,
            "evals_dir": has_evals,
        },
        sub_scores=sub,
        findings=findings,
    )


# ----------------------------------------------------------------------------
# F. Freshness & Self-Maintenance
# ----------------------------------------------------------------------------
def latest_code_mtime(d: Path) -> float:
    latest = 0.0
    for r, dirs, files in os.walk(d):
        dirs[:] = [x for x in dirs if x not in IGNORE_DIRS and not x.startswith(".")]
        for f in files:
            if Path(f).suffix in CODE_EXTS:
                latest = max(latest, file_mtime(Path(r) / f))
    return latest


def score_f(modules: list[Module], repo: Path) -> CategoryScore:
    # Drift: how many modules' context is older than their newest code file
    drifted = 0
    measurable = 0
    for m in modules:
        if not m.context_file:
            continue
        ctx_mtime = file_mtime(m.context_file)
        code_mtime = latest_code_mtime(m.path)
        if code_mtime == 0:
            continue
        measurable += 1
        # 30-day staleness window
        if ctx_mtime + 30 * 86400 < code_mtime:
            drifted += 1
    drift_ratio = (drifted / measurable) if measurable else 0.0

    if measurable == 0:
        # personal fork: no per-folder context to measure — fall back to guide library +
        # root CLAUDE.md freshness vs the newest code file in the whole repo.
        ctx_mtimes: list[float] = []
        rc = find_root_claude(repo)
        if rc:
            ctx_mtimes.append(file_mtime(rc))
        for rel in GUIDE_LIB_DIRS:
            d = repo / rel
            if d.is_dir():
                ctx_mtimes.extend(file_mtime(p) for p in d.rglob("*.md"))
        code_mtime = latest_code_mtime(repo)
        if ctx_mtimes and code_mtime:
            measurable = 1
            if max(ctx_mtimes) + 30 * 86400 < code_mtime:
                drifted = 1
            drift_ratio = drifted / measurable

    # CI / hook validators
    workflows = list((repo / ".github" / "workflows").glob("*.yml")) + list((repo / ".github" / "workflows").glob("*.yaml")) if (repo / ".github" / "workflows").exists() else []
    ctx_validation_workflow = any(
        re.search(r"context|docs|claude|adr|reference", read_text(w), re.IGNORECASE)
        for w in workflows
    )
    # personal fork: .claude/hooks/ (flutter-kit-review, pre-commit-build, post-build …)
    # is this stack's commit/build-time validator, same role as a husky hook.
    claude_hooks = repo / ".claude" / "hooks"
    has_claude_hooks = claude_hooks.is_dir() and any(claude_hooks.iterdir())
    hook_validates_paths = (
        (repo / ".husky" / "pre-commit").exists()
        or (repo / ".husky" / "pre-push").exists()
        or has_claude_hooks
    )

    pts = 0
    if measurable:
        # up to 6 pts for low drift
        pts += round(6 * (1 - drift_ratio))
    if ctx_validation_workflow:
        pts += 2
    if hook_validates_paths:
        pts += 2
    pts = max(0, min(10, pts))

    findings: list[str] = []
    if drifted:
        findings.append(f"{drifted}/{measurable} module의 context가 코드 변경 후 30일 이상 미갱신")
    if not ctx_validation_workflow:
        findings.append("CI에 context / docs validation step 없음")
    if not hook_validates_paths:
        findings.append("commit/build 시점 검증 hook 없음 (.husky 또는 .claude/hooks)")

    return CategoryScore(
        name="Freshness & Self-Maintenance",
        score=pts,
        max=10,
        evidence={
            "drifted_modules": drifted,
            "measurable_modules": measurable,
            "drift_ratio": round(drift_ratio, 3),
            "ctx_validation_workflow": ctx_validation_workflow,
            "hook_validates_paths": hook_validates_paths,
        },
        findings=findings,
    )


# ----------------------------------------------------------------------------
# G. Agent Performance Outcomes
# ----------------------------------------------------------------------------
def score_g(repo: Path) -> CategoryScore:
    eval_dirs = [p for p in ("evals", "benchmarks", "agent-evals", "agent-metrics") if (repo / p).exists()]
    metric_files = list(repo.glob("**/agent-results.json")) + list(repo.glob("**/.skill-eval.json"))
    metric_files = [m for m in metric_files if not any(seg in m.parts for seg in IGNORE_DIRS)]
    has_telemetry_hint = any(
        re.search(r"telemetry|opentelemetry|claude.*session|agent.*log",
                  read_text(p), re.IGNORECASE)
        for p in (repo / "CLAUDE.md", repo / "README.md", repo / "AGENTS.md")
        if p.exists()
    )

    pts = 0
    if eval_dirs:
        pts += 3
    if metric_files:
        pts += 1
    if has_telemetry_hint:
        pts += 1
    pts = max(0, min(5, pts))

    # N/A for this workflow: agent-outcome signal lives in the external PM-vault handoff
    # ledger (no in-repo, MCP-free signal score.py can read). Excluded from denominator.
    findings = ["N/A — 성과 신호는 외부 PM vault handoff ledger(코드 repo 밖). 점수 분모에서 제외."]

    return CategoryScore(
        name="Agent Performance Outcomes",
        score=pts,
        max=5,
        applicable_max=0,
        na=True,
        evidence={
            "status": "N/A (outcomes tracked in external PM vault)",
            "eval_dirs": eval_dirs,
            "metric_files": [str(p.relative_to(repo)) for p in metric_files],
            "telemetry_hint": has_telemetry_hint,
        },
        findings=findings,
    )


# ----------------------------------------------------------------------------
# Bonus / extras: large files, naming hints
# ----------------------------------------------------------------------------
def find_large_files(repo: Path, threshold: int = 300) -> list[tuple[Path, int]]:
    out: list[tuple[Path, int]] = []
    for p in walk_files(repo):
        if p.suffix not in CODE_EXTS:
            continue
        if p.name.endswith(GENERATED_SUFFIXES):  # skip codegen output
            continue
        ln = count_lines(p)
        if ln > threshold:
            out.append((p, ln))
    out.sort(key=lambda x: -x[1])
    return out


# ----------------------------------------------------------------------------
# Grade & ROI
# ----------------------------------------------------------------------------
def grade_label(total: int) -> tuple[str, str]:
    if total >= 90:
        return "AI-Native", "green"
    if total >= 75:
        return "AI-Ready", "green"
    if total >= 60:
        return "AI-Assisted", "amber"
    if total >= 40:
        return "AI-Fragile", "amber"
    return "AI-Hostile", "red"


def derive_actions(report_partial: dict[str, CategoryScore], modules: list[Module],
                    large_files: list[tuple[Path, int]], repo: Path,
                    ctx_layer: dict[str, Any]) -> list[Action]:
    actions: list[Action] = []
    A, B, C, D, E, F, G = (report_partial[k] for k in "ABCDEFG")

    # A — missing per-folder context (skip if a guide library already provides navigation)
    missing = [m.rel for m in modules if not m.has_context]
    if missing and ctx_layer["guide_doc_count"] == 0:
        actions.append(Action(
            title=f"{len(missing)}개 핵심 module에 CLAUDE.md 신설 ({', '.join(missing[:3])}{'…' if len(missing) > 3 else ''})",
            category="A",
            effort="S", effort_hours=0.5 * len(missing),
            impact=f"task당 ~3 min × ~5 task/일 절감 → 모듈 1개당 주 1-2 hr 회수",
            impact_score=9,
            priority=9 / max(0.5, 0.5 * len(missing)),
        ))

    # B — over-long context
    if B.evidence.get("max_lines", 0) > 100:
        actions.append(Action(
            title="과도한 CLAUDE.md를 25-35 lines로 압축 (compass-not-encyclopedia)",
            category="B",
            effort="M", effort_hours=2.0,
            impact="agent context 로드 시간 단축 + 핵심 정보 가시성 ↑",
            impact_score=7,
            priority=7 / 2.0,
        ))

    # C — no MEMORY/ADR
    if not C.evidence.get("memory_md") and not C.evidence.get("adr"):
        actions.append(Action(
            title="MEMORY.md 또는 docs/adr/ 도입으로 tribal knowledge 외부화",
            category="C",
            effort="M", effort_hours=3.0,
            impact="senior 의존 의사결정 외부화 → 신규 agent run 시 오류 ↓",
            impact_score=8,
            priority=8 / 3.0,
        ))

    # D — no architecture doc
    if not D.evidence.get("architecture_doc"):
        actions.append(Action(
            title="ARCHITECTURE.md 또는 mermaid dependency 다이어그램 추가",
            category="D",
            effort="M", effort_hours=2.5,
            impact="cross-module ripple 추적 → 변경 영향 분석 시간 절반",
            impact_score=7,
            priority=7 / 2.5,
        ))

    # E1 — broken refs
    if E.evidence.get("ref_broken", 0) > 0:
        actions.append(Action(
            title=f"context의 hallucinated path {E.evidence['ref_broken']}건 수정 (referential trust)",
            category="E",
            effort="S", effort_hours=0.5,
            impact="agent의 잘못된 path-following 방지 — stale = worse than missing",
            impact_score=10,
            priority=10 / 0.5,
        ))

    # E — no path validation in CI
    if not F.evidence.get("ctx_validation_workflow") and not F.evidence.get("hook_validates_paths"):
        actions.append(Action(
            title="CI 또는 pre-push hook에 context path 검증 추가",
            category="F",
            effort="S", effort_hours=1.0,
            impact="stale reference를 코드 머지 시점에 차단 — 회귀 방지",
            impact_score=8,
            priority=8 / 1.0,
        ))

    # 7 (large files) — included in B/C symptom but suggested separately
    huge = [(p, ln) for p, ln in large_files if ln > 500]
    if huge:
        sample = ", ".join(f"{p.relative_to(repo).as_posix()} ({ln})" for p, ln in huge[:3])
        actions.append(Action(
            title=f"god file {len(huge)}개 분할 (>500 lines): {sample}",
            category="B",
            effort="L", effort_hours=2.5 * len(huge),
            impact=f"파일당 ~5K-10K token 절감 + 편집 정확도 ↑",
            impact_score=6,
            priority=6 / max(2.5, 2.5 * len(huge)),
        ))

    # G — no eval infra (skip when G is N/A for this workflow)
    if G.score < 3 and not G.na:
        actions.append(Action(
            title="evals/ 디렉터리 + 대표 task pass-rate 측정 도입",
            category="G",
            effort="L", effort_hours=6.0,
            impact="AI 회귀 측정 가능 — 개선 ROI 자체를 정량화",
            impact_score=6,
            priority=6 / 6.0,
        ))

    actions.sort(key=lambda a: -a.priority)
    return actions


# ----------------------------------------------------------------------------
# Generate insights
# ----------------------------------------------------------------------------
def generate_insights(cats: dict[str, CategoryScore], total: int) -> list[str]:
    out: list[str] = []
    grade, _ = grade_label(total)
    out.append(f"총점 {total}/100 · 등급 {grade}")

    # weakest categories (exclude N/A; use applicable denominator)
    ranked = sorted(((k, c) for k, c in cats.items() if not c.na),
                    key=lambda kv: kv[1].score / max(1, kv[1].denom()))
    for k, c in ranked[:2]:
        out.append(f"가장 낮은 카테고리: {k} {c.name} {c.score}/{c.denom()}")

    # E1 hallucination is special
    e = cats.get("E")
    if e and e.evidence.get("ref_broken", 0) > 0:
        out.append(
            f"⚠️  context에 hallucinated path {e.evidence['ref_broken']}건 — Meta 기준으로는 0이어야 함"
        )

    # F freshness
    f = cats.get("F")
    if f and f.evidence.get("drift_ratio", 0) > 0.3:
        out.append(f"context drift 높음 ({f.evidence['drift_ratio']:.0%}) — stale 위험")

    return out


# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------
def git_branch(repo: Path) -> str:
    try:
        r = subprocess.run(
            ["git", "-C", str(repo), "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True, text=True, timeout=5,
        )
        return r.stdout.strip() or "unknown"
    except Exception:
        return "unknown"


def build_report(repo: Path) -> Report:
    modules = find_core_modules(repo)
    context_files = find_all_context_files(repo)
    root_claude = find_root_claude(repo)
    large_files = find_large_files(repo, 300)
    ctx_layer = detect_context_layer(repo)

    b_files = hub_context_files(repo)
    cats = {
        "A": score_a(modules, root_claude, ctx_layer),
        "B": score_b(b_files, repo),
        "C": score_c(modules, repo, ctx_layer),
        "D": score_d(repo, context_files, ctx_layer),
        "E": score_e(repo, context_files),
        "F": score_f(modules, repo),
        "G": score_g(repo),
    }
    for c in cats.values():
        if c.na:
            c.score = 0
    raw_total = sum(c.score for c in cats.values() if not c.na)
    applicable_max = sum(c.denom() for c in cats.values()) or 1
    # personal fork: renormalize to /100 over applicable categories (E2 + G excluded as N/A)
    total = min(100, round(raw_total / applicable_max * 100))
    grade, color = grade_label(total)
    actions = derive_actions(cats, modules, large_files, repo, ctx_layer)
    insights = generate_insights(cats, total)

    return Report(
        meta={
            "repo": repo.name,
            "path": str(repo.resolve()),
            "scored_at": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
            "git_branch": git_branch(repo),
            "rubric_version": "v2-100pt-personal",
            "modules_total": len(modules),
            "context_files_total": len(context_files),
            "guide_doc_count": ctx_layer["guide_doc_count"],
            "adr_count": ctx_layer["adr_count"],
            "large_files_300plus": len(large_files),
            "raw_total": raw_total,
            "applicable_max": applicable_max,
            "na_categories": [k for k, c in cats.items() if c.na] + (["E2"] if cats["E"].applicable_max == 11 else []),
        },
        total=total,
        grade=grade,
        grade_color=color,
        categories=cats,
        insights=insights,
        actions=actions,
        extras={
            "modules": [asdict(m) | {"path": str(m.path), "context_file": str(m.context_file) if m.context_file else None} for m in modules],
            "large_files": [
                {"path": str(p.relative_to(repo).as_posix()), "lines": ln}
                for p, ln in large_files[:30]
            ],
        },
    )


def serialize(report: Report) -> dict[str, Any]:
    cats = {k: asdict(c) for k, c in report.categories.items()}
    return {
        "meta": report.meta,
        "total": report.total,
        "grade": report.grade,
        "grade_color": report.grade_color,
        "categories": cats,
        "insights": report.insights,
        "actions": [asdict(a) for a in report.actions],
        "extras": report.extras,
    }


def render_markdown(report: Report) -> str:
    lines = []
    lines.append(f"# AI-Readiness Audit · {report.meta['repo']}")
    lines.append("")
    lines.append(f"**Score:** {report.total}/100 · **Grade:** {report.grade}  "
                 f"(raw {report.meta['raw_total']}/{report.meta['applicable_max']}, "
                 f"N/A 제외: {', '.join(report.meta['na_categories']) or '없음'})")
    lines.append(f"**Branch:** `{report.meta['git_branch']}` · **Scored:** {report.meta['scored_at']}")
    lines.append(f"**Modules:** {report.meta['modules_total']} · **Context files:** {report.meta['context_files_total']} · "
                 f"**Guide docs:** {report.meta['guide_doc_count']} · **ADRs:** {report.meta['adr_count']} · "
                 f"**Large files (>300 ln):** {report.meta['large_files_300plus']}")
    lines.append("")

    lines.append("## Category Scores")
    lines.append("")
    lines.append("| Cat | Name | Score |")
    lines.append("|-----|------|-------|")
    for k, c in report.categories.items():
        val = "**N/A**" if c.na else f"**{c.score}/{c.denom()}**"
        lines.append(f"| {k} | {c.name} | {val} |")
    lines.append("")

    lines.append("## Insights")
    for ins in report.insights:
        lines.append(f"- {ins}")
    lines.append("")

    lines.append("## Findings (per category)")
    for k, c in report.categories.items():
        if not c.findings:
            continue
        lines.append(f"### {k}. {c.name}  ({c.score}/{c.denom()})")
        for f in c.findings:
            lines.append(f"- {f}")
    lines.append("")

    lines.append("## Top Actions (ranked by ROI)")
    lines.append("")
    lines.append("| # | Effort | Action | Impact |")
    lines.append("|---|--------|--------|--------|")
    for i, a in enumerate(report.actions[:8], 1):
        lines.append(f"| {i} | {a.effort} ({a.effort_hours:.1f} hr) | [{a.category}] {a.title} | {a.impact} |")
    lines.append("")

    if report.extras["large_files"]:
        lines.append("## Large Files (>300 lines)")
        for lf in report.extras["large_files"][:10]:
            lines.append(f"- {lf['path']} — **{lf['lines']}** lines")
        lines.append("")

    return "\n".join(lines)


def render_html(report: Report) -> str:
    """Data-driven dashboard in the bespoke card+panel layout — header, score-hero +
    7-category chart, strengths + ROI panels. Generated by score.py via Bash so it does
    NOT go through the editor Write hook. The one element it cannot produce is the
    2-store structural SVG map (per-repo hand-craft) — fill assets/template.html for that."""
    m = report.meta
    esc = html.escape
    cats = report.categories
    grade_bg = {"green": "var(--green-soft)", "amber": "var(--amber-soft)", "red": "var(--red-soft)"}.get(report.grade_color, "var(--amber-soft)")
    grade_fg = {"green": "var(--green)", "amber": "var(--amber)", "red": "var(--red)"}.get(report.grade_color, "var(--amber)")

    def sub_for(k: str, c: CategoryScore) -> str:
        e = c.evidence
        if k == "A":
            return f"가이드 {m['guide_doc_count']}문서 · per-folder {e.get('covered_modules', 0)}/{e.get('core_modules', 0)}"
        if k == "B":
            return " · ".join(f"{kk.split('_', 1)[-1]} {vv}" for kk, vv in c.sub_scores.items())
        if k == "C":
            return f"ADR {e.get('adr_count', 0)} · 가이드 {e.get('guide_doc_count', 0)} · 비자명마커 {e.get('nonobvious_markers', 0)}"
        if k == "D":
            return (f"arch {'O' if e.get('architecture_doc') else 'X'} · "
                    f"mermaid {'O' if e.get('mermaid_diagrams') else 'X'} · "
                    f"workspace {'O' if e.get('workspace_or_solution') else 'X'}")
        if k == "E":
            return (f"ref {e.get('ref_total', 0) - e.get('ref_broken', 0)}/{e.get('ref_total', 0)} 유효 · "
                    f"E2 N/A · build {'O' if (e.get('dotnet_build') or e.get('flutter_build')) else 'X'}")
        if k == "F":
            return (f"drift {e.get('drift_ratio', 0)} · hooks {'O' if e.get('hook_validates_paths') else 'X'} · "
                    f"CI {'O' if e.get('ctx_validation_workflow') else 'X'}")
        if k == "G":
            return "N/A — 외부 PM vault handoff ledger"
        return c.findings[0] if c.findings else ""

    rows = []
    for k, c in cats.items():
        sub = esc(sub_for(k, c))
        if c.na:
            rows.append(f'<div class="rule-row"><div class="idx">{k}</div>'
                        f'<div><div class="title">{esc(c.name)}</div><div class="rsub">{sub}</div></div>'
                        f'<div class="bar"></div><div class="prog na">N/A</div></div>')
            continue
        denom = c.denom()
        ratio = c.score / denom if denom else 0.0
        barcls = "bar-good" if ratio >= 0.75 else ("bar-warn" if ratio >= 0.5 else "bar-bad")
        rows.append(f'<div class="rule-row"><div class="idx">{k}</div>'
                    f'<div><div class="title">{esc(c.name)}</div><div class="rsub">{sub}</div></div>'
                    f'<div class="bar {barcls}"><span style="width:{round(ratio*100)}%"></span></div>'
                    f'<div class="prog">{c.score}<small>/{denom}</small></div></div>')
    rows_html = "\n".join(rows)

    wins = []
    for k, c in cats.items():
        if c.na:
            continue
        d = c.denom()
        if d and c.score / d >= 0.75:
            wins.append(f'<li><div class="whead"><span class="tag tag-good">{k}</span>{esc(c.name)} '
                        f'<b>{c.score}/{d}</b></div><div class="wnote">{esc(sub_for(k, c))}</div></li>')
    wins_html = "\n".join(wins) or '<li><div class="wnote">75%+ 카테고리 없음</div></li>'

    roi = []
    for a in report.actions[:7]:
        roi.append(f'<li><div class="whead"><span class="tag tag-roi">{a.category} · {a.effort} {a.effort_hours:.1f}h</span>'
                   f'{esc(a.title)}</div><div class="wnote">{esc(a.impact)}</div></li>')
    roi_html = "\n".join(roi) or '<li><div class="whead"><span class="tag tag-good">✓</span>권장 액션 없음 — 양호</div></li>'

    na = ", ".join(m["na_categories"]) or "없음"
    ref_broken = cats["E"].evidence.get("ref_broken", 0)
    ref_color = "var(--green)" if ref_broken == 0 else "var(--red)"

    return f"""<!doctype html>
<html lang="ko"><head><meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>{esc(m['repo'])} · AI-Readiness</title>
<link rel="preconnect" href="https://fonts.googleapis.com"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet"/>
<style>
:root{{--bg:#fafafa;--surface:#fff;--border:#e5e7eb;--text:#0f172a;--text-2:#475569;--text-3:#94a3b8;
--accent:#2563eb;--accent-soft:#eff6ff;--green:#16a34a;--green-soft:#dcfce7;--amber:#d97706;--amber-soft:#fef3c7;--red:#dc2626;--red-soft:#fee2e2;--grid:#f1f5f9;}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--text);font-family:"Inter",system-ui,sans-serif;-webkit-font-smoothing:antialiased}}
.page{{max-width:1180px;margin:0 auto;padding:44px 36px 60px}}
.header{{display:flex;justify-content:space-between;align-items:flex-end;padding-bottom:22px;border-bottom:1px solid var(--border);margin-bottom:28px}}
.eyebrow{{font-family:"JetBrains Mono",monospace;font-size:11px;color:var(--text-3);letter-spacing:.12em;text-transform:uppercase;margin-bottom:8px}}
h1{{font-size:28px;font-weight:700;margin:0;letter-spacing:-.02em}}
.hsub{{font-size:13px;color:var(--text-2);margin-top:4px}}
.header-meta{{text-align:right;font-family:"JetBrains Mono",monospace;font-size:11px;color:var(--text-3);line-height:1.7}}
.header-meta strong{{color:var(--text);font-weight:500}}
.score-strip{{display:grid;grid-template-columns:320px 1fr;gap:22px;margin-bottom:28px}}
.score-hero{{background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:26px 26px 22px}}
.score-hero .label{{font-size:12px;color:var(--text-3);text-transform:uppercase;letter-spacing:.08em}}
.value{{display:flex;align-items:baseline;gap:6px;margin-top:8px}}
.num{{font-size:60px;font-weight:700;letter-spacing:-.04em;line-height:1}}.denom{{font-size:19px;color:var(--text-3)}}
.grade-row{{margin-top:13px}}
.grade-badge{{display:inline-flex;align-items:center;gap:6px;padding:4px 10px;border-radius:999px;font-family:"JetBrains Mono",monospace;font-size:12px;font-weight:600;background:{grade_bg};color:{grade_fg}}}
.grade-dot{{width:6px;height:6px;border-radius:999px;background:{grade_fg}}}
.score-hero hr{{border:0;border-top:1px solid var(--border);margin:18px 0 14px}}
.mini-stats{{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}}
.mini-stat .k{{font-family:"JetBrains Mono",monospace;font-size:10.5px;color:var(--text-3);margin-bottom:2px}}
.mini-stat .v{{font-size:15px;font-weight:600}}
.rules{{background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:18px 22px 20px}}
.rules-head{{display:flex;justify-content:space-between;align-items:center;margin-bottom:14px}}
.rules-head h2{{font-size:14px;font-weight:600;margin:0}}
.legend-inline{{display:flex;gap:12px;font-family:"JetBrains Mono",monospace;font-size:11px;color:var(--text-2)}}
.legend-inline span{{display:inline-flex;align-items:center;gap:5px}}.legend-inline i{{width:8px;height:8px;border-radius:2px}}
.rule-row{{display:grid;grid-template-columns:26px 1fr 200px 70px;gap:12px;align-items:center;padding:8px 0;font-size:13px}}
.rule-row+.rule-row{{border-top:1px dashed var(--border)}}
.idx{{font-family:"JetBrains Mono",monospace;font-size:11px;color:var(--text-3);font-weight:600}}
.title{{font-weight:500}}.rsub{{font-size:11px;color:var(--text-3);margin-top:1px;font-family:"JetBrains Mono",monospace}}
.bar{{height:8px;border-radius:3px;background:var(--grid);overflow:hidden}}.bar span{{display:block;height:100%;border-radius:3px}}
.bar-good span{{background:var(--green)}}.bar-warn span{{background:var(--amber)}}.bar-bad span{{background:var(--red)}}
.prog{{font-family:"JetBrains Mono",monospace;font-size:12px;font-weight:600;text-align:right}}.prog small{{color:var(--text-3);font-weight:500}}.prog.na{{color:var(--text-3);font-weight:500}}
.findings{{display:grid;grid-template-columns:1fr 1fr;gap:22px}}
.panel{{background:var(--surface);border:1px solid var(--border);border-radius:8px;overflow:hidden}}
.panel-head{{padding:14px 18px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:10px}}
.panel-head h3{{font-size:13px;font-weight:600;margin:0;text-transform:uppercase;letter-spacing:.06em}}
.panel-head .count{{font-family:"JetBrains Mono",monospace;font-size:11px;color:var(--text-3);margin-left:auto}}
.panel-strength .panel-head{{background:var(--green-soft)}}.panel-strength .panel-head h3{{color:var(--green)}}
.panel-risk .panel-head{{background:var(--amber-soft)}}.panel-risk .panel-head h3{{color:var(--amber)}}
.panel-list{{list-style:none;margin:0;padding:0}}
.panel-list li{{padding:13px 18px;border-top:1px solid var(--border);font-size:13px;line-height:1.5}}.panel-list li:first-child{{border-top:0}}
.whead{{display:flex;align-items:center;gap:8px;font-weight:500;flex-wrap:wrap}}
.tag{{font-family:"JetBrains Mono",monospace;font-size:10.5px;padding:2px 7px;border-radius:3px;font-weight:500}}
.tag-good{{background:var(--green-soft);color:var(--green)}}.tag-roi{{background:var(--accent-soft);color:var(--accent)}}
.wnote{{margin-top:4px;color:var(--text-2);font-size:12.5px}}
footer{{font-family:"JetBrains Mono",monospace;font-size:11px;color:var(--text-3);text-align:center;margin-top:40px}}
@media (max-width:900px){{.score-strip,.findings{{grid-template-columns:1fr}}}}
</style></head><body><div class="page">
<header class="header">
<div><div class="eyebrow">시스템 감사 · AI 준비도 · v2 personal · score.py</div>
<h1>{esc(m['repo'])}</h1><div class="hsub">자동 채점 (벤더 제외 · 보정 없음)</div></div>
<div class="header-meta"><div>점수 측정 <strong>{m['scored_at']}</strong></div>
<div>브랜치 <strong>{esc(str(m['git_branch']))}</strong></div>
<div>모듈 {m['modules_total']} · 가이드 {m['guide_doc_count']} · ADR {m['adr_count']}</div></div>
</header>
<section class="score-strip">
<div class="score-hero">
<div class="label">AI 준비도 지수 · /100</div>
<div class="value"><span class="num">{report.total}</span><span class="denom">/ 100</span></div>
<div class="grade-row"><span class="grade-badge"><span class="grade-dot"></span>{esc(report.grade)}</span></div>
<hr/>
<div class="mini-stats">
<div class="mini-stat"><div class="k">raw / 적용</div><div class="v">{m['raw_total']}/{m['applicable_max']}</div></div>
<div class="mini-stat"><div class="k">잘못된 경로</div><div class="v" style="color:{ref_color}">{ref_broken}</div></div>
<div class="mini-stat"><div class="k">N/A 제외</div><div class="v">{esc(na)}</div></div>
</div></div>
<div class="rules">
<div class="rules-head"><h2>7개 카테고리</h2>
<div class="legend-inline"><span><i style="background:var(--green)"></i>75%+</span><span><i style="background:var(--amber)"></i>50–74%</span><span><i style="background:var(--red)"></i>&lt;50%</span></div></div>
{rows_html}
</div>
</section>
<div class="findings">
<section class="panel panel-strength"><div class="panel-head"><h3>강점</h3><span class="count">75%+</span></div>
<ul class="panel-list">{wins_html}</ul></section>
<section class="panel panel-risk"><div class="panel-head"><h3>ROI 액션</h3><span class="count">우선순위순</span></div>
<ul class="panel-list">{roi_html}</ul></section>
</div>
<footer>{esc(m['repo'])} · AI-Readiness v2 personal · {m['scored_at']}</footer>
</div></body></html>"""


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("repo", nargs="?", default=".", help="repo path (default: cwd)")
    p.add_argument("--json", dest="json_out", help="write JSON report to this path")
    p.add_argument("--html", dest="html_out", help="write a compact HTML dashboard to this path")
    p.add_argument("--markdown", action="store_true", help="emit markdown to stdout (default)")
    p.add_argument("--quiet", action="store_true", help="suppress stdout output")
    args = p.parse_args()

    repo = Path(args.repo).resolve()
    if not repo.exists():
        print(f"error: repo path not found: {repo}", file=sys.stderr)
        return 2

    report = build_report(repo)
    payload = serialize(report)

    if args.json_out:
        Path(args.json_out).write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
    if args.html_out:
        Path(args.html_out).write_text(render_html(report), encoding="utf-8")

    if not args.quiet:
        print(render_markdown(report))

    return 0


if __name__ == "__main__":
    sys.exit(main())
