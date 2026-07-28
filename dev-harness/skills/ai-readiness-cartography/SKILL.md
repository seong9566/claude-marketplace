---
name: ai-readiness-cartography
description: Audits any repository against the v2 AI-Ready rubric (100 pts · 7 categories — Navigation, Context Quality, Tribal Knowledge, Dependency Mapping, Verification Gates, Freshness, Agent Outcomes) and produces a professional single-file HTML dashboard plus an ROI-ranked action list. The skill bundles a Python scorer (`scripts/score.py`) that auto-detects coverage, hallucinated paths, drift, and god files. Trigger whenever the user asks for an "AI-readiness 지도", "AI-ready 시각화", "repo cartography", "codebase audit 시각화", "ai-readiness-cartography", or anything that sounds like "score how agent-friendly this codebase is and visualize it", "check how AI-ready our repo is", "map the repo against the rubric", or "audit our codebase for agent readiness". Also trigger when the user points at a repo and asks whether it is ready for coding agents / LLM workflows — even without the exact keyword. The output is always a clean technical-dashboard HTML (Inter + JetBrains Mono, light surface, blue/green/amber/red accents), never a fantasy map.
---

# AI-Readiness Cartography

이 스킬은 임의 레포지토리를 **AI-Ready 코드베이스 v2 루브릭** (100점 · 7 카테고리 A-G) 으로 감사합니다. 산출물은 한 장의 전문 기술 대시보드 HTML + 자동 채점 JSON + ROI 순으로 정렬된 actionable 액션 리스트입니다. 이름은 "cartography" 지만 톤은 의사결정용 계기판 — 판타지 양피지 / 컴퍼스 로즈 같은 장식은 절대 쓰지 않습니다.

## 개인 포크 (이 버전의 변경점)

모바일 앱 + 백엔드 + 외부 PM vault로 이뤄진 실제 멀티 repo 환경(1–2인·에이전트 헤비)에 맞춘 user-scope 포크. 원본 대비:

- **벤더/빌드 산출물 자동 제외** — `IGNORE_DIRS`에 `bin·obj·actions-runner·Pods·.dart_tool·vendor` 등 추가. **rsync 우회 불필요.** `.dart`를 코드 확장자에 추가(원본 누락 — Flutter가 통째로 안 잡히던 버그).
- **가이드 라이브러리·ADR 1급 인정** — per-folder CLAUDE.md가 없어도 `docs/flutter_kit`·`docs/architecture`(디렉터리)·`docs/adr`를 A(내비)·C(암묵지)·D(의존)에서 크레딧.
- **E2(CODEOWNERS/PR템플릿)·G(성과측정) = N/A** — 신호가 repo 밖(Codex PR 리뷰 프로세스·외부 PM handoff ledger)이라 채점 불가. 0점으로 깎지 않고 **분모에서 제외 후 /100 재정규화**(A-G 척도 유지).
- **E1 FP 강화** — 외부 절대경로(PM handoff)·문서 플레이스홀더(`test/xxx.dart`)·dotdir(`.claude`)·프로젝트-하위폴더 기준 경로(.NET `Commons/…`)를 hallucination으로 오판하지 않음.
- **B는 허브 문서 한정** — root CLAUDE.md/AGENTS.md 품질만 평가(가이드 stub README 희석 제거). 가이드 깊이는 C가 반영.
- **F drift 폴백** — per-folder context가 없으면 가이드/CLAUDE.md 신선도 vs 최신 코드로 측정.
- **D/F/E3 retarget(추가식)** — JS(turbo/nx/husky) 유지 + `.sln`·`pubspec.yaml`/melos·`.claude/hooks`·dotnet/flutter 빌드 감지.
- **산출물**: `score.py`가 markdown 기본 + `--html <path>`로 **데이터 기반 대시보드 직접 생성**(Bash 경유라 impeccable Write 훅 우회). 서사형 2-스토어 대시보드가 필요하면 `assets/template.html`을 손으로 채움(아래 step 2).

> 결과: rsync·수동 보정 없이 `python3 .../score.py <repo> --json out.json --html out.html` 한 줄로 정확한 점수. (검증: 모바일 80, 서버 81 — AI-Ready)

## When to use

- "AI-readiness 지도 / 시각화 / 점수 매겨줘"
- "이 레포가 얼마나 agent-friendly 한지 보여줘"
- "codebase audit", "repo cartography"
- "Claude Code 가 이 레포를 잘 다룰 수 있을까" 같은 우회 표현
- 트리거 키워드 없이도 LLM workflow 적합도 평가를 원하면 트리거

