#!/usr/bin/env bash
# 프로젝트 승격 — wiki/projects/<slug>/ 에 index.md 와 prd.md 만 만든다.
# adr/ · architecture.md · notes/ 는 실제로 쓸 내용이 생겼을 때 만든다(빈 문서 금지).
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
사용법:
  TASK_VAULT=<vault 루트> project-new.sh <slug> --title "<제목>" --summary "<한 줄 정의>" \
      [--status "<현재 상태>"] [--repo <코드 repo 이름>]

  <slug>      wiki/projects/ 아래 폴더명 (한글 가능, 공백 대신 -; /·\·.·.. 사용 불가)
  --title     문서 제목에 쓸 이름
  --summary   이 제품이 무엇인지 한 줄 (index 인용문에 들어간다)
  --status    예: "발굴 통과 — PRD 작성 전" (생략 시 이 문구)
  --repo      코드 repo 이름 (vault 밖). 없으면 생략
USAGE
  exit 1
}

[ $# -ge 1 ] || usage
SLUG="$1"; shift
case "$SLUG" in --*) usage;; esac
case "$SLUG" in
  ""|.|..|*/*|*\\*)
    echo "project-new: slug에 / 나 .. 는 쓸 수 없다 — wiki/projects/ 바로 아래 폴더명 하나여야 한다." >&2
    exit 1
    ;;
esac

TITLE=""; SUMMARY=""; STATUS="발굴 통과 — PRD 작성 전"; REPO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --title)   TITLE="${2:-}"; shift 2;;
    --summary) SUMMARY="${2:-}"; shift 2;;
    --status)  STATUS="${2:-}"; shift 2;;
    --repo)    REPO="${2:-}"; shift 2;;
    *) echo "알 수 없는 인자: $1" >&2; usage;;
  esac
done

[ -n "${TASK_VAULT:-}" ] || { echo "project-new: TASK_VAULT=<vault 루트> 를 지정하라." >&2; exit 1; }
[ -d "$TASK_VAULT/wiki/projects" ] || {
  echo "project-new: vault가 아니다 — $TASK_VAULT 에 wiki/projects/ 가 없다." >&2
  echo "             새 vault라면 vault-bootstrap 을 먼저 돌린다." >&2; exit 1; }
[ -n "$TITLE" ] || { echo "project-new: --title 은 필수다." >&2; exit 1; }
[ -n "$SUMMARY" ] || { echo "project-new: --summary 는 필수다." >&2; exit 1; }

DIR="$TASK_VAULT/wiki/projects/$SLUG"
[ -e "$DIR" ] && { echo "project-new: 이미 있다 — wiki/projects/$SLUG" >&2; exit 1; }
mkdir -p "$DIR"

REPO_LINE=""
[ -n "$REPO" ] && REPO_LINE="> 💻 **dev repo**: \`$REPO\` (vault 밖)
"

cat > "$DIR/index.md" <<EOF
# $TITLE — 프로젝트 홈

> $SUMMARY
$REPO_LINE
- 상태: **$STATUS**
- PRD: [[projects/$SLUG/prd]]

## 발굴 계보

- 승격 근거(시장·경쟁·가설·결정)를 여기에 링크한다. **복사하지 말고 링크한다.**

## 연결 문서

-
EOF

cat > "$DIR/prd.md" <<EOF
# $TITLE — PRD

> $SUMMARY

## 1. 목표

<!-- 무엇을 달성하면 성공인가. 가능하면 검증 가능한 기준으로 적는다. -->

## 2. 대상

<!-- 누구를 위한 것인가. 대상이 아닌 사람도 적으면 스코프가 단단해진다. -->

## 3. 스코프 · 기능

<!-- 포함/제외. 표로 쓰고 F1·F2… 번호를 붙이면 task·ADR에서 참조할 수 있다. -->

## 4. 열린 항목

<!-- 아직 못 정한 것. 정해지면 여기서 지우고 본문으로 옮긴다. -->

## 5. 연결 문서

- [[projects/$SLUG/index]] — 프로젝트 홈

<!--
이 다섯은 공통분모다. 프로젝트 성격에 맞게 섹션을 늘린다
(배경·가치 제안·기술·릴리스·데이터 모델·비기능 요구 등).
-->
EOF

echo "✓ 승격: wiki/projects/$SLUG/"
echo "  + index.md"
echo "  + prd.md (5섹션 골격)"
echo
echo "다음:"
echo "  1) vault index·log 에 이 프로젝트를 연결한다"
echo "  2) PRD 본문은 결정을 확정한 뒤 쓴다(grilling 등)"
echo "  3) PRD가 서면 project-board-scaffold 로 보드를 올린다"
