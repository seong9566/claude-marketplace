# task 프론트매터 템플릿

PM↔코드 태스크 라이프사이클의 단위. 소스 오브 트루스는 이 노트의 `status` 프론트매터다.
위치: `wiki/projects/<project>/tasks/<ID>-<slug>.md`. 보드는 `tasks.base`가 `status`로 그룹핑한다.
빠른 생성/전환: `project-board-scaffold` 스킬이 동봉한 `task.sh`(`TASK_VAULT`로 vault 지정).

```yaml
---
id: T01                 # PM·코드 공유 안정 키 (브랜치/커밋이 이 ID를 참조)
project: <project>
status: todo            # todo | wip | done  (할 일 | 진행 중 | 진행 완료)
section: pm             # pm | code — 지금 공을 쥔 섹션
title: 제목
created: YYYY-MM-DD
updated: YYYY-MM-DD
repo:                   # 코드 섹션 repo 이름 (vault 밖)
branch:                 # 코드 참조 (예: feat/T01-...)
pr:                     # PR 번호/URL
spec:                   # PM 산출물 링크 (예: "[[2026-06-30-...]]")
tags: [task]
---
```

## 본문 섹션

- `## 목표 / 완료기준(AC)` — 검증 가능한 성공조건
- `## PM 참조` — PRD·ADR·Output 계획 링크 (PM→task)
- `## 코드 참조` — repo·브랜치·핵심 파일·PR (코드→task)
- `## 진행 로그` — `task.sh`가 상태전환을 한 줄씩 append
