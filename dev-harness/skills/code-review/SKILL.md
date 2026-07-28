---
name: code-review
description: Use when a pull request needs a code review — especially right after `gh pr create` when the diff changes behavior/logic. Runs a single-pass Codex adversarial review (local ChatGPT auth, zero OpenAI API cost), keeps only high-confidence findings, and posts a short bullet summary comment plus per-finding line-anchored inline comments (with code blocks) via the GitHub reviews API. Triggers on "PR 리뷰", "리뷰해줘", "code review", "review this PR", "코드 리뷰", or an automated post-PR review gate. Not for fixing code — review only.
---

# Code Review — Codex adversarial 엔진 (과금 0)

내가 만든 PR을 **로컬 Codex CLI(ChatGPT 구독 인증)**로 리뷰하고, 결과를 심각도·2계층 "PR 리뷰 글"로 게시한다. OpenAI API 과금 0. **리뷰 전용 — 코드 수정 금지.**

> **먼저 [`policy.md`](policy.md)를 읽는다.** 게이트·적대 스탠스·focus 라우팅·확신도·출력 형식·수렴 판단·게시 절차는 **전부 거기가 정본**이고 Codex CLI판과 공유한다. 이 파일은 **Claude Code에서의 실행 방법**만 담는다. 정책을 바꿔야 하면 이 파일이 아니라 `policy.md`를 고친다.

엔진 결정 근거: codex `adversarial-review`가 적대 스탠스·attack-surface·발견별 confidence(0-1)·그라운딩·calibration을 **네이티브로** 갖는다. 그래서 별도 확신도 채점 패스·다중 렌즈 에이전트를 만들지 않는다. Risk로 focus만 조절하는 **1패스** 리뷰다.

## 실행 — codex adversarial 1패스

**먼저 cwd를 맞춘다 — 실행 cwd = 리뷰 대상 워크트리.** 메인 트리나 다른 워크트리에서 돌리면 `--base` diff가 비거나 남의 변경을 읽어 **리뷰가 통째로 무의미해진다**(2026-07-24까지 3회 연속 실수). `gh pr view`·`gh pr diff`·`gh repo view`도 전부 cwd의 remote·브랜치를 따르므로, 아래 첫 명령 전에 `cd <대상 워크트리 절대경로>`를 확인한다.

```bash
cd <리뷰 대상 워크트리 절대경로>
base=$(gh pr view <PR#> --json baseRefName -q .baseRefName)
# adversarial-review는 --base 와 focus 텍스트를 함께 받는다(review와 달리 배타 아님)
node "$HOME/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs" \
  adversarial-review --base "origin/$base" --wait "<policy §적대 스탠스의 focus 텍스트>" > /tmp/cr-raw.md
```
- **`origin/`을 붙이는 이유**: `baseRefName`은 `dev`처럼 브랜치명만 준다. 그대로 넘기면 codex가 **로컬 `dev`**를 본다 — 메인 트리는 브랜치 전환·머지가 훅으로 막혀 있어 로컬 base 브랜치가 며칠씩 뒤처지고, 그러면 **이미 머지된 남의 PR이 diff에 섞여** 오탐이 난다(2026-07-27 PR #96 실측: 로컬 `dev`가 6일 전 커밋이라 PR #92·#93 머지분까지 리뷰 대상에 들어갔다).
- 작은 PR은 `--wait`, 큰 PR은 `--background`(완료는 `/codex:status`). 인증 1개 공유라 워크트리 여러 개 **동시 리뷰 금지**(순차).
- codex의 구조화 출력(파일·line·confidence·recommendation)을 policy §출력 형식으로 옮긴다.

## 폴백
- codex usage/rate limit이면 재시도 없이 `/code-review high --comment`(자체 인라인 게시 — 별도 헤더 코멘트 추가 안 함).
- **원인 불명 실패는 폴백하지 않고 보고**한다.
