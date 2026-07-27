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
