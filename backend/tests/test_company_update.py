# @TASK P2-R1-T2 - 기업 프로필 수정 API 테스트
# @SPEC docs/planning/02-trd.md#기업-프로필-수정
# @TEST tests/test_company_update.py
"""
PUT /api/v1/company/profile 엔드포인트 테스트.

research_fields, tech_keywords 업데이트 및 Notion DB 저장 검증.
"""

from __future__ import annotations

import pytest
from unittest.mock import AsyncMock, patch
from typing import Optional

from httpx import AsyncClient, ASGITransport

from main import app


# ---------------------------------------------------------------------------
# Fixtures / Constants
# ---------------------------------------------------------------------------

VALID_BN = "1234567890"

# Notion query_database가 반환하는 기존 기업 페이지 mock
MOCK_NOTION_PAGE = {
    "id": "page-abc-123",
    "properties": {
        "기업명": {"type": "title", "title": [{"text": {"content": "테스트 주식회사"}}]},
        "사업자번호": {"type": "rich_text", "rich_text": [{"text": {"content": "1234567890"}}]},
        "대표자명": {"type": "rich_text", "rich_text": [{"text": {"content": "홍길동"}}]},
        "업종": {"type": "select", "select": {"name": "소프트웨어 개발"}},
        "매출액": {"type": "number", "number": 5_000_000_000},
        "종업원수": {"type": "number", "number": 50},
        "주소": {"type": "rich_text", "rich_text": [{"text": {"content": "서울특별시 강남구"}}]},
        "연구분야": {"type": "multi_select", "multi_select": [{"name": "AI"}]},
        "기술키워드": {"type": "multi_select", "multi_select": [{"name": "Python"}]},
    },
}


def _make_notion_mock(pages: list | None = None):
    """NotionDBClient mock을 생성하는 헬퍼."""
    mock_notion = AsyncMock()
    mock_notion.query_database = AsyncMock(
        return_value=pages if pages is not None else [MOCK_NOTION_PAGE]
    )
    mock_notion.update_page = AsyncMock(return_value=MOCK_NOTION_PAGE)
    return mock_notion


# ---------------------------------------------------------------------------
# 1. 전체 업데이트 성공
# ---------------------------------------------------------------------------


class TestUpdateProfileSuccess:
    """research_fields, tech_keywords 전체 업데이트 성공."""

    @pytest.mark.asyncio
    async def test_update_profile_success(self):
        """research_fields + tech_keywords 모두 업데이트하면 200 반환."""
        with patch("app.routers.company.NotionDBClient") as mock_notion_cls:
            mock_notion = _make_notion_mock()
            mock_notion_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.put(
                    "/api/v1/company/profile",
                    json={
                        "business_number": "123-45-67890",
                        "research_fields": ["AI", "로봇공학"],
                        "tech_keywords": ["Python", "TensorFlow"],
                    },
                )

            assert resp.status_code == 200
            data = resp.json()
            assert data["business_number"] == "1234567890"
            assert data["company_name"] == "테스트 주식회사"

            # Notion update_page 호출 확인
            mock_notion.update_page.assert_called_once()
            call_args = mock_notion.update_page.call_args
            props = call_args[1]["properties"] if "properties" in call_args[1] else call_args[0][1]
            assert "연구분야" in props
            assert "기술키워드" in props


# ---------------------------------------------------------------------------
# 2. 부분 업데이트 (tech_keywords만)
# ---------------------------------------------------------------------------


class TestUpdateProfilePartial:
    """tech_keywords만 보낸 경우 research_fields는 변경하지 않는다."""

    @pytest.mark.asyncio
    async def test_update_profile_partial(self):
        """tech_keywords만 전송하면 해당 필드만 업데이트한다."""
        with patch("app.routers.company.NotionDBClient") as mock_notion_cls:
            mock_notion = _make_notion_mock()
            mock_notion_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.put(
                    "/api/v1/company/profile",
                    json={
                        "business_number": "123-45-67890",
                        "tech_keywords": ["Rust", "CUDA"],
                    },
                )

            assert resp.status_code == 200

            # update_page가 호출되었고 기술키워드만 포함
            mock_notion.update_page.assert_called_once()
            call_args = mock_notion.update_page.call_args
            props = call_args[1]["properties"] if "properties" in call_args[1] else call_args[0][1]
            assert "기술키워드" in props
            assert "연구분야" not in props


# ---------------------------------------------------------------------------
# 3. 빈 배열로 필드 초기화
# ---------------------------------------------------------------------------


class TestUpdateProfileEmptyFields:
    """빈 배열로 보내면 해당 필드를 초기화한다."""

    @pytest.mark.asyncio
    async def test_update_profile_empty_fields(self):
        """빈 리스트를 전송하면 multi_select가 빈 배열로 업데이트된다."""
        with patch("app.routers.company.NotionDBClient") as mock_notion_cls:
            mock_notion = _make_notion_mock()
            mock_notion_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.put(
                    "/api/v1/company/profile",
                    json={
                        "business_number": "123-45-67890",
                        "research_fields": [],
                        "tech_keywords": [],
                    },
                )

            assert resp.status_code == 200

            # 빈 multi_select로 업데이트 확인
            mock_notion.update_page.assert_called_once()
            call_args = mock_notion.update_page.call_args
            props = call_args[1]["properties"] if "properties" in call_args[1] else call_args[0][1]
            assert props["연구분야"] == {"multi_select": []}
            assert props["기술키워드"] == {"multi_select": []}


# ---------------------------------------------------------------------------
# 4. Notion DB에 업데이트 저장 확인
# ---------------------------------------------------------------------------


class TestUpdateProfileNotionSave:
    """Notion DB의 update_page가 올바른 page_id와 properties로 호출되는지 확인."""

    @pytest.mark.asyncio
    async def test_update_profile_notion_save(self):
        """update_page가 올바른 page_id로 호출된다."""
        with patch("app.routers.company.NotionDBClient") as mock_notion_cls:
            mock_notion = _make_notion_mock()
            mock_notion_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.put(
                    "/api/v1/company/profile",
                    json={
                        "business_number": "123-45-67890",
                        "research_fields": ["바이오"],
                    },
                )

            assert resp.status_code == 200

            # page_id 확인
            mock_notion.update_page.assert_called_once()
            call_args = mock_notion.update_page.call_args
            page_id = call_args[1]["page_id"] if "page_id" in call_args[1] else call_args[0][0]
            assert page_id == "page-abc-123"


# ---------------------------------------------------------------------------
# 5. 존재하지 않는 프로필 수정 시 404
# ---------------------------------------------------------------------------


class TestUpdateProfileNotFound:
    """Notion DB에 해당 기업이 없으면 404."""

    @pytest.mark.asyncio
    async def test_update_profile_not_found(self):
        """존재하지 않는 사업자번호로 프로필 수정 시 404 반환."""
        with patch("app.routers.company.NotionDBClient") as mock_notion_cls:
            mock_notion = _make_notion_mock(pages=[])  # 빈 결과
            mock_notion_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.put(
                    "/api/v1/company/profile",
                    json={
                        "business_number": "999-99-99999",
                        "research_fields": ["AI"],
                    },
                )

            assert resp.status_code == 404
            assert "찾을 수 없습니다" in resp.json()["detail"]
