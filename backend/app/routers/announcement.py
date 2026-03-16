# @TASK P3-R1-T2 - 공고 조회 API
# @SPEC docs/planning/02-trd.md#공고-API
"""
공고 목록/상세 조회 API 엔드포인트.

GET /api/v1/announcements          - 공고 목록 (상태/키워드 필터, 페이지네이션)
GET /api/v1/announcements/{id}     - 공고 상세 조회
"""

from __future__ import annotations

import logging
from typing import Any, Optional

from fastapi import APIRouter, HTTPException, Query

from app.config import settings
from app.models.schemas import AnnouncementListResponse, AnnouncementResponse
from app.services.notion_db import (
    NotionDBClient,
    NotionAPIError,
    extract_property_value,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/announcements", tags=["announcements"])


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _page_to_announcement(page: dict[str, Any]) -> AnnouncementResponse:
    """Notion 페이지 객체를 AnnouncementResponse로 변환한다."""
    props = page.get("properties", {})
    return AnnouncementResponse(
        iris_id=extract_property_value(props.get("IRIS ID", {})) or "",
        title=extract_property_value(props.get("제목", {})) or "",
        organization=extract_property_value(props.get("주관기관", {})) or "",
        field=extract_property_value(props.get("분야", {})),
        deadline=extract_property_value(props.get("마감일", {})),
        budget=extract_property_value(props.get("지원규모", {})),
        status=extract_property_value(props.get("상태", {})) or "open",
        detail_url=extract_property_value(props.get("상세URL", {})),
    )


def _build_filter(
    status: Optional[str] = None,
    keyword: Optional[str] = None,
) -> Optional[dict[str, Any]]:
    """Notion 쿼리 필터를 구성한다."""
    conditions: list[dict[str, Any]] = []

    if status:
        conditions.append({
            "property": "상태",
            "select": {"equals": status},
        })

    if keyword:
        conditions.append({
            "property": "제목",
            "title": {"contains": keyword},
        })

    if not conditions:
        return None
    if len(conditions) == 1:
        return conditions[0]
    return {"and": conditions}


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------


@router.get("", response_model=AnnouncementListResponse)
async def get_announcements(
    status: Optional[str] = Query(None, description="공고 상태 필터 (진행중/마감)"),
    keyword: Optional[str] = Query(None, description="키워드 검색"),
    page: int = Query(1, ge=1, description="페이지 번호"),
    page_size: int = Query(20, ge=1, le=100, description="페이지 크기"),
):
    """공고 목록을 조회한다.

    Notion AnnouncementCache DB에서 공고 목록을 필터/페이지네이션하여 반환한다.

    Raises:
        503: Notion DB 장애
    """
    notion = NotionDBClient(token=settings.notion_api_token)
    notion_filter = _build_filter(status=status, keyword=keyword)

    try:
        pages = await notion.query_database(
            database_id=settings.notion_db_announcement_id,
            filter=notion_filter,
            sorts=[{"property": "마감일", "direction": "ascending"}],
        )
    except NotionAPIError as e:
        logger.error("Notion DB 조회 실패: %s", e)
        raise HTTPException(
            status_code=503,
            detail="데이터베이스 서비스에 일시적 장애가 발생했습니다",
        )

    total = len(pages)

    # 서버 사이드 페이지네이션 (Notion은 전체 반환이므로 슬라이싱)
    start = (page - 1) * page_size
    end = start + page_size
    sliced = pages[start:end]

    items = [_page_to_announcement(p) for p in sliced]

    return AnnouncementListResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/{announcement_id}", response_model=AnnouncementResponse)
async def get_announcement_detail(announcement_id: str):
    """공고 상세 정보를 조회한다.

    Args:
        announcement_id: Notion 페이지 ID

    Raises:
        404: 공고를 찾을 수 없음
        503: Notion DB 장애
    """
    notion = NotionDBClient(token=settings.notion_api_token)

    try:
        page = await notion.get_page(page_id=announcement_id)
    except NotionAPIError as e:
        if e.code == "object_not_found":
            raise HTTPException(
                status_code=404,
                detail=f"공고 '{announcement_id}'를 찾을 수 없습니다",
            )
        logger.error("Notion DB 조회 실패: %s", e)
        raise HTTPException(
            status_code=503,
            detail="데이터베이스 서비스에 일시적 장애가 발생했습니다",
        )

    return _page_to_announcement(page)
