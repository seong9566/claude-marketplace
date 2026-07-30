# sdd-harness

이 플러그인은 개발 계획의 각 작업을 subagent에 위임해 실행하고, TDD·체계적 디버깅·코드리뷰·워크트리 격리 같은 개발 절차를 함께 적용하는 개발 하네스 스킬 묶음입니다.

## 출처와 라이선스

업스트림 [superpowers](https://github.com/obra/superpowers) v6.2.0(MIT, Jesse Vincent) 파생. 라이선스 전문은 LICENSE 참조.

## 이름 충돌

**수록 스킬 14종의 이름이 업스트림 `superpowers`와 전부 같다.** 파생이므로 당연한 결과지만, 결과는 그냥 넘길 일이 아니다.

둘 다 켜 두면 `sdd-harness:brainstorming` 과 `superpowers:brainstorming` 처럼 **거의 같은 스킬이 14쌍** 모델에게 동시에 제시된다. 접두가 다르니 덮어쓰지는 않지만, 고른 쪽이 내가 고친 쪽이라는 보장이 없다 — 한쪽만 고쳐 두고 다른 쪽이 도는 것이 이 구조에서 가장 흔한 실패다.

**둘 중 하나만 켠다.** 이 플러그인을 쓰기로 했다면 `superpowers`는 끄고 들어온다 — `/plugin` 메뉴에서 끄거나, `~/.claude/settings.json` 의 `enabledPlugins` 에 `"superpowers@claude-plugins-official": false` 를 둔다.

> 프로젝트 `.claude/settings.local.json` 이 전역 설정을 덮으므로, 전역에서 껐는데도 겹쳐 보이면 그 파일부터 확인한다.

## 수록 스킬

| 스킬명 | description 첫 문장 |
| --- | --- |
| `brainstorming` | You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. |
| `choosing-an-implementer` | 계획 실행 직전에 **구현자를 누구로 할지**(외부 CLI 에이전트 / 하네스 내부 subagent / 나) 정하고, 태스크 성질로 권장안을 붙여 사용자에게 묻는다 |
| `dispatching-parallel-agents` | Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies |
| `executing-plans` | Use when you are implementing a written plan yourself, task by task with review checkpoints, rather than dispatching a fresh subagent per task |
| `finishing-a-development-branch` | Use when implementation is complete, all tests pass, and you need to decide how to integrate the work |
| `receiving-code-review` | Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation |
| `requesting-code-review` | Use when completing tasks, implementing major features, or before merging to verify work meets requirements |
| `subagent-driven-development` | Use when executing an implementation plan whose tasks are mostly independent, by dispatching a fresh implementer subagent per task with a review after each |
| `systematic-debugging` | Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes |
| `test-driven-development` | Use when implementing any feature or bugfix, before writing implementation code |
| `using-git-worktrees` | Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via native tools or git worktree fallback |
| `verification-before-completion` | Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always |
| `writing-plans` | Use when you have a spec or requirements for a multi-step task, before touching code |
| `writing-skills` | Use when creating new skills, editing existing skills, or verifying skills work before deployment |

## 이 fork가 바꾼 것

업스트림 6.2.0을 base로 하고, 아래만 바꿨다. 스킬 본문의 나머지는 원본 그대로다.

**재패키징에서 필연적으로 따라온 것**

- 스킬 간 상호 참조 접두를 `superpowers:` → **`sdd-harness:`** 로 전환(21곳). 그대로 두면 이 플러그인만 설치한 환경에서 존재하지 않는 스킬을 가리킨다.
- `using-superpowers` 스킬 **제외** — 업스트림 플러그인의 자체 부트스트랩이라 진짜 superpowers와 함께 설치되면 충돌한다. 그 제외로 죽은 상대 링크 3곳(`executing-plans`·`writing-skills`)을 정리했다.
- `brainstorming/scripts/server.cjs`의 버전 조회에 `.claude-plugin/plugin.json`을 추가 — 이 플러그인 구조에선 기존 두 경로가 모두 없어 버전이 `unknown`으로 떨어졌다.

**문서 경로 중립화**

- **런타임 디렉터리** `.superpowers/sdd/`·`.superpowers/brainstorm/` → **`.sdd-harness/sdd/`·`.sdd-harness/brainstorm/`** (스크립트 4종 + 문서). 스킬이 남의 repo 작업 트리에 만드는 디렉터리라 업스트림 브랜드를 그대로 쓸 이유가 없다. self-ignoring `.gitignore`도 두 스킬이 공유하도록 `.sdd-harness/` 루트 한 곳으로 모았다(전에는 SDD만 `sdd/` 아래에 만들었고 brainstorm은 repo의 `.gitignore` 항목에 의존했다 — 그 항목이 없는 repo에선 세션 파일이 노출됐다).
- `docs/superpowers/plans/` → **`docs/plans/`**, `docs/superpowers/specs/` → **`docs/specs/`** (8곳). 업스트림 경로는 플러그인 이름으로 브랜딩돼 있어 다른 repo에 그대로 쓸 수 없었다. 두 경로 모두 **기본값일 뿐이고 repo CLAUDE.md가 지정하면 그쪽이 이긴다**는 문장을 함께 넣었다.

**보탠 것**

- `writing-plans` — **Red Verification** 절 신설. Step 2에서 테스트가 예상한 이유로 실패하지 않으면 의심할 대상은 구현이 아니라 테스트라는 규율, 그리고 그래서 계획의 Red 기대값에 실패 **메시지**까지 적어야 한다는 근거. 무효 테스트는 구현 전후로 모두 green이라 아무도 잡아주지 않는다.
- `writing-plans`·`brainstorming` — 모델 티어 지침(싼 티어면 올리고 끝나면 내린다).
- `brainstorming` — 결정·승인·선택은 산문에 묻지 말고 런타임의 구조화 질문 도구(Claude Code는 `AskUserQuestion`)로 물으라는 지침.
- `subagent-driven-development` — **Without the Bundled Scripts** 절 신설. 번들 bash 스크립트 3종(`sdd-workspace`·`task-brief`·`review-package`)을 못 쓰거나 쓰기 싫은 환경을 위한 인라인 대체표와, 그때 잃는 것 두 가지(컨텍스트 절약·플랜별 격리)를 명시했다. 진행 원장은 파일 대신 하네스 Task 목록을 쓴다.
- `choosing-an-implementer` — **구현자 선택 게이트 신설.** 업스트림은 계획을 실행할 때 구현자가 하네스 내부 subagent라고 암묵적으로 전제한다. 그러나 실제 선택지는 셋(외부 CLI 에이전트·내부 subagent·컨트롤러 직접)이고 각각 비용 주체가 달라 **사용자가 정할 문제**다. 다만 계획을 읽은 쪽은 나이므로 선택지만 늘어놓지 말고 태스크 성질로 **권장안과 근거를 붙이도록** 규정했다. 판정 기준표는 이 스킬 한 곳에만 두고, 실행 진입점 3곳(`writing-plans`·`subagent-driven-development`·`executing-plans`)에는 부르라는 한 줄만 넣었다 — 표를 복제하면 조용히 어긋난다. `executing-plans`에도 넣은 이유는 그 경로가 "subagent 없이 돌릴 때의 폴백"이라 **아무것도 고르지 않은 채 도착하는 자리**이기도 하기 때문이다.

  이어서 **게이트를 무효화하던 경로 두 개를 끊었다.** ①`executing-plans`는 "subagent가 있으면 무조건 `subagent-driven-development`를 쓰라"고 지시해, ③을 고른 사람이 두 홉 만에 ②로 되돌려졌다 — 이제 그 안내는 **슬롯이 비어 있을 때만** 발화한다. ②`writing-plans`는 자체적으로 "subagent냐 inline이냐" 2지선다를 따로 물어, ①이 통째로 빠진 채 결정이 두 번 내려졌다 — 이제 게이트로 넘긴다. 함께 `description` 3개가 "session"이라는 같은 단어를 서로 다른 축(어느 세션에서 실행하나 / 누가 코드를 쓰나)으로 쓰던 것을 **구현자 축 하나로** 통일했다.

**스크립트 없는 변형을 별도 스킬로 두지 않은 이유**

한때 `subagent-driven-development-lite`라는 두 번째 스킬로 담았다가 **되돌려 full 안의 한 절로 흡수했다.** 계기는 "이건 왜 있냐"는 물음이었고, 답이 "발견된 필요가 아니라 보존된 fork라서"였다. 실측: 281줄과 505줄이 같은 계약(태스크마다 새 구현자 → 태스크 리뷰 → 유계 fix 루프 → 최종 전체 리뷰)을 담고 있었고, 삭제 전 대조에서 lite에 **고유 내용은 0건**이었다. 차이는 전부 배관(스크립트 3종·원장 위치)이라 표 하나로 들어간다. 사본을 하나 줄이려고 시작한 이관에서 사본을 하나 늘리고 있었던 셈이다.

## repo마다 설정할 것

이 플러그인은 프로젝트 고유값을 안에 박지 않는다. 아래는 repo의 `CLAUDE.md`에 적어 두면 스킬이 그걸 따른다.

| 항목 | 기본값 | 비고 |
| --- | --- | --- |
| 계획 문서 디렉터리 | `docs/plans/` | `writing-plans`가 여기에 쓴다 |
| 스펙·설계 문서 디렉터리 | `docs/specs/` | `brainstorming`이 여기에 쓴다 |
| 브랜치·워크트리 규약 | 없음 | `using-git-worktrees` 기본 동작. `feat/*` 같은 규약이 있으면 CLAUDE.md에 적는다 |
| 최종 리뷰 경로 | `requesting-code-review` | 별도 리뷰 명령·PR 시점 리뷰어를 쓰면 그걸 적는다 |
| 모델 티어 | `haiku`/`sonnet`/`opus` 일반명 | 특정 모델 ID로 고정하지 않았다 — 세대가 바뀌면 stale해지기 때문 |
| 구현자(누가 코드를 쓰는가) | 매번 묻는다 | `choosing-an-implementer`가 묻는다. 항상 같은 쪽을 쓰는 repo면 CLAUDE.md에 적어 두면 그 스킬이 묻지 않고 넘어간다. 외부 CLI 에이전트를 쓴다면 어떤 CLI인지·호출 경로도 함께 적는다(플러그인은 특정 CLI를 전제하지 않는다) |

`subagent-driven-development`의 원장·산출물은 `.sdd-harness/sdd/<plan-basename>/`, `brainstorming`의 세션 파일은 `.sdd-harness/brainstorm/<session-id>/` 아래 생긴다. `.sdd-harness/`에 self-ignoring `.gitignore`가 자동 생성되므로 repo `.gitignore`에 따로 넣을 일은 없다.
