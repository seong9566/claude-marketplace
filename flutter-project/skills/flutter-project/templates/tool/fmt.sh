#!/bin/sh
# PR 전 포맷 헬퍼 — origin/dev(또는 인자로 준 base) 대비 변경된 .dart 파일만 dart format.
# 전체 트리(`dart format lib test`)는 변경과 무관한 파일까지 재포맷해 PR 노이즈를 유발하므로 변경분만 포맷한다.
# 변경 .dart가 없으면 아무것도 하지 않는다(인자 없는 `dart format`이 cwd 전체를 포맷하는 footgun 회피).
set -eu
base="${1:-origin/dev}"
files=$(git diff --name-only --diff-filter=ACMR "$base" -- '*.dart')
if [ -z "$files" ]; then
  echo "포맷할 변경 .dart 없음 (base: $base)"
  exit 0
fi
echo "$files" | xargs dart format
