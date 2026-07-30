---
name: project-scaffold
description: Use when a validated idea should become a project folder in an Obsidian PM vault — "프로젝트 승격", "새 프로젝트 만들어줘", "wiki/projects에 올려줘", "프로젝트 스캐폴딩", 발굴·검증을 통과한 후보를 wiki/projects/<P>/ 로 올릴 때.
---

# 프로젝트 승격 스캐폴딩

검증을 통과한 후보를 `wiki/projects/<P>/`로 올린다. **만드는 것은 `index.md`와 `prd.md` 둘뿐이다.**

`adr/`·`architecture.md`·`notes/`는 실제로 쓸 내용이 생겼을 때 만든다 — 빈 문서는 lint에서 stub·orphan으로 잡히고, 있어도 아무도 안 읽는다. 구조 정본은 vault의 `wiki/meta/project-template.md`.

## 사전 확인

- **승격할 근거가 있는가.** 발굴 자료(시장·경쟁·페인포인트·가설)나 결정 기록이 있어야 한다. 근거 없이 폴더부터 만들면 빈 껍데기가 남는다.
- vault인가 — `TASK_VAULT/wiki/projects/`가 있어야 한다. 없으면 `vault-bootstrap`이 먼저다.

## 절차

### 1. 네 가지를 묻는다 (그 이상 묻지 않는다)

| 물을 것 | 쓰이는 곳 |
| --- | --- |
| 폴더명(slug) | `wiki/projects/<slug>/` — 한글 가능, 공백 대신 `-`; `/`·`\`·`.`·`..` 사용 불가 |
| 제목 | 문서 제목 |
| **한 줄 정의** | index 인용문. "무엇을 하는 물건인가"를 한 문장으로 |
| 현재 상태 · 코드 repo | index 상태 줄 (repo는 없으면 생략) |

**PRD 본문은 여기서 묻지 않는다.** 목표·대상·스코프를 즉석에서 받아 적으면 확정되지 않은 것이 확정된 것처럼 박힌다.

### 2. 실행

```bash
export TASK_VAULT=<vault 루트>
bash "<이 스킬 디렉터리>/project-new.sh" <slug> \
  --title "<제목>" --summary "<한 줄 정의>" [--status "<상태>"] [--repo <repo>]
```

이미 있는 폴더면 거부한다.

### 3. 연결 (이게 빠지면 승격이 아니다)

- vault 최상위 `wiki/index.md`의 프로젝트 절에 한 줄 추가 — 무엇이고 지금 어느 단계인지
- `wiki/log.md`에 `setup` 엔트리
- 발굴 자료를 index의 §발굴 계보에 **링크**(복사하지 않는다 — 원본은 `wiki/product/`에 남는다)

### 4. 다음 단계를 알린다

1. **PRD 본문**은 결정을 확정한 뒤 쓴다(grilling 등으로 압박 인터뷰 → 결정 → PRD). 골격 5섹션은 공통분모이며 프로젝트 성격에 맞게 늘린다.
2. PRD가 서면 **`project-board-scaffold`**로 태스크 보드를 올린다.

**보드를 지금 만들지 않는다.** PRD가 골격뿐인 시점엔 task를 뽑을 근거가 없어 빈 보드만 남는다.

## 흔한 실수

| 실수 | 결과 | 대신 |
| --- | --- | --- |
| PRD 5섹션을 즉석 인터뷰로 채움 | 확정 안 된 스코프가 확정된 것처럼 박힌다 | 골격만 두고 결정 후 작성 |
| `adr/`·`architecture.md`를 빈 채로 생성 | lint stub·orphan | 생길 때 만든다 |
| 발굴 자료를 프로젝트 폴더로 복사 | `wiki/product/`의 포트폴리오 기억이 끊긴다 | wiki link로 연결 |
| index·log 연결을 건너뜀 | 승격했는데 아무도 못 찾는다 | 3단계는 필수 |
| 승격과 동시에 보드 생성 | 빈 보드 방치 | PRD 확정 후 보드 스킬 |
