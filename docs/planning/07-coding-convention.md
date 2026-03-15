# Coding Convention: IRIS 자동 매칭 앱

## 1. Flutter (Dart)

### 프로젝트 구조
```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routes.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── network/
├── features/
│   ├── onboarding/
│   ├── profile/
│   ├── home/
│   ├── matching/
│   ├── report/
│   ├── consultation/
│   └── settings/
├── models/
├── services/
│   ├── api_service.dart
│   ├── iris_service.dart
│   ├── notion_service.dart
│   └── openai_service.dart
└── widgets/
    ├── match_card.dart
    ├── score_gauge.dart
    └── ...
```

### 네이밍 규칙
- 파일명: `snake_case` (예: `match_card.dart`)
- 클래스: `PascalCase` (예: `MatchCard`)
- 변수/함수: `camelCase` (예: `matchScore`)
- 상수: `camelCase` (예: `maxKeywords`)
- 프라이빗: `_prefix` (예: `_fetchData`)

### 코드 규칙
- 모든 위젯은 `StatelessWidget` 우선 사용
- 상태관리: Riverpod 또는 Provider
- API 호출은 `services/` 폴더에 분리
- Feature별 폴더 구조 유지

## 2. FastAPI (Python)

### 프로젝트 구조
```
backend/
├── main.py
├── requirements.txt
├── .env
├── app/
│   ├── __init__.py
│   ├── config.py
│   ├── routers/
│   │   ├── company.py
│   │   ├── announcement.py
│   │   ├── matching.py
│   │   └── consultation.py
│   ├── services/
│   │   ├── iris_scraper.py
│   │   ├── public_api.py
│   │   ├── llm_analyzer.py
│   │   ├── notion_db.py
│   │   ├── email_sender.py
│   │   └── pdf_generator.py
│   ├── models/
│   │   └── schemas.py
│   └── utils/
```

### 네이밍 규칙
- 파일명: `snake_case`
- 클래스: `PascalCase`
- 함수/변수: `snake_case`
- 상수: `UPPER_SNAKE_CASE`

### API 규칙
- RESTful 엔드포인트
- 버전 프리픽스: `/api/v1/`
- 응답 형식: JSON

```python
# 엔드포인트 예시
POST /api/v1/company/lookup          # 사업자번호 조회
GET  /api/v1/announcements           # 공고 목록
POST /api/v1/matching/analyze        # 매칭 분석 실행
GET  /api/v1/matching/results        # 매칭 결과 조회
POST /api/v1/consultation/submit     # 전문가 상담 신청
GET  /api/v1/reports/{id}/download   # 보고서 다운로드
```

## 3. 공통 규칙

### Git
- 커밋 메시지: `type: description` (feat, fix, refactor, docs, test)
- 브랜치: `feature/기능명`, `fix/버그명`
- 한국어 커밋 허용

### 환경변수
- `.env` 파일로 관리 (git에 포함 금지)
- 필수 키: `OPENAI_API_KEY`, `NOTION_API_TOKEN`, `NOTION_DB_*_ID`, `SMTP_*`

### IRIS 스크래핑 규칙
- robots.txt 허용 경로만 사용
- 요청 간격: 최소 1초 딜레이
- User-Agent 명시
- 에러 시 재시도: 최대 3회
