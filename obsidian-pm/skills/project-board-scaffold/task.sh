#!/usr/bin/env bash
# PM↔코드 task 상태 전환기.
# 소스 오브 트루스: 이 vault의 wiki/projects/<project>/tasks/*.md (프론트매터 status).
# 사람·PM 세션·코드 세션(훅) 공용. 절대경로로 어디서든 호출 가능.
set -euo pipefail
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# vault 루트 결정: TASK_VAULT 우선(플러그인으로 설치된 경우 필수),
# 없으면 vault 안(.claude/scripts/)에 놓인 것으로 보고 두 단계 위를 쓴다.
export TASK_VAULT="${TASK_VAULT:-$(cd "$SELF/../.." && pwd)}"
if [ ! -d "$TASK_VAULT/wiki/projects" ]; then
  echo "task: vault를 찾을 수 없다 — TASK_VAULT=<vault 루트> 로 지정하라." >&2
  echo "      현재값: $TASK_VAULT (여기에 wiki/projects/ 가 없다)" >&2
  exit 1
fi
exec python3 - "$@" <<'PYEOF'
import os, sys, re, glob, datetime, json, subprocess

VAULT = os.environ["TASK_VAULT"]
PROJECTS = os.path.join(VAULT, "wiki", "projects")
TODAY = datetime.date.today().isoformat()
STATUSES = {"todo", "wip", "done"}
SECTIONS = {"pm", "code"}
LABEL = {"todo": "할 일", "wip": "진행 중", "done": "진행 완료"}
EMOJI = {"todo": "📋", "wip": "🔧", "done": "✅"}

def _webhook_url():
    url = os.environ.get("DISCORD_WEBHOOK_URL", "").strip()
    if url:
        return url
    pd = os.environ.get("CLAUDE_PROJECT_DIR", "")  # 세션/훅 호출 시 설정됨(수동 터미널 호출은 env 변수 필요)
    if pd:
        try:
            with open(os.path.join(pd, ".env"), encoding="utf-8") as fh:
                for line in fh:
                    s = line.strip()
                    if s.startswith("DISCORD_WEBHOOK_URL="):
                        return s.split("=", 1)[1].strip().strip('"').strip("'")
        except OSError:
            pass
    return ""

def notify_discord(text):
    """Discord webhook 알림 (fail-soft). URL: env DISCORD_WEBHOOK_URL → $CLAUDE_PROJECT_DIR/.env → 없으면 no-op.
    실패·타임아웃·URL 부재 어떤 경우에도 예외를 던지지 않는다(상태 전환은 이미 완료됨 — 알림은 부가기능)."""
    url = _webhook_url()
    if not url:
        return
    try:
        payload = json.dumps({"content": text})
        subprocess.run(
            ["curl", "-s", "-m", "5", "-o", "/dev/null",
             "-H", "Content-Type: application/json", "--data-raw", payload, url],
            check=False, timeout=8,
        )
    except Exception:
        pass

def die(msg):
    sys.stderr.write("task: " + msg + "\n"); sys.exit(1)

def usage():
    sys.stderr.write(
        "사용법:\n"
        "  task.sh new   <ID> \"<제목>\" --project <P> [--section pm|code]\n"
        "  task.sh todo  <ID> [--project <P>] [--force]\n"
        "  task.sh wip   <ID> [--project <P>] [--section pm|code] [--force]\n"
        "  task.sh done  <ID> [--project <P>]\n"
        "  task.sh ls    [--project <P>] [--status todo|wip|done]\n"
        "  task.sh board <P>            # tasks.base(보드) 생성. new 가 자동 호출\n"
        "예: task.sh wip T03 --project toss-자동매매 --section code\n"
        "규칙: 상태·섹션 변화 없으면 no-op(로그 없음). done→wip|todo 강등은 --force 필요(훅 오전환 방지).\n"
        "      ID는 프로젝트 안에서만 유일 — 여러 프로젝트에 같은 ID가 있으면 --project 필수.\n"
    ); sys.exit(1)

