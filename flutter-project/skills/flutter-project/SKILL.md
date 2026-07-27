---
name: flutter-project
description: >
  새 Flutter 코드 프로젝트/앱을 처음부터 만들 때 사용. 트리거: "새 Flutter 프로젝트/앱 만들어줘", "/flutter-project", 또는 신규 Flutter repo 생성·아키텍처(feature-first vs layer-first) 판정이 필요하다는 신호.
---

# Flutter 프로젝트 스캐폴드 (아키텍처 판정 포함)

새 Flutter 프로젝트를 만들 때 다음 순서를 수행한다.

1. **연결** — 프로젝트 이름, 생성 위치, org/bundle id를 받고 대상 경로가 비어 있는지 먼저 확인한다.
2. **문서 스캔** — PRD·기능정의서 같은 기획 문서가 있으면 기능 목록, 기능 간 데이터 공유, 성장 신호를 추출한다.
3. **판정 인터뷰** — 문서가 채우지 못한 질문만 물어 bounded context 결합도를 확인하고, feature-first와 layer-first 중 하나를 근거와 함께 제안해 사용자 승인을 받는다.
4. **골격 제시** — 실제 기능명을 반영한 디렉터리 트리와 구조 규칙을 보여주고 다시 승인받는다.
5. **생성** — 승인된 위치에 Flutter repo를 만들고, 동봉된 템플릿과 골격 정본에 따라 파일·의존성·하네스를 구성한다.
6. **완료 보고** — 의존성 설치, 코드 생성, 정적 분석, 테스트, 아키텍처 검사 결과와 생성 트리를 보고한다.

질문 생략 조건, 판정 rubric, 생성 명령, 검증 게이트 5종, 멱등 규칙은 [reference/procedure.md](reference/procedure.md)를 따른다. 디렉터리 트리, layer-first 변형, 이음매, 레이어 계약, 의존성, 하네스, 결정 표는 [reference/skeleton.md](reference/skeleton.md)를 정본으로 삼는다.
