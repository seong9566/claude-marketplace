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

| 스킬 | 언제 |
| --- | --- |
| `project-board-scaffold` | `wiki/projects/<P>/`에 PRD·설계는 있는데 task 추적이 없을 때. 보드(`tasks.base`) + task 노트를 올리고 이미 진행한 작업을 소급 기록한다 |

**vault 경로는 `TASK_VAULT` 환경변수로 준다.** 동봉한 `task.sh`는 `TASK_VAULT/wiki/projects/`가 없으면 아무것도 하지 않고 종료한다.

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