def parse_flags(argv):
    pos, flags = [], {}
    i = 0
    while i < len(argv):
        a = argv[i]
        if a.startswith("--"):
            key = a[2:]
            nxt = argv[i+1] if i+1 < len(argv) else ""
            if nxt == "" or nxt.startswith("--"):  # 값 없는 불리언 플래그(--force)
                flags[key] = ""; i += 1
            else:
                flags[key] = nxt; i += 2
        else:
            pos.append(a); i += 1
    return pos, flags

def find_file(tid, project=None):
    """ID는 프로젝트 안에서만 유일하다(T01이 여러 프로젝트에 있다). 모호하면 --project 를 요구한다."""
    hits = []
    for f in sorted(glob.glob(os.path.join(PROJECTS, "*", "tasks", "*.md"))):
        txt = open(f, encoding="utf-8").read()
        if re.search(r'(?m)^id:\s*' + re.escape(tid) + r'\s*$', txt):
            if project and field(txt, "project") != project:
                continue
            hits.append((f, txt))
    if not hits:
        where = " (project=" + project + ")" if project else ""
        die("task ID를 찾을 수 없음: " + tid + where + "  (먼저 'task.sh new'로 생성)")
    if len(hits) > 1:
        die(tid + " 가 여러 프로젝트에 있음: " + ", ".join(field(t, "project") for _, t in hits)
            + "  → --project <P> 로 지정")
    return hits[0]

def field(txt, name):
    m = re.search(r'(?m)^' + name + r':\s*(.*)$', txt)
    return (m.group(1).strip() if m else "")

def set_field(txt, name, value):
    return re.sub(r'(?m)^' + name + r':.*$', name + ": " + value, txt, count=1)

def append_log(txt, line):
    if re.search(r'(?m)^## 진행 로그\s*$', txt):
        return re.sub(r'(?m)^(## 진행 로그\s*)$', r'\1\n' + line, txt, count=1)
    return txt.rstrip() + "\n\n## 진행 로그\n" + line + "\n"

def slug(title):
    s = re.sub(r'[\s/\\]+', '-', title.strip())
    s = re.sub(r'[^\w가-힣\-]', '', s)
    return s[:40].strip('-') or "task"

def cmd_transition(status, tid, section, force=False, project=None):
    f, txt = find_file(tid, project)
    old = field(txt, "status") or "?"
    old_section = field(txt, "section")
    if old == "done" and status != "done" and not force:
        print("↷ " + tid + ": done→" + status + " 강등 방지(훅 오전환 보호). 재오픈은 --force")
        return
    if old == status and (not section or section == old_section):
        print("= " + tid + ": 변경 없음 (이미 " + status + ")")
        return
    txt = set_field(txt, "status", status)
    if section:
        if section not in SECTIONS: die("section은 pm|code")
        txt = set_field(txt, "section", section)
    txt = set_field(txt, "updated", TODAY)
    note = (" (section=" + section + ")") if section else ""
    txt = append_log(txt, "- [" + TODAY + "] " + old + "→" + status + note)
    open(f, "w", encoding="utf-8").write(txt)
    print("✓ " + tid + ": " + old + " → " + status + " [" + LABEL[status] + "]" + note)
    print("  " + os.path.relpath(f, VAULT))
    title = field(txt, "title")
    project = field(txt, "project")
    notify_discord(EMOJI.get(status, "•") + " [" + tid + "] " + old + "→" + status + " · " + title + " · " + project)

