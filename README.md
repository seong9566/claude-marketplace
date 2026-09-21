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
| `vault-bootstrap` | 빈 폴더에서 새 vault를 세울 때, 또는 기존 vault에 운영 규약이 없을 때 | 폴더 28개 + `AGENTS.md`·`CLAUDE.md`·`wiki/index.md`·`log.md` + `wiki/meta/` 템플릿 11종 |
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

### `dev-harness`

개발 세션 보조 스킬 **5종**.

```
/plugin install dev-harness@seong-skills
```

| 스킬 | 용도 |
| --- | --- |
| `code-review` | PR 코드 리뷰 |
| `grilling` | 계획·결정을 한 번에 한 질문씩 캐물어 스트레스 테스트 |


> ⚠️ **두 이름 모두 개인 스킬로 흔히 쓰는 이름이다.** `~/.claude/skills/`에 같은 이름이 있어도 서로 덮어쓰지는 않지만(`dev-harness:code-review` vs `code-review`), 어느 쪽을 부르는지 헷갈리기 쉽다. 상세: [`dev-harness/README.md` §이름 충돌](dev-harness/README.md#이름-충돌).

## 이 repo를 고칠 때

**플러그인 파일을 고치면 같은 커밋에서 그 플러그인의 `.claude-plugin/plugin.json` `version`을 올린다.**

Claude Code는 이 clone이 아니라 `plugins/cache/<플러그인>/<버전>/` 스냅샷을 읽고, 그 스냅샷은 `version`이 바뀔 때만 새로 만들어진다. 안 올리면 갱신이 조용히 건너뛰어진다 — `claude plugin update`가 `already at the latest version`이라고 답해서 실패가 성공처럼 보인다. 이 함정에 두 번 걸렸다(`2fc1600` dev-harness · `e4d07ab` obsidian-pm).

`hooks/pre-push`가 이를 막는다. 클론한 뒤 한 번 걸어준다:

```
ln -s ../../hooks/pre-push .git/hooks/pre-push
```