## What to produce

**3가지 결과물을 한 번에 만듭니다.**

1. **JSON 점수표** (raw 데이터, 다른 도구가 소비할 수 있음)
2. **단일 HTML 대시보드** (사람이 보고 의사결정)
3. **ROI 순 액션 리스트** (우선순위가 매겨진 다음 단계)

기본 저장 위치 우선순위:
- 레포에 `docs/` 가 있으면 → `docs/ai-readiness-map.html`, `docs/ai-readiness-score.json`
- `.claude/` 가 있으면 → `.claude/ai-readiness-{map.html,score.json}`
- 없으면 레포 루트
- 사용자가 명시적 경로를 지정하면 그 경로 우선

## Workflow

### 1. Python 스크립트로 자동 채점

```bash
# 한 줄로 충분 (벤더 자동 제외, rsync 불필요)
python3 ~/.claude/skills/ai-readiness-cartography/scripts/score.py <repo-path> \
  --json <output-path>/ai-readiness-score.json \
  --html <output-path>/ai-readiness-map.html   # --html 생략 시 markdown 요약만
```

스크립트는 stdlib only (deps 없음, Python 3.10+). 출력:
- `--json` 구조화된 점수표 (categories A-G, evidence, sub_scores, findings, ROI actions, large files, `meta.raw_total`/`applicable_max`/`na_categories`)
- `--html` 데이터 기반 대시보드 — 헤더 + score-hero · 7카테고리 차트 그리드 + 강점/ROI 2패널(서사형 2-스토어 SVG 맵만 제외, 그건 template.html 수동). Bash 생성이라 impeccable 훅 우회
- stdout markdown 요약 (항상)

채점이 자동으로 잡는 것:
- **A** navigation coverage — per-folder CLAUDE.md **또는** 가이드 라이브러리(`docs/flutter_kit`·`docs/architecture`)+root CLAUDE.md 허브
- **B** 허브 문서(root CLAUDE.md/AGENTS.md) 품질 — conciseness·quick commands·key files·non-obvious·cross-refs
- **C** Five-Question(코퍼스=모듈 context+CLAUDE+가이드) + Q5 store(MEMORY/`docs/adr`/decisions)
- **D** ARCHITECTURE.md / `docs/architecture` 디렉터리 / mermaid / `.sln`·`pubspec`·workspace
- **E1** **hallucinated path 검증**(절대·플레이스홀더·dotdir·프로젝트하위 FP 제외) — 가장 중요 · **E2=N/A**
- **E3** build/test infra(dotnet/flutter/JS) · **E4** evals
- **F** context drift(per-folder 없으면 가이드/CLAUDE 폴백) + CI + `.husky`/`.claude/hooks`
- **G = N/A** (성과 신호가 외부 PM vault라 분모 제외)

자동이 잡지 못하는 것 (Manual 보강):
- C의 tribal knowledge depth, B2-B4 깊이
- **외부 PM vault 차원**(handoff ledger·Codex 리뷰) — MCP 필요, score.py 밖. 필요 시 수동 보정.

LLM 이 JSON 을 받은 뒤 manual 항목을 보강하거나 그대로 차트에 반영합니다.

### 2. JSON 으로 HTML 대시보드 채우기

`assets/template.html` 을 복사 후 JSON 의 값을 끼워 넣습니다. **절대 처음부터 쓰지 말 것** — 디자인이 매번 바뀝니다.

바꿔야 할 블록:

**(a) 헤더**
- `<title>` · h1 의 `{{REPO_NAME}}`
- `header-meta` 의 날짜 (오늘) · git branch · `meta.modules_total` · `meta.context_files_total`

**(b) Score hero**
- `score-hero .num` ← `total`
- `grade-badge` 텍스트 ← grade (`AI-Native` / `AI-Ready` / `AI-Assisted` / `AI-Fragile` / `AI-Hostile`)
- `grade-badge` 배경/색 ← `grade_color` (green / amber / red)
- 등급 임계값:
  - 90-100 AI-Native (green)
  - 75-89  AI-Ready (green)
  - 60-74  AI-Assisted (amber)
  - 40-59  AI-Fragile (amber)
  - < 40   AI-Hostile (red)
