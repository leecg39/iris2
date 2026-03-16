# @TASK P3-R2-T3 - 매칭 분석 API 엔드포인트 테스트
# @SPEC docs/planning/02-trd.md#매칭-분석-API
# @TEST tests/test_matching.py

import pytest
from unittest.mock import AsyncMock, patch

from httpx import AsyncClient, ASGITransport

from main import app


# ---------------------------------------------------------------------------
# Mock data helpers
# ---------------------------------------------------------------------------

MOCK_COMPANY_PAGE = {
    "id": "company-page-1",
    "properties": {
        "기업명": {"type": "title", "title": [{"text": {"content": "테스트 주식회사"}}]},
        "사업자번호": {"type": "rich_text", "rich_text": [{"text": {"content": "1234567890"}}]},
        "업종": {"type": "select", "select": {"name": "소프트웨어 개발"}},
        "연구분야": {"type": "multi_select", "multi_select": [{"name": "AI"}, {"name": "빅데이터"}]},
        "기술키워드": {"type": "multi_select", "multi_select": [{"name": "딥러닝"}, {"name": "NLP"}]},
        "매출액": {"type": "number", "number": 5_000_000_000},
        "종업원수": {"type": "number", "number": 50},
    },
}

MOCK_SCRAPED_ANNOUNCEMENTS = [
    {
        "iris_id": "IRIS-001",
        "title": "AI 기술개발 지원사업",
        "organization": "과학기술정보통신부",
        "field": "ICT",
        "deadline": "2026-06-30",
        "budget": "10억원",
        "status": "진행중",
        "detail_url": "https://www.iris.go.kr/detail?irisId=IRIS-001",
        "content": "AI 기술 개발을 위한 정부지원사업입니다.",
    },
]

MOCK_LLM_RESULT = {
    "match_score": 85,
    "match_reason": "기업의 AI/딥러닝 기술역량이 공고의 AI 기술개발 요구사항과 높은 일치도를 보임",
}

MOCK_CREATED_MATCH_PAGE = {
    "id": "match-page-1",
    "properties": {},
}


from typing import Optional


def _make_match_page(
    page_id: str,
    score: int,
    reason: str,
    ann_title: str,
    ann_org: str,
    ann_deadline: Optional[str] = "2026-06-30",
) -> dict:
    """매칭 결과 Notion 페이지 mock."""
    props = {
        "매칭점수": {"type": "number", "number": score},
        "매칭사유": {"type": "rich_text", "rich_text": [{"text": {"content": reason}}]},
        "공고제목": {"type": "rich_text", "rich_text": [{"text": {"content": ann_title}}]},
        "주관기관": {"type": "rich_text", "rich_text": [{"text": {"content": ann_org}}]},
    }
    if ann_deadline:
        props["공고마감일"] = {"type": "date", "date": {"start": ann_deadline}}
    else:
        props["공고마감일"] = {"type": "date", "date": None}
    return {"id": page_id, "properties": props}


MOCK_MATCH_PAGES = [
    _make_match_page("match-1", 85, "AI 분야 높은 일치도", "AI 기술개발 지원사업", "과학기술정보통신부"),
    _make_match_page("match-2", 62, "바이오 분야 관련성 있음", "바이오 연구개발 사업", "산업통상자원부", "2026-05-15"),
]


# ---------------------------------------------------------------------------
# 1. 매칭 분석: POST /api/v1/matching/analyze
# ---------------------------------------------------------------------------


