# flutter-project 절차 정본 (Claude Code · Codex 공용)

> **구조 정본은 [`skeleton.md`](skeleton.md)** — 이 문서는 판정·생성 절차만 담고, 골격(트리·의존성·하네스·결정 표)은 재정의하지 않는다.

PRD·기능정의서를 읽고 아키텍처(feature-first vs layer-first)를 판정한 뒤, 골격 정본대로 Flutter 코드 repo를 지정한 위치에 생성한다.

## 1. 연결 (입력 수집)

1. **기획 문서** — PRD·기능정의서 같은 기획 문서가 있으면 경로를 받아 읽는다. 없으면 §3 인터뷰가 전부를 커버한다.
2. **코드 repo 위치** — 부모 폴더는 기본값 없이 사용자에게 묻는다. repo 이름 기본값은 프로젝트 slug를 **소문자 snake_case로 정규화**한 것(Dart 패키지명 규칙 `[a-z_][a-z0-9_]*` — `My_App` → `my_app`. 정규화가 필요했으면 사용자에게 결과를 보여 확인). **경로가 이미 존재하면 여기서 중단**(멱등 — 인터뷰까지 돌고 나서 생성에서 막히지 않게, 확인은 맨 앞에서).
3. **org** — bundle id(예: `com.example`). 골격 §8: 기본값 없음, 반드시 묻는다.

## 2. 문서 스캔 (인터뷰 입력 만들기)

기획 문서가 있으면 거기서 추출한다:

- **제품 기능 목록** — 화면 수가 아니라 **PRD의 기능 정의 기준**. 스플래시·온보딩·설정 같은 부속 화면은 기능으로 세지 않는다.
- **기능 간 데이터 공유 관계** — 여러 화면이 같은 핵심 객체(세션·카드·장치)를 보는가.
- **성장 신호** — PRD의 로드맵/Phase 항목.

문서가 신호를 주면 그 항목은 3에서 묻지 않는다(판정 근거로 인용만).

## 3. 판정 인터뷰 (AskUserQuestion — 문서가 못 채운 것만)

| # | 질문 | 역할 |
|---|---|---|
| Q1 | 화면들이 각자 독립 데이터·플로우인가, 하나의 리치 가변 핵심 객체를 공유하는가? | **지배 신호**(bounded context 결합도) |
| Q2 | 출시 시점 제품 기능 수 + 1년 내 추가 전망? | 강한 proxy(대개 Q1과 일치) |
| Q3 | 여러 세션/사람이 기능별 병렬 작업하나? | 보조 |
| Q4 | 기능 단위 on/off·실험·모듈 분리 전망? | 보조 |

**지배 신호가 판정을 확정하면 남은 문항은 묻지 않는다** — 기능들이 독립 bounded context임(핵심 객체 비공유)이 문서로 확인되면 feature-first 확정, Q2~Q4는 노이즈다(잘 문서화된 프로젝트는 인터뷰 0문항이 정상이다). Q1(결합도)과 Q2(기능 수)가 엇갈릴 때만 — 4+ 기능인데 하나의 리치 가변 객체를 공유하거나, 2~3개인데 완전 독립 — Q1이 이긴다. 기능 수는 결합도의 proxy일 뿐 판정 기준이 아니다.

## 4. 판정 규칙 (rubric)

| 조건 | 판정 |
|---|---|
| 기능들이 각자 독립 bounded context(리치 가변 핵심 객체 비공유) | **feature-first** — 기능 4+·성장 예정이면 이 신호가 굳는다. 값객체·read-mostly 공유는 shared/ 커널로(골격 §3③) |
| 하나의 리치 가변 핵심 객체를 모든 화면이 공유(단일 bounded context) | **layer-first 변형**(골격 §2 말미) — 전형적으로 기능 2~3개 고정 |
| 애매 | 결합도가 가른다(기능 수 아님): 공유가 값객체·read-mostly면 feature-first + shared/ / 리치 가변 공유가 지배면 layer-first |

