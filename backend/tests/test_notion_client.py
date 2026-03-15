# @TASK P1-R1-T1 - Notion DB Client 테스트
# @SPEC docs/planning/02-trd.md#Notion-DB

import pytest
import pytest_asyncio
from unittest.mock import AsyncMock, MagicMock, patch

from app.services.notion_db import (
    NotionDBClient,
    NotionAPIError,
    build_rich_text,
    build_number,
    build_select,
    build_multi_select,
    build_date,
    build_url,
    build_email,
    build_phone,
    build_relation,
    build_title,
    extract_property_value,
)


@pytest.fixture
def mock_notion_async_client():
    """notion-client AsyncClient mock."""
    client = MagicMock()
    client.pages = MagicMock()
    client.pages.create = AsyncMock()
    client.pages.update = AsyncMock()
    client.pages.retrieve = AsyncMock()
    client.databases = MagicMock()
    client.databases.query = AsyncMock()
    return client


@pytest_asyncio.fixture
async def notion_client(mock_notion_async_client):
    """NotionDBClient with mocked internal client."""
    with patch("app.services.notion_db.AsyncClient", return_value=mock_notion_async_client):
        client = NotionDBClient(token="test-token")
        yield client


# -------------------------------------------------------------------
# create_page
# -------------------------------------------------------------------


@pytest.mark.asyncio
async def test_create_page(notion_client, mock_notion_async_client):
    """create_page 가 pages.create 를 올바른 인자로 호출한다."""
    expected_response = {
        "id": "page-id-123",
        "properties": {"Name": {"title": [{"text": {"content": "Test"}}]}},
    }
    mock_notion_async_client.pages.create.return_value = expected_response

    properties = {"Name": build_title("Test")}
    result = await notion_client.create_page("db-id-abc", properties)

    mock_notion_async_client.pages.create.assert_awaited_once_with(
        parent={"database_id": "db-id-abc"},
        properties=properties,
    )
    assert result == expected_response
    assert result["id"] == "page-id-123"


# -------------------------------------------------------------------
# query_database
# -------------------------------------------------------------------


@pytest.mark.asyncio
async def test_query_database(notion_client, mock_notion_async_client):
    """query_database 가 필터와 정렬을 전달한다."""
    mock_notion_async_client.databases.query.return_value = {
        "results": [
            {"id": "page-1", "properties": {}},
            {"id": "page-2", "properties": {}},
        ],
        "has_more": False,
    }

    filter_obj = {"property": "status", "select": {"equals": "open"}}
    sorts = [{"property": "deadline", "direction": "ascending"}]

    result = await notion_client.query_database("db-id-abc", filter=filter_obj, sorts=sorts)

    mock_notion_async_client.databases.query.assert_awaited_once_with(
        database_id="db-id-abc",
        filter=filter_obj,
        sorts=sorts,
        start_cursor=None,
        page_size=100,
    )
    assert len(result) == 2
    assert result[0]["id"] == "page-1"


@pytest.mark.asyncio
async def test_query_database_no_filter(notion_client, mock_notion_async_client):
    """query_database 에 필터/정렬 없이 호출할 수 있다."""
    mock_notion_async_client.databases.query.return_value = {
        "results": [],
        "has_more": False,
    }

    result = await notion_client.query_database("db-id-abc")

    mock_notion_async_client.databases.query.assert_awaited_once_with(
        database_id="db-id-abc",
        filter=None,
        sorts=None,
        start_cursor=None,
        page_size=100,
    )
    assert result == []


@pytest.mark.asyncio
async def test_query_database_pagination(notion_client, mock_notion_async_client):
    """query_database 가 여러 페이지를 자동으로 순회한다."""
    mock_notion_async_client.databases.query.side_effect = [
        {
            "results": [{"id": "page-1"}],
            "has_more": True,
            "next_cursor": "cursor-abc",
        },
        {
            "results": [{"id": "page-2"}],
            "has_more": False,
        },
    ]

    result = await notion_client.query_database("db-id-abc")

    assert len(result) == 2
    assert mock_notion_async_client.databases.query.await_count == 2


# -------------------------------------------------------------------
# update_page
# -------------------------------------------------------------------


@pytest.mark.asyncio
async def test_update_page(notion_client, mock_notion_async_client):
    """update_page 가 pages.update 를 올바른 인자로 호출한다."""
    expected_response = {"id": "page-id-123", "properties": {}}
    mock_notion_async_client.pages.update.return_value = expected_response

    properties = {"status": build_select("closed")}
    result = await notion_client.update_page("page-id-123", properties)

    mock_notion_async_client.pages.update.assert_awaited_once_with(
        page_id="page-id-123",
        properties=properties,
    )
    assert result == expected_response


# -------------------------------------------------------------------
# get_page
# -------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_page(notion_client, mock_notion_async_client):
    """get_page 가 pages.retrieve 를 올바른 인자로 호출한다."""
    expected_response = {
        "id": "page-id-123",
        "properties": {"Name": {"title": [{"text": {"content": "Test"}}]}},
    }
    mock_notion_async_client.pages.retrieve.return_value = expected_response

    result = await notion_client.get_page("page-id-123")

    mock_notion_async_client.pages.retrieve.assert_awaited_once_with(
        page_id="page-id-123",
    )
    assert result == expected_response
    assert result["id"] == "page-id-123"


# -------------------------------------------------------------------
# error handling
# -------------------------------------------------------------------


