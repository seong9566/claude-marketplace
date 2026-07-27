# 시장조사 원본 캡처 양식 (raw/market-research/)

> 시장조사에서 모은 원본(앱 리뷰·Reddit·설문·유튜브·기사)을 `raw/market-research/`에 저장할 때 쓰는 양식. **raw는 source of truth — 가공하지 말고 원문에 가깝게** 넣는다. 정리·구조화는 "ingest 해줘"라고 하면 내가 `wiki/product/`에 한다.

## 저장 위치 (소스 타입별 폴더)

| 타입 | 폴더 | `type:` |
| --- | --- | --- |
| 앱스토어/구글플레이 리뷰 | `raw/market-research/reviews/` | `review` |
| Reddit 글·댓글 | `raw/market-research/reddit/` | `reddit` |
| 설문 결과 | `raw/market-research/surveys/` | `survey` |
| 유튜브 메모 | `raw/market-research/youtube/` | `youtube` |
| 블로그·기사 | `raw/market-research/articles/` | `article` |
| 분류 애매 | `raw/market-research/inbox/` | (아무거나) |

파일명: `<출처>-<YYYY-MM>.md` (예: `runday-리뷰-2026-07.md`).

## Frontmatter (복사해서 채우기)

```yaml
---
title: ""              # 원본이 뭔지 한 줄 (예: 런데이 앱스토어 리뷰 30건)
source: ""             # URL 또는 출처
type: review           # review | reddit | survey | youtube | article
market:                # 어느 시장? (예: 운동 · 여행 · 직장인)
clipped: YYYY-MM-DD     # 수집한 날
status: unprocessed    # unprocessed → (내가 ingest하면) done
tags: [raw/market-research]
---
```

## 본문 (원문에 가깝게)

가공하지 말고 붙여넣는다. 타입별 최소 형태:

- **리뷰**: `별점 · 날짜 · 리뷰 원문`을 한 줄씩. 좋은/나쁜 섞어서.
- **Reddit**: `URL · 제목 · 핵심 문장 인용 · 업보트/댓글수`.
- **설문**: `문항`과 `응답 분포/자유응답`.
- **유튜브**: `영상 링크 · 타임스탬프 · 받아적은 요지`.
- **기사**: `링크 · 핵심 주장 인용`.

원문 그대로가 원칙. 당신의 해석·아이디어는 여기 말고 `wiki/product/`(내가 정리)나 [[product/decision-log]]에.

## 넣은 다음

"방금 넣은 시장조사 ingest 해줘"라고 하면 내가 불만→`pain-points`, 시장→`markets`, 경쟁→`competitors`, 가설거리→`hypotheses`로 컴파일하고 출처를 링크한다.

## 연결
- [[meta/frontmatter-convention]] · [[product/index]]