보정 기준(rubric을 바꿀 때 검산용, 골격 §9의 두 기준 repo): Repo B(기능 5개가 서로 독립 context) → feature-first ✓ / Repo A(리치 가변 핵심 객체 하나를 두 화면이 공유·지배 = 단일 bounded context) → layer-first ✓. 두 사례 모두 **결합도가 판정을 몰고 기능 수(5 vs 2)는 결과와 일치할 뿐이다** — 기능 수를 기준으로 삼지 말 것.

판정은 **근거(PRD 인용·인터뷰 답)와 함께 제시하고 사용자 승인을 받는다** — Skill이 확정하지 않는다.

## 5. 골격 제시

골격 정본 §2(판정이 layer-first면 §2 말미 변형 섹션)를 기반으로, **PRD의 실제 기능명이 매핑된 트리**를 보여준다(예: `features/order/`·`features/catalog/` — placeholder가 아니라 이 프로젝트의 이름). 사용자 승인 후 6으로.

## 6. 생성

**6.1의 `flutter create`를 뺀 이하 모든 명령은 생성된 `<경로>` 안(cwd)에서 실행한다** — 스킬 실행 위치와 무관하게 게이트·hook 경로(`.claude/hooks/…`·`.githooks/…`)는 새 repo 기준 상대경로다.

1. `flutter create --org <org> --project-name <이름> --platforms=android,ios <경로>`
2. 골격 정본 §2(또는 변형)·§6(의존성 — **재계산 금지, 목록 그대로**)·§8(결정 표)대로 파일 작성. `[T]` 태그 파일은 이 스킬의 `templates/` 실물을 읽어 패키지명만 바꿔 이식하고, `[신작]`은 §8 구성대로 작성한다. 실제 feature와 `test/` 미러, `docs/ARCHITECTURE.md`, `pubspec.yaml`은 템플릿에 없으므로 스캐폴딩 시 PRD와 골격 정본에 맞춰 생성한다. PM vault를 함께 쓰는 경우에만, 새 repo `CLAUDE.md`에 해당 vault의 핸드오프 지침을 연결하는 선택 단계를 수행한다.
3. `git init`. **hooksPath·초기 커밋은 아직** — 게이트(6.4)를 통과한 뒤 6.5에서 한다.
4. **검증 게이트(전부 통과해야 완료)**: `flutter pub get` → `dart run build_runner build --delete-conflicting-outputs` → `flutter analyze`(0 issues) → `flutter test` → `.claude/hooks/check-architecture.sh --report`(9종 PASS). **게이트가 실패하면** 그 자리에서 고쳐 남은 게이트만 이어 재실행한다 — repo가 이미 있어 스킬을 다시 부르면 1(연결)에서 abort되므로 **재-invoke 금지**(부분 실패 복구는 수동).
5. `git config core.hooksPath .githooks` → **초기 커밋 1개**(scaffold). 게이트 통과·codegen 산출 뒤에 커밋하므로 pre-commit(`check-architecture.sh` + `check.mjs --staged`)이 생성물 부재로 막히지 않는다.

## 7. 완료 보고

- 생성 트리 + 검증 결과. **원격(GitHub) 생성·push는 하지 않는다** — 사용자 판단.

## 주의

- **멱등**: 코드 repo 경로 존재 확인은 **1(연결)에서 이미 수행** — 6(생성) 직전에 한 번 더 재확인한다(연결과 생성 사이에 시간이 흐를 수 있음). 어느 쪽이든 존재하면 중단(덮어쓰지 않음).
- **판정을 건너뛰지 않는다** — 사용자가 구조를 명시했어도 rubric 결과와 다르면 근거를 보여주고 재확인한다. 인터뷰가 이 Skill의 존재 이유다.
- **실물 템플릿 동봉**: 실물 템플릿은 이 스킬의 `templates/`에 동봉되며, 생성은 그 템플릿 + 골격 문서가 함께 주도한다.
