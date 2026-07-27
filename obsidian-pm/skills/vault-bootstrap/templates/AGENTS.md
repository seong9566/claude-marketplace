# 제품 발굴 + 개발 세컨드 브레인 운영 지침 (Product OS)

이 vault는 **제품 발굴 + 개발 LLM Wiki 세컨드 브레인**이다. "무엇을·왜 만드는가"(시장조사→가설→검증)부터 "어떻게 개발/운영하는가"(여러 프로젝트·기술 스택)까지, 좋은 제품을 만들기 위한 지식·결정·시행착오·재사용 체크리스트를 모아 AI와 사람이 함께 검색·활용한다.

- **제품 발굴 앞단**(무엇을·왜)은 `wiki/product/`가 담당한다. 발굴 깔때기이며, 검증 통과 후보만 `wiki/projects/<project>/`로 승격한다.
- 범용 개인 기록(생각·감정·일상)은 이 vault에 넣지 않는다. **제품·개발 맥락만** 다룬다.

## 목적과 범위

- 넣는다: 쓰는 언어·프레임워크 지식, 백엔드/API/배포/인프라, AI agent 운영, 하네스 구축·점검 기준, 프로젝트 PRD/ARCHITECTURE/ADR/tasks, 에러 해결 기록, 재사용 프롬프트·체크리스트·템플릿.
- 넣지 않는다: 무목적 웹 클리핑, 감정/일상 기록, 프로젝트와 무관한 아이디어 조각, 다시 쓸 계획 없는 링크.
- 판단 기준은 **개발 재사용성**이다. 목적 없는 수집은 하지 않는다.

## 3 레이어 (Karpathy LLM Wiki 패턴)

- `raw/`: 사용자가 수집한 불변 원본. AI는 읽기만 하고, 명시 없으면 수정하지 않는다. source of truth.
- `wiki/`: AI가 원본과 대화를 바탕으로 컴파일하는 지식층. AI가 생성/수정/연결/갱신한다.
- `Output/`: 위키 기반 실제 산출물. 프로젝트에 복사하거나 참고한다.
- `AGENTS.md`: 최상위 운영 스키마(이 문서). 각 폴더의 `CLAUDE.md`는 지역 규칙.

## 폴더 구조

| 경로 | 역할 | 수정 규칙 |
| --- | --- | --- |
| `raw/` | 불변 원본 전체 | 명시 없으면 수정 금지 |
| `raw/inbox/` | 미분류 임시 원본 | 읽기 전용 |
| `raw/articles/` | 글·블로그·웹 클리핑 | 읽기 전용 |
| `raw/dev/` | 기술 문서·코드 메모·학습 자료 원본 | 읽기 전용 |
| `raw/docs/` | 공식 문서 | 읽기 전용 |
| `raw/errors/` | 에러 메시지·로그·해결 전 기록 | 읽기 전용 |
| `raw/snippets/` | 재사용 가능한 코드 패턴 | 읽기 전용 |
| `raw/projects/<project>/` | 기능 정의서·회의 메모·PRD 초안 원본 | 읽기 전용 |
| `raw/assets/` | 스크린샷·PDF·다이어그램 | 읽기 전용 |
| `raw/market-research/` | 시장조사 원본: reviews·reddit·articles·youtube·surveys·inbox | 읽기 전용 |
| `wiki/` | AI가 컴파일하는 지식층 | 생성/수정 가능 |
| `wiki/index.md` | 목차·탐색 시작점 | 큰 변경 시 갱신 |
| `wiki/log.md` | 시간순 작업 기록 | 의미 있는 작업마다 append |
| `wiki/sources/` | 원본별 요약 페이지 | 원본 1개당 1페이지 |
| `wiki/topics/` | 반복 개념 | 생성/갱신 |
| `wiki/entities/` | 도구·조직·제품 | 생성/갱신 |
| `wiki/dev/` | 재사용 가능한 개발 노트 | 생성/갱신 |
| `wiki/product/` | 제품 발굴 앞단: markets·competitors·pain-points·hypotheses·decision-log | 생성/갱신 |
| `wiki/projects/<project>/` | PRD/ARCHITECTURE/ADR/tasks + 그 프로젝트의 **기술 스택 특화** 지식·에러·노트 | 생성/갱신 |
| `wiki/harness/` | agent rules·검증 루프·체크리스트 | 생성/갱신 |
| `wiki/errors/` | 에러 해결 카드 | 생성/갱신 |
| `wiki/questions/` | 재사용 가치 있는 질문·답변 | 생성/갱신 |
| `wiki/meta/` | 템플릿·lint 보고서·운영 문서 | 생성/갱신 |
| `Output/` | 위키 기반 산출물 | 생성/수정 가능 |

