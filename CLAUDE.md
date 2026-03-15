# IRIS 정부지원사업 자동 매칭 앱

## 프로젝트 개요
사업자번호 입력 → 공공API 기업 데이터 연동 → IRIS 공고 스크래핑 → AI 적합도 분석 → 매칭 결과 + 보고서 + 전문가 연결

## 기술 스택
- **Frontend**: Flutter (iOS/Android)
- **Backend**: FastAPI (Python)
- **Database**: Notion DB (via Notion API)
- **AI**: OpenAI GPT API
- **Scraping**: BeautifulSoup4 / httpx
- **PDF**: ReportLab
- **Email**: SMTP / SendGrid

## 프로젝트 구조
```
IRIS2/
├── CLAUDE.md              # 이 파일
├── TASKS.md               # 태스크 목록 (38개)
├── docs/planning/         # 7개 기획 문서
├── specs/                 # 화면 명세 + 도메인 리소스
├── backend/               # FastAPI 서버
├── lib/                   # Flutter 앱
├── test/                  # Flutter 테스트
└── .claude/agents/        # 에이전트 팀
```

## 핵심 규칙
1. IRIS 스크래핑 시 robots.txt 준수, 요청 간 1초 딜레이
2. API 키는 반드시 환경변수로 관리 (.env)
3. 모든 API 엔드포인트는 /api/v1/ 프리픽스
4. TDD: 테스트 먼저 → 구현 → 리팩토링
5. 한국어 커밋 허용

## 외부 서비스
- IRIS: https://www.iris.go.kr/main.do (정부 R&D 공고)
- 공공API: 기업마당 등 (사업자번호 → 기업정보)
- OpenAI: GPT API (적합도 분석, 공고 요약)
- Notion: DB API (데이터 저장)

## 환경변수 (.env)
```
OPENAI_API_KEY=
NOTION_API_TOKEN=
NOTION_DB_COMPANY_ID=
NOTION_DB_ANNOUNCEMENT_ID=
NOTION_DB_MATCH_ID=
NOTION_DB_CONSULT_ID=
NOTION_DB_REPORT_ID=
SMTP_HOST=
SMTP_PORT=
SMTP_USER=
SMTP_PASSWORD=
```
