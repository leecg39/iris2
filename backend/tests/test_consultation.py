# @TASK P4-R2-T2 - 전문가 상담 신청 API 테스트
# @SPEC docs/planning/02-trd.md#전문가-상담
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from httpx import AsyncClient, ASGITransport

from main import app


@pytest.fixture
def mock_notion_client():
    """NotionDBClient mock."""
    with patch("app.routers.consult.get_notion_client") as mock_factory:
        client = AsyncMock()
        client.create_page.return_value = {
            "id": "page-id-123",
            "properties": {},
        }
        mock_factory.return_value = client
        yield client


@pytest.fixture
def mock_email_sender():
    """EmailSender mock."""
    with patch("app.routers.consult.get_email_sender") as mock_factory:
        sender = AsyncMock()
        sender.send_confirmation_email.return_value = True
        mock_factory.return_value = sender
        yield sender


@pytest.fixture
def valid_payload():
    return {
        "company_id": "company-abc",
        "announcement_id": "ann-xyz",
        "requester_name": "홍길동",
        "email": "hong@example.com",
        "phone": "010-1234-5678",
        "message": "상담 부탁드립니다.",
    }


@pytest.mark.asyncio
async def test_submit_consultation(mock_notion_client, mock_email_sender, valid_payload):
    """POST /api/v1/consultation/submit 성공 테스트."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.post("/api/v1/consultation/submit", json=valid_payload)

    assert resp.status_code == 200
    data = resp.json()
    assert data["id"] == "page-id-123"
    assert data["status"] == "접수"
    assert data["email_sent"] is True


@pytest.mark.asyncio
async def test_submit_saves_to_notion(mock_notion_client, mock_email_sender, valid_payload):
    """Notion DB 저장 확인 테스트."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/api/v1/consultation/submit", json=valid_payload)

    mock_notion_client.create_page.assert_called_once()
    call_args = mock_notion_client.create_page.call_args
    # database_id 인자가 전달되었는지 확인 (빈 문자열도 전달된 것으로 간주)
    assert "database_id" in call_args.kwargs or len(call_args.args) > 0
    # properties 인자가 전달되었는지 확인
    assert "properties" in call_args.kwargs or len(call_args.args) > 1


@pytest.mark.asyncio
async def test_submit_sends_email(mock_notion_client, mock_email_sender, valid_payload):
    """이메일 발송 확인 테스트."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/api/v1/consultation/submit", json=valid_payload)

    mock_email_sender.send_confirmation_email.assert_called_once_with(
        to_email="hong@example.com",
        requester_name="홍길동",
        company_name="company-abc",
        announcement_title="ann-xyz",
    )


@pytest.mark.asyncio
async def test_submit_validation(mock_notion_client, mock_email_sender):
    """필수 필드 누락 시 422 반환 테스트."""
    incomplete_payload = {
        "company_id": "company-abc",
        # announcement_id 누락
        "requester_name": "홍길동",
        "email": "hong@example.com",
        "phone": "010-1234-5678",
    }
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.post("/api/v1/consultation/submit", json=incomplete_payload)

    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_submit_email_failure_still_saves(mock_notion_client, mock_email_sender, valid_payload):
    """이메일 실패해도 신청은 저장되는지 테스트 (graceful degradation)."""
    mock_email_sender.send_confirmation_email.return_value = False

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.post("/api/v1/consultation/submit", json=valid_payload)

    assert resp.status_code == 200
    data = resp.json()
    assert data["id"] == "page-id-123"
    assert data["status"] == "접수"
    assert data["email_sent"] is False
    # Notion 저장은 여전히 호출됨
    mock_notion_client.create_page.assert_called_once()