BOARD = """filters:
  and:
    - file.hasTag("task")
    - project == "{project}"
formulas:
  board: if(note.status == "todo", "① 할 일", if(note.status == "wip", "② 진행 중", "③ 진행 완료"))
properties:
  note.status:
    displayName: 상태
  note.section:
    displayName: 섹션
  note.title:
    displayName: 제목
  note.branch:
    displayName: 브랜치
  note.updated:
    displayName: 갱신
  formula.board:
    displayName: 진행
views:
  - type: cards
    name: 보드
    groupBy:
      property: formula.board
      direction: ASC
    order:
      - title
      - section
      - branch
      - updated
  - type: table
    name: 전체
    order:
      - status
      - section
      - title
      - updated
"""

def ensure_board(project):
    """프로젝트에 tasks.base(Obsidian Bases 보드)가 없으면 만든다. 있으면 no-op."""
    path = os.path.join(PROJECTS, project, "tasks.base")
    if os.path.exists(path):
        return False
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w", encoding="utf-8").write(BOARD.replace("{project}", project))
    print("✓ 보드 생성: " + os.path.relpath(path, VAULT))
    return True

def cmd_board(project):
    if not project: die("board 에는 프로젝트 이름 필요 (예: task.sh board 출발-비서)")
    if not ensure_board(project):
        print("= 보드 이미 있음: " + os.path.relpath(os.path.join(PROJECTS, project, "tasks.base"), VAULT))

def cmd_new(tid, title, project, section):
    if not project: die("new 에는 --project 필요")
    section = section or "pm"
    if section not in SECTIONS: die("section은 pm|code")
    ensure_board(project)
    tdir = os.path.join(PROJECTS, project, "tasks")
    os.makedirs(tdir, exist_ok=True)
    path = os.path.join(tdir, tid + "-" + slug(title) + ".md")
    if os.path.exists(path): die("이미 존재: " + os.path.relpath(path, VAULT))
    body = (
        "---\n"
        "id: " + tid + "\n"
        "project: " + project + "\n"
        "status: todo\n"
        "section: " + section + "\n"
        "title: " + title + "\n"
        "created: " + TODAY + "\n"
        "updated: " + TODAY + "\n"
        "repo:\n"
        "branch:\n"
        "pr:\n"
        "spec:\n"
        "tags: [task]\n"
        "---\n"
        "# " + tid + " " + title + "\n\n"
        "> 한 줄 요약.\n\n"
        "## 목표 / 완료기준(AC)\n- [ ] \n\n"
        "## PM 참조\n- \n\n"
        "## 코드 참조\n- repo: \n- branch: \n- 핵심 파일: \n- PR: \n\n"
        "## 진행 로그\n- [" + TODAY + "] 생성 → todo (section=" + section + ")\n"
    )
    open(path, "w", encoding="utf-8").write(body)
    print("✓ 생성: " + os.path.relpath(path, VAULT))

def cmd_ls(project, status):
    rows = []
    pat = os.path.join(PROJECTS, project or "*", "tasks", "*.md")
    for f in sorted(glob.glob(pat)):
        txt = open(f, encoding="utf-8").read()
        st = field(txt, "status")
        if status and st != status: continue
        rows.append((field(txt, "id"), st, field(txt, "section"), field(txt, "title")))
    order = {"todo": 0, "wip": 1, "done": 2}
    rows.sort(key=lambda r: (order.get(r[1], 9), r[0]))
    for tid, st, sec, title in rows:
        print("%-5s %-5s %-4s %s" % (tid, st, sec, title))
    if not rows: print("(task 없음)")

def main():
    argv = sys.argv[1:]
    if not argv: usage()
    cmd = argv[0]
    pos, flags = parse_flags(argv[1:])
    if cmd in STATUSES:
        if not pos: usage()
        cmd_transition(cmd, pos[0], flags.get("section"), "force" in flags, flags.get("project"))
    elif cmd == "new":
        if len(pos) < 2: usage()
        cmd_new(pos[0], pos[1], flags.get("project"), flags.get("section"))
    elif cmd == "ls":
        cmd_ls(flags.get("project"), flags.get("status"))
    elif cmd == "board":
        cmd_board(pos[0] if pos else flags.get("project"))
    else:
        usage()

main()
PYEOF
