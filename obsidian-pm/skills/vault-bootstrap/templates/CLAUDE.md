# Claude Code 운영 지침

이 vault는 **제품 발굴 + 개발 LLM Wiki 세컨드 브레인**이다. Claude Code는 **vault 루트의 `AGENTS.md`를 운영 스키마로 그대로 따른다.** AGENTS.md와 이 문서가 충돌하면 AGENTS.md를 우선한다.

## 기본 동작

- vault 운영 규칙(목적·범위, 폴더 구조, 핵심 원칙, 작업 절차, 페이지/로그 양식)은 모두 `AGENTS.md`에서 읽는다.
- 작업 시작 전에 `AGENTS.md`와 `wiki/index.md`를 먼저 확인한다.
- 기본 작성 언어는 한국어. 기술 용어·코드·API·원문 명칭은 영어를 유지한다.
- `raw/` 원본은 사용자가 명시하지 않으면 수정하지 않는다.
- 기술 스택 특화 지식은 일반 레이어가 아니라 `wiki/projects/<project>/`에 기록한다(`AGENTS.md` 핵심 운영 규칙 5).

## 스킬

`obsidian-pm` 플러그인(마켓플레이스)에서 설치해 쓴다.

- `vault-bootstrap`: 새 vault 구조·규약 생성 (이 vault를 만든 스킬)
- `project-scaffold`: 검증 통과 후보를 `wiki/projects/<P>/`로 승격 (index·prd 생성)
- `project-board-scaffold`: 프로젝트에 태스크 보드(`tasks.base`)와 task 노트 스캐폴딩

## 도구 사용 우선순위

- 파일 읽기: `Read` (cat 금지)
- 파일 편집: `Edit` (sed/awk 금지)
- 파일 생성: `Write`
- 위키/raw 검색: `rg` (Bash)
- 위키 페이지 탐색: 우선 `wiki/index.md` → 필요 시 `rg`

## 출력 규칙

- 작업이 끝나면 `wiki/log.md`에 적절한 `type`(`setup`/`ingest`/`query`/`lint`/`output`/`maintenance`)으로 append한다.
- 새 페이지 생성이나 큰 수정 후에는 `wiki/index.md`를 갱신한다.
- 좋은 답변/비교/분석/계획은 채팅에만 두지 말고 `wiki/questions/`나 `Output/`에 파일로 남긴다.
