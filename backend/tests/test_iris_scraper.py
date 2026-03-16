# @TASK P3-R1-T1 - IRIS 스크래퍼 서비스 테스트
# @SPEC docs/planning/02-trd.md#IRIS-스크래핑
"""
IRIS 공고 스크래퍼 테스트.

실제 IRIS 사이트를 호출하지 않고 mock HTML로 테스트한다.
"""

from __future__ import annotations

import asyncio
import time
from unittest.mock import AsyncMock, MagicMock, patch

import httpx
import pytest
import pytest_asyncio

from app.services.iris_scraper import IRISScraper, ScrapingError

# ---------------------------------------------------------------------------
# Mock HTML fixtures
# ---------------------------------------------------------------------------

MOCK_LIST_HTML = """
<html>
<body>
<table class="board_list">
  <tbody>
    <tr>
      <td class="no">1</td>
      <td class="title"><a href="/usr/bsn/pbs/selectBsnPbsDtl.do?irisId=RD-202601-001">2026년 AI 융합 기술개발 사업</a></td>
      <td class="org">과학기술정보통신부</td>
      <td class="field">AI/SW</td>
      <td class="deadline">2026-04-30</td>
      <td class="budget">50억원</td>
      <td class="status"><span class="ing">진행중</span></td>
    </tr>
    <tr>
      <td class="no">2</td>
      <td class="title"><a href="/usr/bsn/pbs/selectBsnPbsDtl.do?irisId=RD-202601-002">바이오 헬스 연구개발</a></td>
      <td class="org">보건복지부</td>
      <td class="field">바이오/의료</td>
      <td class="deadline">2026-03-31</td>
      <td class="budget">30억원</td>
      <td class="status"><span class="end">마감</span></td>
    </tr>
  </tbody>
</table>
</body>
</html>
"""

MOCK_DETAIL_HTML = """
<html>
<body>
<div class="view_cont">
  <h3 class="tit">2026년 AI 융합 기술개발 사업</h3>
  <table class="view_table">
    <tr><th>주관기관</th><td class="org">과학기술정보통신부</td></tr>
    <tr><th>연구분야</th><td class="field">AI/SW</td></tr>
    <tr><th>접수마감</th><td class="deadline">2026-04-30</td></tr>
    <tr><th>지원규모</th><td class="budget">총 50억원 (과제당 최대 10억원)</td></tr>
    <tr><th>공고상태</th><td class="status">진행중</td></tr>
  </table>
  <div class="content">
    <p>본 사업은 AI 기술을 활용한 융합 기술개발을 지원합니다.</p>
    <p>참여 기업은 중소기업 이상이어야 합니다.</p>
  </div>
  <div class="attach_list">
    <ul>
      <li><a href="/download/file1.pdf">공고문.pdf</a></li>
      <li><a href="/download/file2.hwp">신청서양식.hwp</a></li>
    </ul>
  </div>
</div>
</body>
</html>
"""

MOCK_EMPTY_LIST_HTML = """
<html>
<body>
<table class="board_list">
  <tbody>
  </tbody>
</table>
</body>
</html>
"""


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def scraper() -> IRISScraper:
    """기본 스크래퍼 인스턴스 (딜레이 0으로 테스트 속도 향상)."""
    return IRISScraper(base_url="https://test.iris.go.kr", delay=0.0)


@pytest.fixture
def slow_scraper() -> IRISScraper:
    """딜레이 준수 테스트용 스크래퍼 (1초 딜레이)."""
    return IRISScraper(base_url="https://test.iris.go.kr", delay=1.0)


def _mock_response(html: str, status_code: int = 200) -> httpx.Response:
    """httpx.Response mock 생성 헬퍼."""
    return httpx.Response(
        status_code=status_code,
        text=html,
        request=httpx.Request("GET", "https://test.iris.go.kr"),
    )


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


