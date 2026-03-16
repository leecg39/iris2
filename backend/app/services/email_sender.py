# @TASK P4-R2-T1 - 이메일 발송 서비스
# @SPEC docs/planning/02-trd.md#이메일-발송
"""
상담 신청 확인 이메일 발송 서비스.

aiosmtplib을 사용하여 비동기 SMTP 이메일을 발송한다.
"""

from __future__ import annotations

import logging
from email.message import EmailMessage

import aiosmtplib

logger = logging.getLogger(__name__)


class EmailSender:
    """이메일 발송 서비스 (aiosmtplib).

    Args:
        host: SMTP 서버 호스트
        port: SMTP 서버 포트
        user: SMTP 인증 사용자
        password: SMTP 인증 비밀번호
    """

    def __init__(self, host: str, port: int, user: str, password: str):
        self.host = host
        self.port = port
        self.user = user
        self.password = password

    async def send_confirmation_email(
        self,
        to_email: str,
        requester_name: str,
        company_name: str,
        announcement_title: str,
    ) -> bool:
        """상담 신청 확인 이메일 발송.

        HTML 템플릿으로 확인 이메일을 생성하여 발송한다.

        Args:
            to_email: 수신자 이메일 주소
            requester_name: 신청자 이름
            company_name: 기업명
            announcement_title: 공고 제목

        Returns:
            True (성공) / False (실패)
        """
        try:
            html_body = self._build_html_template(
                requester_name=requester_name,
                company_name=company_name,
                announcement_title=announcement_title,
            )

            message = EmailMessage()
            message["From"] = self.user
            message["To"] = to_email
            message["Subject"] = "[IRIS] 전문가 상담 신청이 접수되었습니다"
            message.set_content(
                f"{requester_name}님, {announcement_title} 관련 상담 신청이 접수되었습니다."
            )
            message.add_alternative(html_body, subtype="html")

            await aiosmtplib.send(
                message,
                hostname=self.host,
                port=self.port,
                username=self.user,
                password=self.password,
                start_tls=True,
            )

            logger.info("확인 이메일 발송 성공: %s", to_email)
            return True

        except Exception as exc:
            logger.error("이메일 발송 실패 (%s): %s", to_email, exc)
            return False

    def _build_html_template(
        self,
        requester_name: str,
        company_name: str,
        announcement_title: str,
    ) -> str:
        """확인 이메일 HTML 템플릿 생성.

        Args:
            requester_name: 신청자 이름
            company_name: 기업명
            announcement_title: 공고 제목

        Returns:
            HTML 문자열
        """
        return f"""\
<html>
<head>
  <meta charset="utf-8">
</head>
<body style="font-family: 'Apple SD Gothic Neo', sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background: #1a56db; color: white; padding: 20px; border-radius: 8px 8px 0 0;">
    <h1 style="margin: 0; font-size: 20px;">IRIS 전문가 상담 신청 접수 확인</h1>
  </div>
  <div style="border: 1px solid #e5e7eb; border-top: none; padding: 24px; border-radius: 0 0 8px 8px;">
    <p>{requester_name}님, 안녕하세요.</p>
    <p><strong>{announcement_title}</strong> 관련 전문가 상담 신청이 정상적으로 접수되었습니다.</p>
    <table style="width: 100%; border-collapse: collapse; margin: 16px 0;">
      <tr>
        <td style="padding: 8px; border-bottom: 1px solid #e5e7eb; color: #6b7280;">신청자</td>
        <td style="padding: 8px; border-bottom: 1px solid #e5e7eb;">{requester_name}</td>
      </tr>
      <tr>
        <td style="padding: 8px; border-bottom: 1px solid #e5e7eb; color: #6b7280;">기업명</td>
        <td style="padding: 8px; border-bottom: 1px solid #e5e7eb;">{company_name}</td>
      </tr>
      <tr>
        <td style="padding: 8px; border-bottom: 1px solid #e5e7eb; color: #6b7280;">관련 공고</td>
        <td style="padding: 8px; border-bottom: 1px solid #e5e7eb;">{announcement_title}</td>
      </tr>
    </table>
    <p>전문가 배정 후 연락드리겠습니다.</p>
    <p style="color: #6b7280; font-size: 13px; margin-top: 24px;">
      본 메일은 자동 발송된 메일입니다. 문의사항은 IRIS 고객센터로 연락해 주세요.
    </p>
  </div>
</body>
</html>"""
