# @TASK P4-R2-T1 - 이메일 발송 서비스 테스트
# @SPEC docs/planning/02-trd.md#이메일-발송
import pytest
from unittest.mock import AsyncMock, patch, MagicMock

from app.services.email_sender import EmailSender


@pytest.fixture
def email_sender():
    return EmailSender(
        host="smtp.test.com",
        port=587,
        user="test@test.com",
        password="testpass",
    )


@pytest.mark.asyncio
async def test_send_confirmation_email(email_sender):
    """확인 이메일 발송 성공 테스트."""
    with patch("app.services.email_sender.aiosmtplib.send", new_callable=AsyncMock) as mock_send:
        mock_send.return_value = ({}, "OK")

        result = await email_sender.send_confirmation_email(
            to_email="user@example.com",
            requester_name="홍길동",
            company_name="테스트주식회사",
            announcement_title="2026년 R&D 지원사업",
        )

        assert result is True
        mock_send.assert_called_once()

        # send 호출 시 전달된 메시지 확인
        call_args = mock_send.call_args
        message = call_args.kwargs.get("message") or call_args.args[0]
        assert message["To"] == "user@example.com"
        assert "[IRIS]" in message["Subject"]


@pytest.mark.asyncio
async def test_email_html_template(email_sender):
    """HTML 템플릿 내용 확인 테스트."""
    html = email_sender._build_html_template(
        requester_name="홍길동",
        company_name="테스트주식회사",
        announcement_title="2026년 R&D 지원사업",
    )

    assert "홍길동" in html
    assert "테스트주식회사" in html
    assert "2026년 R&D 지원사업" in html
    assert "전문가 배정" in html
    assert "<html" in html.lower()


@pytest.mark.asyncio
async def test_email_with_invalid_address(email_sender):
    """잘못된 이메일 주소 처리 테스트."""
    with patch("app.services.email_sender.aiosmtplib.send", new_callable=AsyncMock) as mock_send:
        mock_send.side_effect = ValueError("Invalid email address")

        result = await email_sender.send_confirmation_email(
            to_email="not-an-email",
            requester_name="홍길동",
            company_name="테스트주식회사",
            announcement_title="2026년 R&D 지원사업",
        )

        assert result is False


@pytest.mark.asyncio
async def test_smtp_connection_error(email_sender):
    """SMTP 연결 실패 처리 테스트."""
    with patch("app.services.email_sender.aiosmtplib.send", new_callable=AsyncMock) as mock_send:
        mock_send.side_effect = OSError("Connection refused")

        result = await email_sender.send_confirmation_email(
            to_email="user@example.com",
            requester_name="홍길동",
            company_name="테스트주식회사",
            announcement_title="2026년 R&D 지원사업",
        )

        assert result is False