@pytest.mark.asyncio
async def test_error_handling_api_response_error(notion_client, mock_notion_async_client):
    """Notion API 에러 시 NotionAPIError 를 발생시킨다."""
    from notion_client.errors import APIResponseError
    import httpx

    mock_notion_async_client.pages.retrieve.side_effect = APIResponseError(
        code="object_not_found",
        status=404,
        message="Page not found",
        headers=httpx.Headers({}),
        raw_body_text='{"code":"object_not_found","message":"Page not found"}',
    )

    with pytest.raises(NotionAPIError) as exc_info:
        await notion_client.get_page("nonexistent-page-id")

    assert exc_info.value.code == "object_not_found"
    assert "Page not found" in str(exc_info.value)


@pytest.mark.asyncio
async def test_error_handling_unexpected_error(notion_client, mock_notion_async_client):
    """예상치 못한 에러도 NotionAPIError 로 래핑된다."""
    mock_notion_async_client.pages.retrieve.side_effect = ConnectionError("Network failure")

    with pytest.raises(NotionAPIError) as exc_info:
        await notion_client.get_page("page-id-123")

    assert "Network failure" in str(exc_info.value)


# -------------------------------------------------------------------
# property builder helpers
# -------------------------------------------------------------------


class TestPropertyBuilders:
    """Notion property 변환 헬퍼 함수 테스트."""

    def test_build_title(self):
        result = build_title("Test Title")
        assert result == {"title": [{"text": {"content": "Test Title"}}]}

    def test_build_rich_text(self):
        result = build_rich_text("Hello World")
        assert result == {"rich_text": [{"text": {"content": "Hello World"}}]}

    def test_build_number(self):
        result = build_number(42)
        assert result == {"number": 42}

    def test_build_number_float(self):
        result = build_number(3.14)
        assert result == {"number": 3.14}

    def test_build_select(self):
        result = build_select("open")
        assert result == {"select": {"name": "open"}}

    def test_build_multi_select(self):
        result = build_multi_select(["AI", "IoT", "BigData"])
        assert result == {"multi_select": [{"name": "AI"}, {"name": "IoT"}, {"name": "BigData"}]}

    def test_build_multi_select_empty(self):
        result = build_multi_select([])
        assert result == {"multi_select": []}

    def test_build_date(self):
        result = build_date("2025-12-31")
        assert result == {"date": {"start": "2025-12-31"}}

    def test_build_date_with_end(self):
        result = build_date("2025-01-01", end="2025-12-31")
        assert result == {"date": {"start": "2025-01-01", "end": "2025-12-31"}}

    def test_build_url(self):
        result = build_url("https://example.com")
        assert result == {"url": "https://example.com"}

    def test_build_email(self):
        result = build_email("test@example.com")
        assert result == {"email": "test@example.com"}

    def test_build_phone(self):
        result = build_phone("010-1234-5678")
        assert result == {"phone_number": "010-1234-5678"}

    def test_build_relation(self):
        result = build_relation(["page-id-1", "page-id-2"])
        assert result == {"relation": [{"id": "page-id-1"}, {"id": "page-id-2"}]}

    def test_build_relation_single(self):
        result = build_relation("page-id-1")
        assert result == {"relation": [{"id": "page-id-1"}]}


# -------------------------------------------------------------------
# extract_property_value
# -------------------------------------------------------------------


class TestExtractPropertyValue:
    """Notion property 에서 값을 추출하는 헬퍼 테스트."""

    def test_extract_title(self):
        prop = {"type": "title", "title": [{"text": {"content": "My Title"}}]}
        assert extract_property_value(prop) == "My Title"

    def test_extract_title_empty(self):
        prop = {"type": "title", "title": []}
        assert extract_property_value(prop) == ""

    def test_extract_rich_text(self):
        prop = {"type": "rich_text", "rich_text": [{"text": {"content": "Hello"}}]}
        assert extract_property_value(prop) == "Hello"

    def test_extract_number(self):
        prop = {"type": "number", "number": 42}
        assert extract_property_value(prop) == 42

    def test_extract_select(self):
        prop = {"type": "select", "select": {"name": "open"}}
        assert extract_property_value(prop) == "open"

    def test_extract_select_none(self):
        prop = {"type": "select", "select": None}
        assert extract_property_value(prop) is None

    def test_extract_multi_select(self):
        prop = {"type": "multi_select", "multi_select": [{"name": "AI"}, {"name": "IoT"}]}
        assert extract_property_value(prop) == ["AI", "IoT"]

    def test_extract_date(self):
        prop = {"type": "date", "date": {"start": "2025-12-31", "end": None}}
        assert extract_property_value(prop) == "2025-12-31"

    def test_extract_date_none(self):
        prop = {"type": "date", "date": None}
        assert extract_property_value(prop) is None

    def test_extract_url(self):
        prop = {"type": "url", "url": "https://example.com"}
        assert extract_property_value(prop) == "https://example.com"

    def test_extract_email(self):
        prop = {"type": "email", "email": "test@example.com"}
        assert extract_property_value(prop) == "test@example.com"

    def test_extract_phone(self):
        prop = {"type": "phone_number", "phone_number": "010-1234-5678"}
        assert extract_property_value(prop) == "010-1234-5678"

    def test_extract_relation(self):
        prop = {"type": "relation", "relation": [{"id": "page-1"}, {"id": "page-2"}]}
        assert extract_property_value(prop) == ["page-1", "page-2"]

    def test_extract_unknown_type(self):
        prop = {"type": "formula", "formula": {"number": 100}}
        assert extract_property_value(prop) is None
