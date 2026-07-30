# dev-harness

개발 세션에서 저장소의 AI 준비도를 감사하고, PR을 검토하고, 계획을 집요하게 스트레스 테스트하며, 세션 토큰 효율을 분석할 때 쓰는 보조 스킬 묶음입니다.

## 이름 충돌

**이 다섯 이름은 개인 스킬로도 흔히 쓰는 이름이다.** `~/.claude/skills/<name>/`에 같은 이름을 이미 갖고 있을 가능성이 높다 — 이 repo 저자의 머신에는 다섯 개가 전부 있다.

둘은 서로를 덮어쓰지 않는다. 플러그인 스킬은 `dev-harness:code-review`로, 개인 스킬은 `code-review`로 각각 불린다. 문제는 **어느 쪽이 도는지 헷갈린다**는 것이고, 그 대가는 두 가지다.

- 스킬을 지목할 때는 **접두를 붙인다** — `dev-harness:grilling`. 맨이름은 개인 사본으로 간다.
- 개인 사본이 이 플러그인에서 갈라져 나온 것이라면 **한 벌만 남긴다.** 두 벌을 두면 한쪽만 고치고도 고쳤다고 여기게 된다. 이 repo에서 실제로 그랬다 — 스킬 문서들이 `~/.claude/skills/…/scripts/`를 하드코딩해, 저자 머신에서는 개인 사본이 돌아 정상으로 보이고 설치자에게는 존재하지 않는 경로였다. 지금은 `${CLAUDE_PLUGIN_ROOT}` 기준으로 고쳐져 있다.

## 수록 스킬

| 스킬명 | description |
|---|---|
| `ai-readiness-cartography` | Audits any repository against the v2 AI-Ready rubric (100 pts · 7 categories — Navigation, Context Quality, Tribal Knowledge, Dependency Mapping, Verification Gates, Freshness, Agent Outcomes) and produces a professional single-file HTML dashboard plus an ROI-ranked action list. |
| `code-review` | Use when a pull request needs a code review — especially right after `gh pr create` when the diff changes behavior/logic. |
| `grilling` | Grill the user relentlessly about a plan, decision, or idea. |
| `grill-me` (`grilling`의 별칭) | A relentless interview to sharpen a plan or design. |
| `improve-token-efficiency` | Claude Code 세션 JSONL 로그를 파싱하여 토큰/컨텍스트 효율 리포트(HTML 대시보드 + $ 절감안)를 생성하는 스킬. |

## 요구사항

| 스킬명 | 외부 의존 |
|---|---|
| `ai-readiness-cartography` | Python 3.10+ (표준 라이브러리만 사용). Git이 있으면 현재 브랜치를 대시보드 메타데이터에 기록합니다. |
| `code-review` | Git 저장소와 GitHub PR, 인증된 GitHub CLI(`gh`), Node.js, 로컬 ChatGPT 인증을 사용하는 OpenAI Codex 플러그인의 `codex-companion.mjs`. |
| `grilling` | 없음. |
| `grill-me` | 외부 의존 없음. 함께 수록된 `grilling` 스킬을 호출합니다. |
| `improve-token-efficiency` | Python 3.9+ (표준 라이브러리만 사용), Claude Code 세션 JSONL 로그. 생성된 대시보드 차트는 Chart.js 4.4.0 CDN을 사용하므로 브라우저의 네트워크 연결이 필요합니다. |
