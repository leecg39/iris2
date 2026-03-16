# @TASK P4-R2-T2 - 전문가 상담 신청 API
# @SPEC docs/planning/02-trd.md#전문가-상담
"""
전문가 상담 신청 라우터.

POST /api/v1/consultation/submit
  - Notion DB 저장 -> 확인 이메일 발송
  - 이메일 실패해도 신청은 성공 (graceful degradation)
"""

from __future__ import annotations

import logging

from fastapi import APIRouter

from app.config import settings
from app.models.schemas import ConsultSubmitRequest, ConsultSubmitResponse
from app.services.email_sender import EmailSender
from app.services.notion_db import (
    NotionDBClient,
    build_title,
    build_rich_text,
    build_email,
    build_phone,
    build_select,
    build_relation,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/consultation", tags=["consultation"])


# -------------------------------------------------------------------
# Dependency helpers (테스트에서 패치 가능)
# -------------------------------------------------------------------


def get_notion_client() -> NotionDBClient:
    """NotionDBClient 인스턴스 생성."""
    return NotionDBClient(token=settings.notion_api_token)


def get_email_sender() -> EmailSender:
    """EmailSender 인스턴스 생성."""
    return EmailSender(
        host=settings.smtp_host,
        port=settings.smtp_port,
        user=settings.smtp_user,
        password=settings.smtp_password,
    )


# -------------------------------------------------------------------
# Endpoints
# -------------------------------------------------------------------


@router.post("/submit", response_model=ConsultSubmitResponse)
async def submit_consultation(request: ConsultSubmitRequest) -> ConsultSubmitResponse:
    """전문가 상담 신청을 접수한다.

    1. Notion DB에 상담 신청 페이지 생성
    2. 신청자에게 확인 이메일 발송 (실패해도 신청은 유지)

    Returns:
        ConsultSubmitResponse: 접수 결과 (id, status, email_sent)
    """
    notion = get_notion_client()
    email_sender = get_email_sender()

    # Layer 1: Pydantic 입력 검증 (자동)
    # Layer 2: Notion DB 저장
    properties = {
        "이름": build_title(request.requester_name),
        "기업": build_relation(request.company_id),
        "공고": build_relation(request.announcement_id),
        "이메일": build_email(request.email),
        "전화번호": build_phone(request.phone),
        "메시지": build_rich_text(request.message),
        "상태": build_select("접수"),
    }

    page = await notion.create_page(
        database_id=settings.notion_db_consult_id,
        properties=properties,
    )
    page_id = page["id"]
    logger.info("상담 신청 저장 완료: %s", page_id)

    # Layer 3: 확인 이메일 발송 (graceful degradation)
    email_sent = await email_sender.send_confirmation_email(
        to_email=request.email,
        requester_name=request.requester_name,
        company_name=request.company_id,
        announcement_title=request.announcement_id,
    )

    if not email_sent:
        logger.warning("확인 이메일 발송 실패 (신청은 유지): %s", request.email)

    return ConsultSubmitResponse(
        id=page_id,
        status="접수",
        email_sent=email_sent,
    )