- `.desc` 한 줄로 가장 약한 카테고리 2개 언급
- Mini stats 3개: modules · context_files · large_files_300plus (또는 ref_broken 강조)

**(c) 7 카테고리 막대차트**
10 rule 차트를 7 카테고리로 교체. 각 행:
- A 15 / B 20 / C 20 / D 15 / E 15 / F 10 / G 5
- 막대 width = `score / max * 100%`
- 색: score/max ≥ 0.75 → bar-good (green) · 0.5-0.74 → bar-warn (amber) · < 0.5 → bar-bad (red)
- `.sub` 에 evidence 1-2개를 짧게 (예: "coverage 75% · 1 module 누락")
- B 와 E 는 sub_scores 가 있으니 행 아래 작게 펼쳐서 5/4개 sub-item 의 점수도 보이게

**(d) Structural Map (SVG)**
대상 레포 구조에 맞게 컬럼 재설정. 카드 안에 `large_files` 의 상위 항목을 hot/warm 바로 표시. CLAUDE.md / AGENTS.md 보유 module 은 accent border + 점등. `ref_broken` 이 있는 module 은 빨간 점 표시.

**(e) Wins / Top ROI Actions 패널**
- 왼쪽 "Wins": evidence 에서 점수 높은 카테고리 위주, 핵심 강점 5개
- 오른쪽 "Top ROI Actions": JSON 의 `actions` 상위 5-7개. 각 행에:
  - Category 태그 (A-G)
  - Effort (S / M / L · 시간)
  - Impact (1줄)
  - Priority score (선택)

**(f) 푸터**
`{{REPO_NAME}} · AI-Readiness v2 · scored {{YYYY-MM-DD}}`

### 3. 브라우저에서 열기

```bash
open <output-path>/ai-readiness-map.html   # macOS
xdg-open <path>                            # Linux
```

사용자가 "열지 마라" 하면 경로만 알림.

### 4. 요약 보고

마지막으로 다음 4가지를 한 문단으로:
1. **총점 / 등급** (`32/100 · AI-Hostile`)
2. **최약점 카테고리 1-2개** + 한 줄 진단
3. **Top 3 ROI 액션** (Effort + Impact 짧게)
4. 생성된 **파일 경로**

## Style rules (non-negotiable)

이 스킬의 정체성. 어긋나면 스킬이 아닙니다.

- **폰트**: Inter (본문), JetBrains Mono (숫자/코드). 다른 폰트 금지.
- **색**: 템플릿의 CSS 변수 팔레트 고정.
- **배경**: `#fafafa` light. 다크 모드 만들지 않음.
- **장식 금지**: 컴퍼스 로즈, 양피지, 필기체, 이모지, 스탬프 — 전부 없이.
- **차트 라이브러리 금지**: 모든 시각화는 인라인 SVG + CSS.

## Common pitfalls

- **루브릭이 v2 임을 잊고 10-rule 로 채점** — 이전 버전 잔재. 현재는 **A-G 7 카테고리 / 100점**.
- **스크립트 출력을 무시하고 직접 점수 매기기** — 자동이 잡는 것은 자동이 더 정확. 스크립트 실행 후 그 위에 보강.
- **E1 hallucinated path 를 가볍게 다룸** — Meta 표준 "0 hallucinated paths". 1건이라도 있으면 즉시 fix 액션.
- **template 무시하고 처음부터 쓰기** — 매번 디자인 달라짐. 복사 → 수정.
- **판타지 회귀** — 이름이 cartography라고 지도 은유 강하게 쓰지 말 것.
- **ROI 정성적 형용사만** — "효율 ↑" 같은 모호한 임팩트 금지. "task당 ~3 min × ~5/일" 처럼 구체적 단위.

## ROI framing

각 액션의 effort/impact 표현 규약:

- **Effort**: S (<1h) / M (1-4h) / L (4h+)
- **Impact**: 정량 단위 우선 — "task당 N min × M task/주", "토큰 X% 절감", "회귀 Y건 catch"
- **Priority**: `impact_score / effort_hours` 로 자동 정렬됨

대표 액션 ROI 표는 `references/scoring-rubric.md` 끝 참조.

## Files

- `assets/template.html` — 복사 후 채울 원본 대시보드
- `references/scoring-rubric.md` — 7 카테고리 채점 기준 v2
- `scripts/score.py` — 자동 채점 + ROI 액션 생성 (Python 3.10+, stdlib only)
