# raw frontmatter 규약

웹 클리퍼·수동 메모 모두 같은 형식으로 들어오게 한다. 초기에는 `title`, `source`, `type`, `status`, `project`, `tech`만 일관되면 충분하다.

```yaml
---
title: ""
source: ""
author: ""
published:
clipped: YYYY-MM-DD
type: dev          # dev | docs | article | error | snippet | project | asset | review | reddit | survey | youtube | other
status: unprocessed # unprocessed | processing | done (사용자만 변경)
project:           # 관련 프로젝트 이름 (없으면 비움)
market:            # 관련 시장 이름 (시장조사 원본만, 예: 운동·여행·직장인)
tech: []           # 예: [flutter, dart, claude-code]
tags: [raw/dev]
---
```

## 필드 설명

- `title`: 원본 제목
- `source`: 원본 URL 또는 출처
- `type`: 수집 타입. 폴더와 맞춘다(`raw/dev`→dev, `raw/docs`→docs, `raw/errors`→error 등)
- `status`: 처리 상태. AI는 읽기만 하고 사용자가 명시하지 않으면 바꾸지 않는다.
- `project`: 프로젝트 맥락 연결용
- `market`: 시장조사 원본(`raw/market-research/`)의 시장 맥락(예: 운동·여행·직장인). `project`와 대칭
- `tech`: 기술 스택 태그(검색·필터용)

## 수집 타입과 raw 위치

| 유형 | raw 위치 | 예시 |
| --- | --- | --- |
| 기술 문서 | `raw/dev/` | Flutter/Dart/Claude Code 문서, 코드 메모 |
| 공식 문서 | `raw/docs/` | 공식 레퍼런스 |
| 블로그/아티클 | `raw/articles/` | 개발 사례, 아키텍처 글 |
| 프로젝트 원본 | `raw/projects/<project>/` | 기능 정의서, 회의 메모, PRD 초안 |
| 에러/디버깅 | `raw/errors/` | 에러 메시지, 로그, 해결 전 기록 |
| 코드 조각 | `raw/snippets/` | 재사용 가능한 코드 패턴 |
| 첨부 | `raw/assets/` | 스크린샷, PDF, 다이어그램 |
| 시장조사 | `raw/market-research/{reviews,reddit,articles,youtube,surveys,inbox}/` | 앱 리뷰, Reddit, 블로그/기사, 유튜브 메모, 설문 (시장은 `market:` 태그) |
