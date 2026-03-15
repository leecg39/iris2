# Database Design: IRIS 자동 매칭 앱

> Notion DB를 사용합니다. 각 테이블은 Notion 데이터베이스로 구현됩니다.

## 1. 데이터베이스 구조

### DB-1: 기업 프로필 (CompanyProfile)

| 필드 | 타입 | 설명 |
|------|------|------|
| id | Title | 고유 ID |
| business_number | Rich Text | 사업자번호 (10자리) |
| company_name | Rich Text | 회사명 |
| industry | Select | 업종 |
| revenue | Number | 매출액 (원) |
| employee_count | Number | 직원 수 |
| research_fields | Multi-select | 연구분야 |
| tech_keywords | Multi-select | 기술 키워드 |
| address | Rich Text | 소재지 |
| ceo_name | Rich Text | 대표자명 |
| created_at | Date | 등록일 |
| updated_at | Date | 수정일 |

### DB-2: 공고 캐시 (AnnouncementCache)

| 필드 | 타입 | 설명 |
|------|------|------|
| id | Title | 고유 ID |
| iris_id | Rich Text | IRIS 공고 고유번호 |
| title | Rich Text | 공고명 |
| organization | Rich Text | 공고기관 |
| field | Select | 분야 |
| deadline | Date | 마감일 |
| budget | Rich Text | 지원규모 |
| status | Select | 상태 (진행중/마감) |
| detail_url | URL | 상세 페이지 URL |
| ai_summary | Rich Text | AI 요약 결과 |
| scraped_at | Date | 스크래핑 일시 |

### DB-3: 매칭 결과 (MatchResult)

| 필드 | 타입 | 설명 |
|------|------|------|
| id | Title | 고유 ID |
| company_id | Relation → CompanyProfile | 기업 참조 |
| announcement_id | Relation → AnnouncementCache | 공고 참조 |
| match_score | Number | 적합도 점수 (0~100) |
| match_reason | Rich Text | 매칭 근거 (LLM 분석) |
| report_url | URL | 생성된 보고서 PDF URL |
| analyzed_at | Date | 분석 일시 |

### DB-4: 전문가 상담 신청 (ConsultRequest)

| 필드 | 타입 | 설명 |
|------|------|------|
| id | Title | 고유 ID |
| company_id | Relation → CompanyProfile | 기업 참조 |
| announcement_id | Relation → AnnouncementCache | 관련 공고 |
| requester_name | Rich Text | 신청자명 |
| email | Email | 이메일 |
| phone | Phone | 연락처 |
| message | Rich Text | 문의 내용 |
| status | Select | 상태 (접수/진행중/완료) |
| created_at | Date | 신청일 |

## 2. 관계도

```
CompanyProfile (1) ──→ (N) MatchResult
AnnouncementCache (1) ──→ (N) MatchResult
CompanyProfile (1) ──→ (N) ConsultRequest
AnnouncementCache (1) ──→ (N) ConsultRequest
```

## 3. 데이터 흐름

```
1. 사업자번호 입력 → 공공API → CompanyProfile 저장
2. IRIS 스크래핑 → AnnouncementCache 저장/갱신
3. LLM 분석 → MatchResult 생성
4. 전문가 상담 제출 → ConsultRequest 생성 + 이메일 발송
```
