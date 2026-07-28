# dev-harness

개발 세션에서 저장소의 AI 준비도를 감사하고, PR을 검토하고, 계획을 집요하게 스트레스 테스트하며, 세션 토큰 효율을 분석할 때 쓰는 보조 스킬 묶음입니다.

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
