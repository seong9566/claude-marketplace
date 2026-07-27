---
name: project-board-scaffold
description: Use when an Obsidian PM vault project under wiki/projects/ has PRD·설계 문서는 있는데 task 추적이 없어 보드를 새로 올릴 때 — "task보드 만들어줘", "보드 스캐폴딩", "task 추적되게 해줘", "task 동기화", "진행 상황 보드로", 또는 이미 진행한 작업을 task 노트로 소급 기록해야 할 때.
---

# 프로젝트 태스크 보드 스캐폴딩

Obsidian PM vault의 `wiki/projects/<P>/`에 **보드(`tasks.base`) + task 노트(`tasks/T01…`)**를 올려 PM↔코드 추적을 시작한다.

전제 레이아웃: vault 루트에 `wiki/projects/<프로젝트>/`가 있고, task 한 개 = 노트 한 개(프론트매터 `status`가 진실), 보드는 네이티브 Obsidian **Bases**(`.base`)가 `status`로 그룹핑한다. 커뮤니티 플러그인 불필요.

## 도구 — 동봉한 `task.sh`

이 스킬 디렉터리의 `task.sh`가 보드 생성·노트 생성·상태 전환을 담당한다. **vault 경로는 `TASK_VAULT`로 준다.**

```bash
SKILL_DIR=<이 SKILL.md가 있는 디렉터리>
export TASK_VAULT=<vault 루트 절대경로>       # wiki/projects/ 를 담고 있는 폴더
bash "$SKILL_DIR/task.sh"                     # 인자 없이 실행하면 사용법
```

`TASK_VAULT`가 없거나 그 아래 `wiki/projects/`가 없으면 **아무것도 하지 않고 종료**한다. vault 안(`.claude/scripts/`)에 직접 둔 경우에는 두 단계 위를 vault로 보고 `TASK_VAULT` 없이도 동작한다.

## 사전 확인

- 대상이 `wiki/projects/<P>/`에 있고 PRD 또는 index가 있다 — **없으면 먼저 승격**한다(보드부터 만들지 않는다).
- 이미 `tasks.base`가 있으면 스캐폴딩이 아니라 task 추가다 → `task.sh new`만 쓴다.

## 절차

### 1. 보드 생성 (기계적)

```bash
bash "$SKILL_DIR/task.sh" board <P>     # 있으면 no-op
```

`new`가 자동 호출하므로 3단계에서 노트를 만들면 보드는 따라온다. 이 명령은 **task는 있는데 보드만 없는 프로젝트**를 뒤늦게 채울 때 쓴다.

### 2. 작업 목록 초안 → **승인 후 생성** (판단)

문서에서 뽑는다. 추측으로 만들지 않는다.

| 출처 | 뽑을 것 |
| --- | --- |
| PRD `## 릴리스` / 개발 순서 | 남은 작업의 뼈대 — 단계가 곧 관문이라 게이트 판정과 맞물린다 |
| PRD 미검증 가정 · 열린 항목 | 단계에 안 들어가는 **독립 리스크** task |
| 프로젝트 index의 상태·판정 표, vault 작업 로그 | **이미 끝난 일**(백필 대상)과 그 판정 문구 |

초안을 만든 뒤 `AskUserQuestion`으로 두 가지를 확정한다 — **묻기 전에 노트를 만들지 않는다.**
- **백필 입자**: 완료 건을 개별 task로 vs 요약 1건 vs 백필 없음
- **남은 작업 단위**: 릴리스 단계 단위 vs 기능 단위 vs 하이브리드

### 3. task 노트 작성

- **ID는 프로젝트 안에서만 유일하다.** 다른 프로젝트에 T01이 있어도 이 프로젝트는 T01부터 시작한다.
- 백필은 `created`=실제 작업일, `updated`=오늘, `## 진행 로그`에 소급 기록임을 한 줄로 남긴다.
- 판정·경고 문구는 **원 실측 문서에서 인용**한다(요약해 새로 쓰지 않는다 — 판정이 미묘하게 뒤집힌다).
- 여러 건을 한 번에 만들 땐 `task.sh new` 반복 대신 같은 프론트매터로 파일을 직접 쓴다 → 이유는 §흔한 실수.

### 4. 연결 (빠뜨리기 쉬움)

- `wiki/projects/<P>/index.md`에 보드 섹션 + 임베드 `![[projects/<P>/tasks.base#보드]]`
- vault 최상위 index에 보드 한 줄
- vault 작업 로그에 엔트리

### 5. 검증

```bash
bash "$SKILL_DIR/task.sh" ls --project <P>                  # 상태 분포가 의도대로인가
rg -o "\[\[T[0-9]+\]\]" "$TASK_VAULT/wiki/projects/<P>/tasks/"   # 결과 있으면 깨진 링크
```

보드 파일은 프로젝트마다 **필터 줄만** 달라야 한다(`diff`로 대조). wikilink는 생성한 노트 + 손댄 index/log까지 전수 검사해 대상 없는 링크가 0이어야 한다.

### 6. 후속 통보

코드 repo의 Stop 훅이 브랜치명에서 task ID를 뽑아 자동 `wip`을 걸 수 있는데, **`--project <P>`가 있어야** 동작한다. vault 밖이라 여기서 못 고치니 **사용자에게 반드시 알린다**.

## 흔한 실수

| 실수 | 결과 | 대신 |
| --- | --- | --- |
| task 링크를 `[[T13]]`으로 | 파일명은 `T13-슬러그`라 **안 잡힌다** | `[[projects/<P>/tasks/T13-슬러그\|T13]]` |
| 백필을 `task.sh done`으로 전환 | 건마다 **Discord 알림**이 나간다(`DISCORD_WEBHOOK_URL` 설정 시) | 파일을 최종 상태로 직접 작성 |
| `## 진행 로그`를 오래된-먼저로 씀 | `task.sh`는 **최신을 맨 위에 넣는다**(prepend) → 다음 전환에서 순서가 뒤엉킨다 | 최신이 위, `생성 →`가 맨 아래 |
| 전환 명령에 `--project` 생략 | 같은 ID가 여러 프로젝트에 있으면 **거부**된다 | 항상 `--project` |
| 보드부터 만들고 task는 나중에 | 빈 보드가 남아 방치된다 | 2~3단계까지 한 번에 |
| PRD 없이 task부터 | 근거 없는 작업 목록이 된다 | 승격·PRD가 먼저 |

## 보드가 하는 일

`tasks.base`는 `file.hasTag("task")` + `project == "<P>"`로 그 프로젝트 task만 모아 `status`를 ① 할 일 / ② 진행 중 / ③ 진행 완료 세 칼럼으로 그룹핑한다(cards 뷰) + 전체 table 뷰. 보드를 손으로 복사하지 말고 **`task.sh board`로 만든다** — 필터 수정 누락이 가장 흔한 사고다.
