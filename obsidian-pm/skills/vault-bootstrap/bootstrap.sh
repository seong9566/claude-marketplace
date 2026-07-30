#!/usr/bin/env bash
# Obsidian PM vault 부트스트랩 — 폴더 트리 + 운영 규약 문서를 찍어낸다.
# 기존 파일은 절대 덮어쓰지 않는다(있으면 건너뛰고 보고). 여러 번 돌려도 안전하다.
set -euo pipefail
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL="$SELF/templates"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "사용법: bootstrap.sh <vault 루트 경로>" >&2
  echo "  기존 파일은 덮어쓰지 않는다. 이미 있는 vault에 부족한 것만 채울 때도 쓸 수 있다." >&2
  exit 1
fi
[ -d "$TPL" ] || { echo "bootstrap: templates/ 를 찾을 수 없다: $TPL" >&2; exit 1; }

mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

DIRS=(
  raw raw/inbox raw/articles raw/dev raw/docs raw/errors raw/snippets
  raw/projects raw/assets raw/market-research
  wiki wiki/sources wiki/topics wiki/entities wiki/dev wiki/product
  wiki/projects wiki/harness wiki/errors wiki/questions wiki/meta
  Output Output/dev-notes Output/checklists Output/prompts
  Output/project-plans Output/reports Output/reports/market
)

made_d=0; made_f=0; skipped=0
for d in "${DIRS[@]}"; do
  if [ ! -d "$TARGET/$d" ]; then mkdir -p "$TARGET/$d"; made_d=$((made_d+1)); fi
done

# templates/ 트리를 그대로 대상에 반영(없는 것만)
while IFS= read -r src; do
  rel="${src#"$TPL"/}"
  dst="$TARGET/$rel"
  if [ -e "$dst" ]; then
    echo "  = 건너뜀(이미 있음): $rel"; skipped=$((skipped+1))
  else
    mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"
    echo "  + $rel"; made_f=$((made_f+1))
  fi
done < <(find "$TPL" -type f | sort)

echo
echo "vault: $TARGET"
echo "폴더 ${made_d}개 생성 · 파일 ${made_f}개 생성 · ${skipped}개 건너뜀"
if [ "$made_f" -gt 0 ]; then
  echo
  echo "다음: wiki/index.md 의 프로젝트 절은 비어 있다. 첫 프로젝트는 project-scaffold 로 승격한다."
fi
