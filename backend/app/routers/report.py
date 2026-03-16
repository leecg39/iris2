# @TASK P4-R1-T2 - 보고서 API
# @SPEC docs/planning/02-trd.md#보고서-API
"""
보고서 API 엔드포인트.

GET  /api/v1/reports               - 보고서 목록 (Notion DB 조회)
GET  /api/v1/reports/{id}/download - PDF 다운로드 (StreamingResponse)
"""

from __future__ import annotations

import json
import logging
from typing import Any, Optional
from urllib.parse import quote

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import StreamingResponse

from app.config import settings
from app.models.schemas import ReportListResponse, ReportResponse
from app.services.notion_db import (
    NotionAPIError,
    NotionDBClient,
    extract_property_value,
)
from app.services.pdf_generator import PDFReportGenerator

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/reports", tags=["reports"])


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _page_to_report(page: dict[str, Any]) -> ReportResponse:
    """Notion 보고서 페이지를 ReportResponse로 변환한다."""
    props = page.get("properties", {})
    created = page.get("created_time", "")

    return ReportResponse(
        id=page["id"],
        announcement_title=extract_property_value(props.get("공고제목", {})) or "",
        match_score=extract_property_value(props.get("매칭점수", {})) or 0,
        pdf_url=extract_property_value(props.get("PDF_URL", {})),
        created_at=created,
    )


def _extract_json_property(props: dict, key: str) -> dict[str, Any]:
    """Notion 속성에서 JSON 문자열을 파싱한다. 실패 시 빈 딕셔너리를 반환한다."""
    raw = extract_property_value(props.get(key, {})) or ""
    if not raw:
        return {}
    try:
        return json.loads(raw)
    except (json.JSONDecodeError, TypeError):
        logger.warning("JSON 파싱 실패 (key=%s): %s", key, raw[:100])
        return {}


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------


@router.get("", response_model=ReportListResponse)
async def get_reports(
    page: int = Query(1, ge=1, description="페이지 번호"),
    page_size: int = Query(20, ge=1, le=100, description="페이지 크기"),
):
    """보고서 목록을 조회한다.

    Notion Report DB에서 보고서 목록을 페이지네이션하여 반환한다.

    Raises:
        503: Notion DB 장애
    """
    notion = NotionDBClient(token=settings.notion_api_token)

    try:
        pages = await notion.query_database(
            database_id=settings.notion_db_report_id,
            sorts=[{"timestamp": "created_time", "direction": "descending"}],
        )
    except NotionAPIError as e:
        logger.error("보고서 목록 조회 실패: %s", e)
        raise HTTPException(
            status_code=503,
            detail="데이터베이스 서비스에 일시적 장애가 발생했습니다",
        )

    total = len(pages)
    start = (page - 1) * page_size
    end = start + page_size
    sliced = pages[start:end]

    items = [_page_to_report(p) for p in sliced]

    return ReportListResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/{report_id}/download")
async def download_report(report_id: str):
    """보고서 PDF를 다운로드한다.

    Notion에서 보고서 메타데이터를 조회한 뒤 PDF를 실시간 생성하여
    StreamingResponse로 반환한다.

    Args:
        report_id: Notion 보고서 페이지 ID

    Raises:
        404: 보고서를 찾을 수 없음
        503: Notion DB 장애
    """
    notion = NotionDBClient(token=settings.notion_api_token)

    try:
        page = await notion.get_page(page_id=report_id)
    except NotionAPIError as e:
        if e.code == "object_not_found":
            raise HTTPException(
                status_code=404,
                detail=f"보고서 '{report_id}'를 찾을 수 없습니다",
            )
        logger.error("보고서 조회 실패: %s", e)
        raise HTTPException(
            status_code=503,
            detail="데이터베이스 서비스에 일시적 장애가 발생했습니다",
        )

    props = page.get("properties", {})

    # Notion 속성에서 PDF 생성에 필요한 데이터 추출
    company_data = _extract_json_property(props, "기업정보")
    announcement_data = _extract_json_property(props, "공고정보")
    match_data = _extract_json_property(props, "매칭결과")

    # 기본 필드 보강 (JSON에 없을 경우 Notion 속성에서 가져옴)
    if not company_data.get("company_name"):
        company_data["company_name"] = extract_property_value(props.get("기업명", {})) or ""
    if not announcement_data.get("title"):
        announcement_data["title"] = extract_property_value(props.get("공고제목", {})) or ""
    if "match_score" not in match_data:
        match_data["match_score"] = extract_property_value(props.get("매칭점수", {})) or 0

    # PDF 생성
    generator = PDFReportGenerator()
    pdf_bytes = await generator.generate_report(
        company=company_data,
        announcement=announcement_data,
        match_result=match_data,
    )

    filename = generator.generate_filename(
        company_name=company_data.get("company_name", "unknown"),
        announcement_title=announcement_data.get("title", "unknown"),
    )

    # RFC 5987 인코딩으로 한글 파일명 지원
    encoded_filename = quote(filename)

    return StreamingResponse(
        iter([pdf_bytes]),
        media_type="application/pdf",
        headers={
            "Content-Disposition": (
                f"attachment; "
                f"filename=\"{encoded_filename}\"; "
                f"filename*=UTF-8''{encoded_filename}"
            ),
        },
    )
