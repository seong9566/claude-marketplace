# 가설 카드 템플릿 (product/hypotheses/)

> `wiki/product/hypotheses/<slug>.md`를 만들 때 쓰는 양식. `pm-product-discovery`(가정 매핑·실험 설계)와 호환. 재사용·비교를 위해 필드를 고정한다. 아래 코드블록을 복사해 채운다.

```markdown
# 가설: <검증 가능한 한 문장>

> 예: 직장인은 운동을 싫어하는 게 아니라 "뭘 할지 정하는 것"을 귀찮아한다.

- 가장 위험한 가정: <틀리면 전체가 무너지는 핵심 가정>
- 검증 방법: <인터뷰 N명 / 랜딩 / 프로토타입 / 데이터>
- 합격 기준: <정량 — 이 수치면 확증>
- 킬 기준: <정량 — 이 수치면 기각>
- 상태: 열림 | 검증중 | 확증 | 반증(킬)
- 근거: [[product/pain-points/<market>]] · [[product/markets/<market>]]
- 결정 연결: [[product/decision-log]] (채택/기각 시 append)
```

## 상태 값

- **열림**: 아직 검증 안 함
- **검증중**: 실험 진행 중
- **확증**: 합격 기준 충족 → 승격 후보
- **반증(킬)**: 킬 기준 충족 → decision-log에 이유 기록

## 연결 문서

- [[product/index]] · [[meta/page-template]]
