# seong-skills

개인용 Claude Code 플러그인 마켓플레이스.

## 설치

```
/plugin marketplace add seong9566/claude-marketplace
/plugin install obsidian-pm@seong-skills
```

비공개 repo라 설치하는 기기에 GitHub 인증(`gh auth login` 또는 git credential)이 있어야 한다.

## 플러그인

### `obsidian-pm`

Obsidian PM vault 운영 스킬.

세 스킬이 **vault 생성 → 프로젝트 승격 → 태스크 추적** 한 줄로 이어진다. 각 단계는 다음 단계를 안내만 하고 대신 하지 않는다.

| 스킬 | 언제 | 만드는 것 |
| --- | --- | --- |
| `vault-bootstrap` | 빈 폴더에서 새 vault를 세울 때, 또는 기존 vault에 운영 규약이 없을 때 | 폴더 26개 + `AGENTS.md`·`CLAUDE.md`·`wiki/index.md`·`log.md` + `wiki/meta/` 템플릿 11종 |
| `project-scaffold` | 검증 통과 후보를 프로젝트로 승격할 때 | `wiki/projects/<P>/`의 `index.md` + `prd.md`(공통분모 5섹션) **둘만** |
| `project-board-scaffold` | PRD가 서고 task 추적이 필요할 때 | `tasks.base` 보드 + `tasks/` 노트, 기존 진행분 소급 기록 |

**vault 경로는 `TASK_VAULT` 환경변수로 준다**(`vault-bootstrap`만 인자로 받는다). 동봉 스크립트는 `TASK_VAULT/wiki/projects/`가 없으면 아무것도 하지 않고 종료한다.

```bash
bash <vault-bootstrap>/bootstrap.sh ~/path/to/new-vault      # 기존 파일은 덮어쓰지 않음(멱등)
export TASK_VAULT=~/path/to/new-vault
bash <project-scaffold>/project-new.sh 내-앱 --title "내 앱" --summary "한 줄 정의"
bash <project-board-scaffold>/task.sh new T01 "첫 작업" --project 내-앱 --section pm
```

```bash
export TASK_VAULT=~/path/to/vault
bash <스킬 디렉터리>/task.sh board <프로젝트>
bash <스킬 디렉터리>/task.sh new T01 "제목" --project <프로젝트> --section pm
bash <스킬 디렉터리>/task.sh wip T01 --project <프로젝트> --section code
bash <스킬 디렉터리>/task.sh ls --project <프로젝트>
```

전제 vault 레이아웃: `wiki/projects/<프로젝트>/tasks/<ID>-<슬러그>.md` 한 개 = task 한 개, 프론트매터 `status`(`todo`/`wip`/`done`)가 소스 오브 트루스, 보드는 네이티브 Obsidian **Bases**가 렌더한다(커뮤니티 플러그인 불필요).

## 주의

- **task ID는 프로젝트 안에서만 유일하다.** 여러 프로젝트에 같은 ID가 있으면 전환 명령이 거부되며 `--project`를 요구한다.
- 코드 repo의 Stop 훅으로 자동 `wip`을 걸 때도 `--project`가 필요하다.
- `DISCORD_WEBHOOK_URL`이 설정돼 있으면 상태 전환마다 알림이 나간다(미설정이면 no-op).

### `flutter-project`

새 Flutter repo를 **아키텍처 판정부터** 스캐폴딩한다.

```
/plugin install flutter-project@seong-skills
```

PRD를 읽고 **feature-first vs layer-first**를 bounded context 결합도로 판정한 뒤(기능 수가 아니다 — 그건 약한 proxy다), 동봉 템플릿으로 repo를 만들고 검증 게이트 5종을 통과시킨다. 판정 근거는 `docs/adr/0001-architecture-*.md`로 남는다.

동봉 템플릿: 구조 검사 9종(Stop hook + pre-commit)·git 훅·커버리지 게이트·CI·릴리즈 워크플로·ADR 체계·`core` 인프라(network/storage/errors/logging)·`sealed Result<T>`.

### `sdd-harness`

계획을 subagent에 위임해 실행하는 개발 하네스 스킬 **15종**. 업스트림 [superpowers](https://github.com/obra/superpowers) v6.2.0(MIT, Jesse Vincent) 파생 — 상세·변경점·라이선스는 [`sdd-harness/README.md`](sdd-harness/README.md).

```
/plugin install sdd-harness@seong-skills
```

`brainstorming` → `writing-plans` → `choosing-an-implementer` → `subagent-driven-development` 한 줄로 이어진다. 실행 직전에 **구현자를 누구로 할지**(외부 CLI 에이전트·하네스 내부 subagent·직접) 권장안과 함께 묻고, 그다음 태스크마다 새 구현자 subagent를 띄우고, 리뷰를 걸고, 실패하면 **유계 fix 루프**(라운드 1–3 재개 → 4–5 상위 모델 → 5라운드 breaker)를 돈다. bash를 못 쓰는 repo는 `-lite` 변형을 쓴다.

경로·브랜치 규약 같은 프로젝트 고유값은 플러그인에 박지 않았다 — repo의 `CLAUDE.md`에 적으면 스킬이 그걸 따른다(설정 항목 표는 위 README 참조).

> `superpowers` 플러그인을 함께 켜 두면 같은 이름의 스킬이 겹친다. 둘 중 하나만 켜는 편이 낫다.

### `dev-harness`

개발 세션 보조 스킬 **5종**.

```
/plugin install dev-harness@seong-skills
```

| 스킬 | 용도 |
| --- | --- |
| `ai-readiness-cartography` | 저장소를 AI-Ready 루브릭으로 감사해 점수·HTML 리포트 생성 |
| `code-review` | PR 코드 리뷰 |
| `grilling` | 계획·결정을 한 번에 한 질문씩 캐물어 스트레스 테스트 |
| `grill-me` | `grilling`을 부르는 별칭 |
| `improve-token-efficiency` | 세션 JSONL을 파싱해 토큰·컨텍스트 효율 리포트 생성 |

`ai-readiness-cartography`·`improve-token-efficiency`는 `python3`가 필요하다.
