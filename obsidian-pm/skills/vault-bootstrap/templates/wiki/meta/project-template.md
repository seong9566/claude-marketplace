# 프로젝트 폴더 템플릿

프로젝트 맥락은 `wiki/projects/<project>/`에 둔다. 프로젝트 repo는 코드·테스트·실행 문서, vault는 맥락·결정·학습·장기 재사용 지식을 담당한다.

## 구조 — 승격 시 둘, 나머지는 필요할 때

```text
wiki/projects/<project>/
  index.md          # 프로젝트 홈: 한 줄 정의·현재 상태·코드 repo·문서 링크  ← 승격 시 생성
  prd.md            # 기획, 기능 정의서                                    ← 승격 시 생성
  tasks/            # task 노트 1개 = task 1개 (프론트매터 status가 진실)   ← 보드 스킬이 생성
  tasks.base        # 네이티브 Obsidian Bases 보드(status로 그룹핑)         ← 보드 스킬이 생성
  architecture.md   # 아키텍처·디렉토리·기술 스택                          ← 필요할 때
  adr/              # 개별 ADR (ADR-0001-….md)                            ← 결정이 생겼을 때
  notes/ · research/  # 그 프로젝트 특화 노트·조사                          ← 필요할 때
```

**빈 문서를 미리 만들지 않는다.** 승격 시점엔 `index.md`·`prd.md`만 만들고 나머지는 실제로 쓸 내용이 생겼을 때 만든다 — 빈 문서는 lint에서 stub·orphan으로 잡힌다.

- **승격**(`index`·`prd` 생성)은 `project-scaffold` 스킬이, **보드**(`tasks/`·`tasks.base`)는 `project-board-scaffold` 스킬이 담당한다. 둘 다 `obsidian-pm` 플러그인.
- **결정 기록의 자리**: 그 프로젝트에 국한된 기술 결정은 `adr/`, 제품 방향·스택처럼 프로젝트를 넘는 결정은 [[product/decision-log]].
- PRD 섹션 구성은 프로젝트마다 다르다(앱·단일 산출물·콘텐츠 제품이 각각 다른 항목을 필요로 한다). 공통분모는 **목표 / 대상 / 스코프·기능 / 열린 항목 / 연결 문서** 다섯이고, 나머지는 성격에 맞게 늘린다.

## ADR 양식 (adr/ADR-NNNN-제목.md)

```markdown
# ADR-NNNN: 결정 제목

- 상태: 제안 | 승인 | 폐기 | 대체됨
- 날짜: YYYY-MM-DD

## 맥락 (왜 결정이 필요했나)

## 결정 (무엇을 정했나)

## 근거 (어떤 정보를 기반으로 했나)

## 결과 (영향 / 트레이드오프)
```

> 결정을 메모로 남기는 이유: 그 결정은 당시 알고 있던 정보를 기반으로 했고, 다음 작업에 영향을 미칠 확률이 높다.