`Output/` 하위: `dev-notes/`, `checklists/`, `prompts/`, `project-plans/`, `reports/`(시장 리포트는 `reports/market/`).

## 제품 발굴 레이어 (`wiki/product/`)

"무엇을·왜 만드는가"를 정하고 그 의사결정을 축적하는 앞단. 척추는 `wiki/product/decision-log.md`.

- 파이프라인: `raw/market-research/` → `wiki/product/`(markets·competitors·pain-points·hypotheses) → **검증 통과 = 승격** → `wiki/projects/<project>/`(+dev repo).
- 승격 시 자료는 복사하지 말고 wiki link로 연결한다. `wiki/product/`는 킬된 후보 포함 **포트폴리오 기억**으로 남긴다.
- 가설은 `wiki/meta/product-hypothesis-template.md` 양식. 시장 진입/보류·가설 채택/기각은 `decision-log.md`에 append.

## 핵심 운영 규칙

1. `raw/`는 source of truth다. 원본을 고치지 말고, 해석·정리는 `wiki/`에 작성한다.
2. `wiki/`는 한 번 만들고 끝이 아니라 누적되는 컴파일 결과물이다.
3. 새 원본을 ingest할 때는 관련 기존 페이지를 다시 읽고 갱신한다.
4. 같은 지식을 매번 새로 추론하지 말고, 위키에 축적된 연결·요약을 재사용한다.
5. **일반 레이어(`wiki/harness`·`wiki/dev`·`wiki/topics`·`wiki/questions`)는 기술 비종속**으로 유지한다. 특정 언어·프레임워크 특화 지식·에러·노트는 그 기술을 쓰는 `wiki/projects/<project>/`에 기록한다.
6. 프로젝트 맥락은 `wiki/projects/<project>/`에, 하네스 기준은 `wiki/harness/`에 둔다.
7. 에러 해결 기록은 `wiki/errors/`에 카드 형태로 축적한다.
8. 중요한 결정은 ADR(`wiki/projects/<project>/adr/`) 또는 `wiki/product/decision-log.md`에 남긴다.
9. 출처 충돌은 임의로 덮어쓰지 말고 `모순 / 열린 질문` 섹션에 남긴다.
10. 내부 연결은 Obsidian wiki link를 사용한다(예: `[[topics/example]]`). 큰 변경 후 `wiki/index.md`, 의미 있는 작업 후 `wiki/log.md`를 갱신한다.
11. **세션 역할 = PM(문서·참조 전용)**: 이 vault에서의 에이전트 세션은 PRD·스펙·설계 등 문서 산출물(`wiki/`·`Output/`)까지만 만든다. **구현 코드는 작성하지 않는다** — 코드는 별도 dev repo 담당. 예외는 P0 가정 해소용 discovery 스파이크뿐.

## 작업 절차 (운영 루프)

- **ingest**: 원본을 읽고 `wiki/sources/`에 요약, 재사용 개념은 `wiki/topics`·`wiki/dev`, 하네스는 `wiki/harness`, 에러는 `wiki/errors`, 도구/프로젝트는 `wiki/entities`·`wiki/projects`에 반영.
- **query**: 작업 전 `wiki/index.md`부터 관련 페이지를 찾아 근거와 함께 답하고, 재사용 가치가 있으면 `wiki/questions/`에 저장.
- **lint**: 깨진 링크·고립·중복·index 누락·stale claim·미ingest raw를 점검.
- **output**: 체크리스트·프로젝트 계획·프롬프트·가이드를 `Output/`에 뽑아낸다.

## 페이지 양식

```markdown
# 제목

> 한 줄 요약.

## 핵심 요점

## 상세 내용

## 연결 문서
- 관련 주제: [[topics/example]]
- 관련 출처: [[sources/source-title]]

## 모순 / 열린 질문
```

세부 템플릿은 `wiki/meta/`를 참조한다(page / source / error card / project / task / frontmatter).

## 로그 양식

`wiki/log.md`에 append:

```markdown
## [YYYY-MM-DD] type | 제목
- 요약: ...
- 변경 파일: ...
- 후속 작업: ...
```

`type`: `setup` / `ingest` / `query` / `lint` / `output` / `maintenance`.

## 프로젝트 승격과 태스크 추적

- **승격**: 검증 통과 후보를 `wiki/projects/<project>/`로 올린다(`index.md`·`prd.md`). → `project-scaffold` 스킬
- **태스크 추적**: `tasks/` 노트 + `tasks.base`(네이티브 Obsidian Bases 보드). → `project-board-scaffold` 스킬
- 두 스킬 모두 `obsidian-pm` 플러그인에 있다. 구조 정본은 `wiki/meta/project-template.md`.
