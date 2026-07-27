---
name: vault-bootstrap
description: Use when starting a new Obsidian PM/개발 세컨드 브레인 vault from an empty folder, or when an existing vault is missing its 운영 규약 — "새 vault 만들어줘", "옵시디언 PM vault 세팅", "vault 부트스트랩", "AGENTS.md 없는데 만들어줘", 새 맥에 vault를 다시 세울 때.
---

# PM vault 부트스트랩

빈 폴더에 **3 레이어 구조(`raw/`·`wiki/`·`Output/`) + 운영 규약**을 찍어 LLM이 곧바로 운영할 수 있는 vault를 만든다.

**규약 없는 빈 폴더는 vault가 아니다.** 이 스킬의 값어치는 폴더가 아니라 `AGENTS.md`(운영 스키마)·`CLAUDE.md`(에이전트 지침)·`wiki/meta/` 템플릿에 있다.

## 실행

```bash
bash "<이 스킬 디렉터리>/bootstrap.sh" <vault 루트 경로>
```

- **기존 파일은 절대 덮어쓰지 않는다.** 있으면 건너뛰고 보고하므로 여러 번 돌려도 안전하고, **이미 쓰던 vault에 빠진 규약만 채울 때도** 그대로 쓴다.
- 만드는 것: 폴더 26개 · `AGENTS.md` · `CLAUDE.md` · `wiki/index.md` · `wiki/log.md` · `wiki/meta/` 템플릿 11종.

## 만든 뒤 반드시 할 것

1. **`AGENTS.md`를 그 사람 것으로 고친다** — 동봉본은 일반형이다. §목적과 범위의 "넣는다/넣지 않는다"를 실제 스택·관심사로 바꾸지 않으면 판단 기준이 없는 것과 같다.
2. **스킬은 복제되지 않는다** — 이 vault를 운영할 스킬은 마켓플레이스에서 설치한다(`obsidian-pm` 플러그인). 사본을 vault에 또 심으면 정본이 갈린다.
3. Obsidian에서 그 폴더를 vault로 연다(`.obsidian/`이 생긴다). 보드(`.base`)는 **네이티브 Bases**라 커뮤니티 플러그인이 필요 없다.

## 하지 않는 것

- 첫 프로젝트를 만들지 않는다 → `project-scaffold`
- 태스크 보드를 만들지 않는다 → `project-board-scaffold`
- `.git` 초기화·원격 연결을 하지 않는다(사용자 판단)

## 흔한 실수

| 실수 | 결과 | 대신 |
| --- | --- | --- |
| 폴더만 만들고 규약을 안 넣음 | LLM이 어디에 뭘 쓸지 몰라 매 세션 다르게 판단한다 | `AGENTS.md`까지가 최소 단위 |
| 동봉 `AGENTS.md`를 그대로 둠 | "넣는다/넣지 않는다"가 남의 기준이라 수집이 산으로 간다 | 1번을 먼저 |
| 기존 vault에 덮어쓰기 시도 | — | 스크립트가 이미 막는다(건너뛰고 보고) |
| 빈 폴더에 더미 문서를 채움 | lint에서 stub·orphan으로 잡힌다 | 폴더만 두고 내용은 생길 때 |
