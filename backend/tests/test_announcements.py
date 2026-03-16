# @TASK P3-R1-T2 - 공고 API 엔드포인트 테스트
# @SPEC docs/planning/02-trd.md#공고-API
# @TEST tests/test_announcements.py

import pytest
from unittest.mock import AsyncMock, patch

from httpx import AsyncClient, ASGITransport

from main import app


# ---------------------------------------------------------------------------
# Mock Notion page helpers
# ---------------------------------------------------------------------------

from typing import Optional


def _make_notion_page(
    page_id: str,
    iris_id: str,
    title: str,
    organization: str,
    field: str = "ICT",
    deadline: Optional[str] = "2026-06-30",
    budget: str = "10억원",
    status: str = "진행중",
    detail_url: str = "",
) -> dict:
    """Notion DB 페이지 형식의 mock 데이터를 생성한다."""
    props = {
        "IRIS ID": {"type": "rich_text", "rich_text": [{"text": {"content": iris_id}}]},
        "제목": {"type": "title", "title": [{"text": {"content": title}}]},
        "주관기관": {"type": "rich_text", "rich_text": [{"text": {"content": organization}}]},
        "분야": {"type": "rich_text", "rich_text": [{"text": {"content": field}}]},
        "지원규모": {"type": "rich_text", "rich_text": [{"text": {"content": budget}}]},
        "상태": {"type": "select", "select": {"name": status}},
    }
    if deadline:
        props["마감일"] = {"type": "date", "date": {"start": deadline}}
    else:
        props["마감일"] = {"type": "date", "date": None}
    if detail_url:
        props["상세URL"] = {"type": "url", "url": detail_url}
    else:
        props["상세URL"] = {"type": "url", "url": None}
    return {"id": page_id, "properties": props}


MOCK_PAGES = [
    _make_notion_page("page-1", "IRIS-001", "AI 기술개발 지원사업", "과학기술정보통신부", "ICT", "2026-06-30", "10억원", "진행중"),
    _make_notion_page("page-2", "IRIS-002", "바이오 연구개발 사업", "산업통상자원부", "바이오", "2026-05-15", "5억원", "진행중"),
    _make_notion_page("page-3", "IRIS-003", "마감된 사업 공고", "중소벤처기업부", "ICT", "2026-01-01", "3억원", "마감"),
]


# ---------------------------------------------------------------------------
# 1. 공고 목록 조회: GET /api/v1/announcements
# ---------------------------------------------------------------------------


class TestGetAnnouncementsList:
    """공고 목록 조회 테스트."""

    @pytest.mark.asyncio
    async def test_get_announcements_list(self):
        """공고 목록을 페이지네이션과 함께 조회한다."""
        with patch("app.routers.announcement.NotionDBClient") as mock_cls:
            mock_notion = AsyncMock()
            mock_notion.query_database = AsyncMock(return_value=MOCK_PAGES)
            mock_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.get("/api/v1/announcements")

            assert resp.status_code == 200
            data = resp.json()
            assert "items" in data
            assert "total" in data
            assert "page" in data
            assert len(data["items"]) == 3
            assert data["items"][0]["title"] == "AI 기술개발 지원사업"

    @pytest.mark.asyncio
    async def test_get_announcements_filter_status(self):
        """상태 필터(진행중/마감)로 공고를 조회한다."""
        # 진행중만 반환하도록 mock
        ongoing_pages = [p for p in MOCK_PAGES if p["properties"]["상태"]["select"]["name"] == "진행중"]

        with patch("app.routers.announcement.NotionDBClient") as mock_cls:
            mock_notion = AsyncMock()
            mock_notion.query_database = AsyncMock(return_value=ongoing_pages)
            mock_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.get("/api/v1/announcements", params={"status": "진행중"})

            assert resp.status_code == 200
            data = resp.json()
            assert len(data["items"]) == 2
            # Notion query_database에 filter가 전달되었는지 확인
            call_kwargs = mock_notion.query_database.call_args
            notion_filter = call_kwargs.kwargs.get("filter") or call_kwargs[1].get("filter")
            assert notion_filter is not None

    @pytest.mark.asyncio
    async def test_get_announcements_filter_keyword(self):
        """키워드 검색으로 공고를 조회한다."""
        keyword_pages = [MOCK_PAGES[0]]  # "AI" 포함 공고

        with patch("app.routers.announcement.NotionDBClient") as mock_cls:
            mock_notion = AsyncMock()
            mock_notion.query_database = AsyncMock(return_value=keyword_pages)
            mock_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.get("/api/v1/announcements", params={"keyword": "AI"})

            assert resp.status_code == 200
            data = resp.json()
            assert len(data["items"]) == 1
            assert "AI" in data["items"][0]["title"]
            # Notion query에 filter가 전달되었는지 확인
            call_kwargs = mock_notion.query_database.call_args
            notion_filter = call_kwargs.kwargs.get("filter") or call_kwargs[1].get("filter")
            assert notion_filter is not None


# ---------------------------------------------------------------------------
# 2. 공고 상세 조회: GET /api/v1/announcements/{id}
# ---------------------------------------------------------------------------


class TestGetAnnouncementDetail:
    """공고 상세 조회 테스트."""

    @pytest.mark.asyncio
    async def test_get_announcement_detail(self):
        """공고 ID로 상세 정보를 조회한다."""
        with patch("app.routers.announcement.NotionDBClient") as mock_cls:
            mock_notion = AsyncMock()
            mock_notion.get_page = AsyncMock(return_value=MOCK_PAGES[0])
            mock_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.get("/api/v1/announcements/page-1")

            assert resp.status_code == 200
            data = resp.json()
            assert data["iris_id"] == "IRIS-001"
            assert data["title"] == "AI 기술개발 지원사업"
            assert data["organization"] == "과학기술정보통신부"

    @pytest.mark.asyncio
    async def test_announcement_not_found(self):
        """존재하지 않는 공고 ID로 조회 시 404 에러."""
        with patch("app.routers.announcement.NotionDBClient") as mock_cls:
            from app.services.notion_db import NotionAPIError

            mock_notion = AsyncMock()
            mock_notion.get_page = AsyncMock(
                side_effect=NotionAPIError("Page not found", code="object_not_found")
            )
            mock_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.get("/api/v1/announcements/nonexistent-id")

            assert resp.status_code == 404