class TestAnalyzeMatching:
    """매칭 분석 요청 테스트."""

    @pytest.mark.asyncio
    async def test_analyze_matching(self):
        """사업자번호로 매칭 분석을 수행하고 결과를 반환한다."""
        with (
            patch("app.routers.match.NotionDBClient") as mock_notion_cls,
            patch("app.routers.match.IRISScraper") as mock_scraper_cls,
            patch("app.routers.match.LLMAnalyzer") as mock_llm_cls,
        ):
            # NotionDBClient mock
            mock_notion = AsyncMock()
            # 1) 기업 조회
            mock_notion.query_database = AsyncMock(
                side_effect=[
                    [MOCK_COMPANY_PAGE],  # 기업 조회
                ]
            )
            # 2) 매칭 결과 저장
            mock_notion.create_page = AsyncMock(return_value=MOCK_CREATED_MATCH_PAGE)
            mock_notion_cls.return_value = mock_notion

            # IRISScraper mock
            mock_scraper = AsyncMock()
            mock_scraper.scrape_announcement_list = AsyncMock(return_value=MOCK_SCRAPED_ANNOUNCEMENTS)
            mock_scraper_cls.return_value = mock_scraper

            # LLMAnalyzer mock
            mock_llm = AsyncMock()
            mock_llm.analyze_match = AsyncMock(return_value=MOCK_LLM_RESULT)
            mock_llm_cls.return_value = mock_llm

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.post(
                    "/api/v1/matching/analyze",
                    json={"business_number": "1234567890"},
                )

            assert resp.status_code == 200
            data = resp.json()
            assert "results" in data
            assert len(data["results"]) >= 1
            result = data["results"][0]
            assert result["match_score"] == 85
            assert "match_reason" in result

    @pytest.mark.asyncio
    async def test_analyze_no_company(self):
        """기업 프로필이 없으면 400 에러를 반환한다."""
        with patch("app.routers.match.NotionDBClient") as mock_notion_cls:
            mock_notion = AsyncMock()
            mock_notion.query_database = AsyncMock(return_value=[])  # 기업 없음
            mock_notion_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.post(
                    "/api/v1/matching/analyze",
                    json={"business_number": "9999999999"},
                )

            assert resp.status_code == 400
            assert "기업" in resp.json()["detail"]


# ---------------------------------------------------------------------------
# 2. 매칭 결과 목록: GET /api/v1/matching/results
# ---------------------------------------------------------------------------


class TestGetMatchingResults:
    """매칭 결과 목록 조회 테스트."""

    @pytest.mark.asyncio
    async def test_get_matching_results(self):
        """매칭 결과 목록을 조회한다."""
        with patch("app.routers.match.NotionDBClient") as mock_notion_cls:
            mock_notion = AsyncMock()
            mock_notion.query_database = AsyncMock(return_value=MOCK_MATCH_PAGES)
            mock_notion_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.get("/api/v1/matching/results")

            assert resp.status_code == 200
            data = resp.json()
            assert "items" in data
            assert "total" in data
            assert len(data["items"]) == 2
            assert data["items"][0]["match_score"] == 85


# ---------------------------------------------------------------------------
# 3. 매칭 결과 상세: GET /api/v1/matching/results/{id}
# ---------------------------------------------------------------------------


class TestGetMatchingResultDetail:
    """매칭 결과 상세 조회 테스트."""

    @pytest.mark.asyncio
    async def test_get_matching_result_detail(self):
        """매칭 결과 ID로 상세 정보를 조회한다."""
        with patch("app.routers.match.NotionDBClient") as mock_notion_cls:
            mock_notion = AsyncMock()
            mock_notion.get_page = AsyncMock(return_value=MOCK_MATCH_PAGES[0])
            mock_notion_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.get("/api/v1/matching/results/match-1")

            assert resp.status_code == 200
            data = resp.json()
            assert data["id"] == "match-1"
            assert data["match_score"] == 85
            assert data["announcement_title"] == "AI 기술개발 지원사업"

    @pytest.mark.asyncio
    async def test_matching_result_not_found(self):
        """존재하지 않는 매칭 결과 ID로 조회 시 404 에러."""
        with patch("app.routers.match.NotionDBClient") as mock_notion_cls:
            from app.services.notion_db import NotionAPIError

            mock_notion = AsyncMock()
            mock_notion.get_page = AsyncMock(
                side_effect=NotionAPIError("Page not found", code="object_not_found")
            )
            mock_notion_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.get("/api/v1/matching/results/nonexistent-id")

            assert resp.status_code == 404
