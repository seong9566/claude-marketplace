# dev-harness

개발 세션에서 계획을 집요하게 스트레스 테스트할 때 쓰는 보조 스킬입니다. PR 코드 리뷰(`code-review`)는 0.4.0에서 뺐다 — superpowers `requesting-code-review`를 쓴다.

## 이름 충돌

**이 이름은 개인 스킬로도 흔히 쓰는 이름이다.** `~/.claude/skills/<name>/`에 같은 이름을 이미 갖고 있을 가능성이 높다 — 이 repo 저자의 머신에도 있다.

둘은 서로를 덮어쓰지 않는다. 플러그인 스킬은 `dev-harness:grilling`으로, 개인 스킬은 `grilling`으로 각각 불린다. 문제는 **어느 쪽이 도는지 헷갈린다**는 것이고, 그 대가는 두 가지다.

- 스킬을 지목할 때는 **접두를 붙인다** — `dev-harness:grilling`. 맨이름은 개인 사본으로 간다.
- 개인 사본이 이 플러그인에서 갈라져 나온 것이라면 **한 벌만 남긴다.** 두 벌을 두면 한쪽만 고치고도 고쳤다고 여기게 된다. 이 repo에서 실제로 그랬다 — 스킬 문서들이 `~/.claude/skills/…/scripts/`를 하드코딩해, 저자 머신에서는 개인 사본이 돌아 정상으로 보이고 설치자에게는 존재하지 않는 경로였다. 지금은 `${CLAUDE_PLUGIN_ROOT}` 기준으로 고쳐져 있다.

## 수록 스킬

| 스킬명 | description |
|---|---|
| `grilling` | Grill the user relentlessly about a plan, decision, or idea. |

## 요구사항

| 스킬명 | 외부 의존 |
|---|---|
| `grilling` | 없음. |
