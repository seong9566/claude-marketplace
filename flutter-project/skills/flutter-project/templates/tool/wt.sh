#!/bin/sh
# 병렬 작업용 워크트리 생성 — base는 항상 최신 dev(메인 트리가 어느 브랜치든 무관).
# 새 세션이 "지금 떠 있는 브랜치"(다른 세션 것) 위에서 분기해 쌓이는 stacking(feat1→feat2)을
# 구조적으로 막는다. 동시에 두 갈래 이상 작업할 땐 각각 이걸로 워크트리를 따로 판다.
#
# 전제: main은 릴리즈 전용이고 작업은 dev에서 파생한다(.githooks/pre-push와 같은 모델).
#       다른 브랜치 모델을 쓰면 아래 base 계산을 그 모델에 맞게 고친다.
#
# 사용: tool/wt.sh <branch>
#   예: tool/wt.sh fix/empty-state
#       tool/wt.sh chore/logging-convention
set -e

branch="$1"
if [ -z "$branch" ]; then
  echo "usage: tool/wt.sh <branch>   예: tool/wt.sh fix/empty-state" >&2
  exit 2
fi

root=$(git rev-parse --show-toplevel)
slug=$(printf '%s' "$branch" | tr '/' '-')
dir="$root/.claude/worktrees/$slug"

if [ -e "$dir" ]; then
  echo "이미 존재: $dir" >&2
  exit 1
fi

# base는 항상 최신 dev. origin 닿으면 origin/dev, 오프라인이면 로컬 dev로 폴백.
git -C "$root" fetch origin dev --quiet 2>/dev/null || true
base=origin/dev
git -C "$root" rev-parse --verify --quiet "$base" >/dev/null 2>&1 || base=dev

git -C "$root" worktree add "$dir" -b "$branch" "$base"
# 새 브랜치가 origin/dev를 upstream으로 물지 않도록 끊는다(첫 push는 git push -u origin <branch>).
git -C "$dir" branch --unset-upstream 2>/dev/null || true
echo "✅ 워크트리: $dir"
echo "   브랜치 '$branch' (base $base) — 메인 트리 브랜치와 무관하게 항상 dev 기반"
echo "   다음: cd \"$dir\"  (작업 끝나면 메인 root에서 git worktree remove \"$dir\")"
