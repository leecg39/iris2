# @TASK P4-R1-T1 - PDF 보고서 생성 서비스 테스트
# @SPEC docs/planning/02-trd.md#보고서-생성

"""
PDFReportGenerator 단위 테스트.

ReportLab 기반 PDF 생성 서비스의 동작을 검증한다.
"""

import pytest
from datetime import datetime


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def sample_company():
    """테스트용 기업 정보."""
    return {
        "company_name": "테스트기업",
        "industry": "정보통신업",
        "research_fields": ["인공지능", "빅데이터"],
        "tech_keywords": ["머신러닝", "자연어처리", "딥러닝"],
        "revenue": 5_000_000_000,
        "employee_count": 50,
    }


@pytest.fixture
def sample_announcement():
    """테스트용 공고 정보."""
    return {
        "title": "2026년 AI 핵심기술 개발사업",
        "organization": "정보통신기획평가원",
        "field": "인공지능",
        "deadline": "2026-04-30",
        "budget": "최대 10억원",
        "detail_url": "https://www.iris.go.kr/detail/12345",
    }


@pytest.fixture
def sample_match_result():
    """테스트용 매칭 결과."""
    return {
        "match_score": 87.5,
        "match_reason": (
            "기업의 AI/빅데이터 연구역량과 공고의 AI 핵심기술 개발 요건이 "
            "높은 수준으로 부합합니다. 특히 자연어처리 기술 보유가 강점입니다."
        ),
        "ai_summary": (
            "본 사업은 AI 핵심기술(자연어처리, 컴퓨터비전 등) 분야의 "
            "원천기술 개발을 목표로 합니다. 중소/중견기업 참여가 가능하며 "
            "최대 10억원까지 지원됩니다."
        ),
    }


@pytest.fixture
def generator():
    """PDFReportGenerator 인스턴스."""
    from app.services.pdf_generator import PDFReportGenerator
    return PDFReportGenerator()


# ---------------------------------------------------------------------------
# Tests: PDF 바이트 생성
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_generate_report_pdf(generator, sample_company, sample_announcement, sample_match_result):
    """generate_report 는 유효한 PDF 바이트를 반환해야 한다."""
    pdf_bytes = await generator.generate_report(
        company=sample_company,
        announcement=sample_announcement,
        match_result=sample_match_result,
    )

    # PDF 바이트가 생성되었는지 확인
    assert isinstance(pdf_bytes, bytes)
    assert len(pdf_bytes) > 0

    # PDF 매직 바이트 확인 (%PDF-)
    assert pdf_bytes[:5] == b"%PDF-"


# ---------------------------------------------------------------------------
# Tests: 보고서 내용 검증
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_report_content(generator, sample_company, sample_announcement, sample_match_result):
    """PDF에 기업정보, 공고정보, 적합도 점수가 포함되어야 한다."""
    pdf_bytes = await generator.generate_report(
        company=sample_company,
        announcement=sample_announcement,
        match_result=sample_match_result,
    )

    # PDF 바이트가 충분한 크기인지 확인 (최소 1KB 이상)
    assert len(pdf_bytes) > 1024

    # PDF가 정상적으로 종료되는지 확인 (%%EOF)
    assert b"%%EOF" in pdf_bytes


# ---------------------------------------------------------------------------
# Tests: 불완전 데이터 처리
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_report_with_missing_data(generator):
    """필수 데이터가 누락되어도 PDF를 생성할 수 있어야 한다."""
    minimal_company = {
        "company_name": "최소기업",
    }
    minimal_announcement = {
        "title": "테스트 공고",
    }
    minimal_match = {
        "match_score": 50.0,
    }

    pdf_bytes = await generator.generate_report(
        company=minimal_company,
        announcement=minimal_announcement,
        match_result=minimal_match,
    )

    assert isinstance(pdf_bytes, bytes)
    assert len(pdf_bytes) > 0
    assert pdf_bytes[:5] == b"%PDF-"


@pytest.mark.asyncio
async def test_report_with_empty_strings(generator):
    """빈 문자열 데이터로도 PDF 생성이 가능해야 한다."""
    company = {"company_name": "", "industry": "", "research_fields": [], "tech_keywords": []}
    announcement = {"title": "", "organization": ""}
    match_result = {"match_score": 0, "match_reason": ""}

    pdf_bytes = await generator.generate_report(
        company=company,
        announcement=announcement,
        match_result=match_result,
    )

    assert isinstance(pdf_bytes, bytes)
    assert pdf_bytes[:5] == b"%PDF-"


# ---------------------------------------------------------------------------
# Tests: 파일명 생성 규칙
# ---------------------------------------------------------------------------


def test_report_filename(generator):
    """파일명은 'IRIS_보고서_{회사명}_{공고명}_{날짜}.pdf' 형식이어야 한다."""
    filename = generator.generate_filename(
        company_name="테스트기업",
        announcement_title="AI핵심기술개발",
    )

    assert filename.startswith("IRIS_")
    assert "테스트기업" in filename
    assert "AI핵심기술개발" in filename
    assert filename.endswith(".pdf")

    # 날짜 형식 확인 (YYYYMMDD)
    today = datetime.now().strftime("%Y%m%d")
    assert today in filename


def test_report_filename_special_chars(generator):
    """파일명에 특수문자가 제거되어야 한다."""
    filename = generator.generate_filename(
        company_name="테스트/기업",
        announcement_title="AI 핵심:기술",
    )

    # 파일시스템 안전하지 않은 문자가 제거됨
    assert "/" not in filename
    assert ":" not in filename
    assert filename.endswith(".pdf")