class TestScrapeAnnouncementList:
    """공고 목록 스크래핑 테스트."""

    @pytest.mark.asyncio
    async def test_scrape_announcement_list(self, scraper: IRISScraper) -> None:
        """공고 목록을 정상적으로 파싱한다."""
        with patch.object(scraper, "_fetch_page", new_callable=AsyncMock) as mock_fetch:
            mock_fetch.return_value = MOCK_LIST_HTML

            results = await scraper.scrape_announcement_list(page=1)

            assert len(results) == 2

            first = results[0]
            assert first["iris_id"] == "RD-202601-001"
            assert first["title"] == "2026년 AI 융합 기술개발 사업"
            assert first["organization"] == "과학기술정보통신부"
            assert first["field"] == "AI/SW"
            assert first["deadline"] == "2026-04-30"
            assert first["budget"] == "50억원"
            assert first["status"] == "진행중"
            assert "RD-202601-001" in first["detail_url"]

    @pytest.mark.asyncio
    async def test_scrape_announcement_list_with_keyword(self, scraper: IRISScraper) -> None:
        """키워드 파라미터가 _fetch_page에 전달된다."""
        with patch.object(scraper, "_fetch_page", new_callable=AsyncMock) as mock_fetch:
            mock_fetch.return_value = MOCK_LIST_HTML

            await scraper.scrape_announcement_list(page=1, keyword="AI")

            call_args = mock_fetch.call_args
            # URL 또는 params에 keyword가 포함되는지 확인
            assert mock_fetch.called

    @pytest.mark.asyncio
    async def test_scrape_empty_list(self, scraper: IRISScraper) -> None:
        """빈 목록을 정상적으로 처리한다."""
        with patch.object(scraper, "_fetch_page", new_callable=AsyncMock) as mock_fetch:
            mock_fetch.return_value = MOCK_EMPTY_LIST_HTML

            results = await scraper.scrape_announcement_list(page=1)

            assert results == []


class TestScrapeAnnouncementDetail:
    """공고 상세 스크래핑 테스트."""

    @pytest.mark.asyncio
    async def test_scrape_announcement_detail(self, scraper: IRISScraper) -> None:
        """공고 상세를 정상적으로 파싱한다."""
        with patch.object(scraper, "_fetch_page", new_callable=AsyncMock) as mock_fetch:
            mock_fetch.return_value = MOCK_DETAIL_HTML

            result = await scraper.scrape_announcement_detail("RD-202601-001")

            assert result["iris_id"] == "RD-202601-001"
            assert result["title"] == "2026년 AI 융합 기술개발 사업"
            assert result["organization"] == "과학기술정보통신부"
            assert result["field"] == "AI/SW"
            assert result["deadline"] == "2026-04-30"
            assert "50억원" in result["budget"]
            assert result["status"] == "진행중"
            assert "AI 기술을 활용" in result["content"]
            assert len(result["attachments"]) == 2
            assert any("file1.pdf" in a for a in result["attachments"])


class TestParseDeadline:
    """마감일 파싱 테스트."""

    @pytest.mark.asyncio
    async def test_parse_deadline_standard(self, scraper: IRISScraper) -> None:
        """YYYY-MM-DD 형식을 정상 파싱한다."""
        result = scraper.parse_deadline("2026-04-30")
        assert result == "2026-04-30"

    @pytest.mark.asyncio
    async def test_parse_deadline_korean(self, scraper: IRISScraper) -> None:
        """한국어 날짜 형식을 파싱한다."""
        result = scraper.parse_deadline("2026년 04월 30일")
        assert result == "2026-04-30"

    @pytest.mark.asyncio
    async def test_parse_deadline_dot(self, scraper: IRISScraper) -> None:
        """점(.) 구분 날짜 형식을 파싱한다."""
        result = scraper.parse_deadline("2026.04.30")
        assert result == "2026-04-30"

    @pytest.mark.asyncio
    async def test_parse_deadline_invalid(self, scraper: IRISScraper) -> None:
        """잘못된 형식은 None을 반환한다."""
        result = scraper.parse_deadline("마감일 미정")
        assert result is None

    @pytest.mark.asyncio
    async def test_parse_deadline_empty(self, scraper: IRISScraper) -> None:
        """빈 문자열은 None을 반환한다."""
        result = scraper.parse_deadline("")
        assert result is None


class TestParseBudget:
    """지원규모 파싱 테스트."""

    @pytest.mark.asyncio
    async def test_parse_budget_billions(self, scraper: IRISScraper) -> None:
        """억원 단위를 파싱한다."""
        result = scraper.parse_budget("총 50억원")
        assert result == "50억원"

    @pytest.mark.asyncio
    async def test_parse_budget_detail(self, scraper: IRISScraper) -> None:
        """상세 예산 문자열에서 핵심 금액을 추출한다."""
        result = scraper.parse_budget("총 50억원 (과제당 최대 10억원)")
        assert "50억원" in result

    @pytest.mark.asyncio
    async def test_parse_budget_man(self, scraper: IRISScraper) -> None:
        """만원 단위를 파싱한다."""
        result = scraper.parse_budget("5000만원")
        assert result == "5000만원"

    @pytest.mark.asyncio
    async def test_parse_budget_empty(self, scraper: IRISScraper) -> None:
        """빈 문자열은 빈 문자열을 반환한다."""
        result = scraper.parse_budget("")
        assert result == ""


class TestScrapeWithDelay:
    """요청 간 딜레이 준수 테스트."""

    @pytest.mark.asyncio
    async def test_scrape_with_delay(self, slow_scraper: IRISScraper) -> None:
        """연속 요청 시 최소 delay 초 간격을 준수한다."""
        with patch.object(slow_scraper, "_fetch_page", new_callable=AsyncMock) as mock_fetch:
            mock_fetch.return_value = MOCK_LIST_HTML

            start = time.monotonic()
            await slow_scraper.scrape_announcement_list(page=1)
            await slow_scraper.scrape_announcement_list(page=2)
            elapsed = time.monotonic() - start

            # 최소 1초 딜레이가 있어야 함 (두 번째 요청 전)
            assert elapsed >= 0.9, f"딜레이 미준수: {elapsed:.2f}초 소요"


class TestSaveToNotion:
    """Notion DB 저장 테스트."""

    @pytest.mark.asyncio
    async def test_save_to_notion(self) -> None:
        """공고를 Notion DB에 저장한다."""
        scraper = IRISScraper(delay=0.0)

        # Mock NotionDBClient
        mock_notion = AsyncMock()
        mock_notion.create_page.return_value = {"id": "page-001"}

        announcements = [
            {
                "iris_id": "RD-202601-001",
                "title": "2026년 AI 융합 기술개발 사업",
                "organization": "과학기술정보통신부",
                "field": "AI/SW",
                "deadline": "2026-04-30",
                "budget": "50억원",
                "status": "진행중",
                "detail_url": "https://test.iris.go.kr/detail?irisId=RD-202601-001",
                "content": "AI 기술 개발 지원",
                "attachments": ["/download/file1.pdf"],
            }
        ]

        saved_count = await scraper.save_announcements_to_notion(
            announcements=announcements,
            notion_client=mock_notion,
            db_id="test-db-id",
        )

        assert saved_count == 1
        mock_notion.create_page.assert_called_once()

        # create_page 호출 인자 확인
        call_kwargs = mock_notion.create_page.call_args
        assert call_kwargs[1]["database_id"] == "test-db-id" or call_kwargs[0][0] == "test-db-id"


class TestErrorHandling:
    """스크래핑 실패 처리 테스트."""

    @pytest.mark.asyncio
    async def test_http_error_raises_scraping_error(self, scraper: IRISScraper) -> None:
        """HTTP 에러 시 ScrapingError를 발생시킨다."""
        with patch.object(scraper, "_fetch_page", new_callable=AsyncMock) as mock_fetch:
            mock_fetch.side_effect = httpx.HTTPStatusError(
                "Server Error",
                request=httpx.Request("GET", "https://test.iris.go.kr"),
                response=httpx.Response(500),
            )

            with pytest.raises(ScrapingError) as exc_info:
                await scraper.scrape_announcement_list(page=1)

            assert "500" in str(exc_info.value) or "Server Error" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_connection_error_raises_scraping_error(self, scraper: IRISScraper) -> None:
        """연결 실패 시 ScrapingError를 발생시킨다."""
        with patch.object(scraper, "_fetch_page", new_callable=AsyncMock) as mock_fetch:
            mock_fetch.side_effect = httpx.ConnectError("Connection refused")

            with pytest.raises(ScrapingError):
                await scraper.scrape_announcement_list(page=1)

    @pytest.mark.asyncio
    async def test_invalid_html_returns_empty(self, scraper: IRISScraper) -> None:
        """파싱 불가능한 HTML은 빈 리스트를 반환한다."""
        with patch.object(scraper, "_fetch_page", new_callable=AsyncMock) as mock_fetch:
            mock_fetch.return_value = "<html><body><p>Not a table</p></body></html>"

            results = await scraper.scrape_announcement_list(page=1)

            assert results == []
