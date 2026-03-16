# @TASK P3-R2-T3 - 매칭 분석 API
# @SPEC docs/planning/02-trd.md#매칭-분석-API
"""
매칭 분석 및 결과 조회 API 엔드포인트.

POST /api/v1/matching/analyze          - 스크래핑 -> LLM 분석 -> 결과 저장 파이프라인
GET  /api/v1/matching/results          - 매칭 결과 목록
GET  /api/v1/matching/results/{id}     - 매칭 결과 상세
"""

from __future__ import annotations

import logging
from typing import Any, Optional

from fastapi import APIRouter, HTTPException, Query

from app.config import settings
from app.models.schemas import (
    MatchAnalyzeRequest,
    MatchAnalyzeResponse,
    MatchResultListResponse,
    MatchResultResponse,
)
from app.services.iris_scraper import IRISScraper
from app.services.llm_analyzer import LLMAnalyzer
from app.services.notion_db import (
    NotionDBClient,
    NotionAPIError,
    build_number,
    build_rich_text,
    build_relation,
    build_title,
    extract_property_value,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/matching", tags=["matching"])


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _page_to_match_result(page: dict[str, Any]) -> MatchResultResponse:
    """Notion 매칭 결과 페이지를 MatchResultResponse로 변환한다."""
    props = page.get("properties", {})
    return MatchResultResponse(
        id=page["id"],
        match_score=extract_property_value(props.get("매칭점수", {})) or 0,
        match_reason=extract_property_value(props.get("매칭사유", {})) or "",
        announcement_title=extract_property_value(props.get("공고제목", {})) or "",
        announcement_org=extract_property_value(props.get("주관기관", {})) or "",
        announcement_deadline=extract_property_value(props.get("공고마감일", {})),
    )


def _extract_company_profile(page: dict[str, Any]) -> dict[str, Any]:
    """Notion 기업 페이지에서 LLM 분석용 프로필을 추출한다."""
    props = page.get("properties", {})
    return {
        "company_name": extract_property_value(props.get("기업명", {})) or "",
        "industry": extract_property_value(props.get("업종", {})) or "",
        "research_fields": extract_property_value(props.get("연구분야", {})) or [],
        "tech_keywords": extract_property_value(props.get("기술키워드", {})) or [],
        "revenue": extract_property_value(props.get("매출액", {})),
        "employee_count": extract_property_value(props.get("종업원수", {})),
    }


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------


@router.post("/analyze", response_model=MatchAnalyzeResponse)
async def analyze_matching(request: MatchAnalyzeRequest):
    """매칭 분석 파이프라인: 기업 조회 -> IRIS 스크래핑 -> LLM 분석 -> 결과 저장.

    Args:
        request: 사업자번호를 포함한 매칭 분석 요청

    Returns:
        매칭 분석 결과 목록

    Raises:
        400: 기업 프로필을 찾을 수 없음
        503: 외부 서비스 장애
    """
    normalized_bn = request.business_number.replace("-", "")

    # Step 1: Notion DB에서 기업 프로필 조회
    notion = NotionDBClient(token=settings.notion_api_token)

    try:
        company_pages = await notion.query_database(
            database_id=settings.notion_db_company_id,
            filter={
                "property": "사업자번호",
                "rich_text": {"equals": normalized_bn},
            },
        )
    except NotionAPIError as e:
        logger.error("기업 조회 실패: %s", e)
        raise HTTPException(
            status_code=503,
            detail="데이터베이스 서비스에 일시적 장애가 발생했습니다",
        )

    if not company_pages:
        raise HTTPException(
            status_code=400,
            detail=f"사업자번호 '{normalized_bn}'에 해당하는 기업 프로필을 찾을 수 없습니다. 먼저 기업 조회를 진행해주세요.",
        )

    company_profile = _extract_company_profile(company_pages[0])

    # Step 2: IRIS 공고 스크래핑
    scraper = IRISScraper(
        base_url=settings.iris_base_url,
        delay=settings.scrape_delay,
    )

    try:
        announcements = await scraper.scrape_announcement_list()
    except Exception as e:
        logger.error("IRIS 스크래핑 실패: %s", e)
        raise HTTPException(
            status_code=503,
            detail="IRIS 공고 스크래핑에 실패했습니다",
        )

    # Step 3: LLM 적합도 분석 (각 공고에 대해)
    analyzer = LLMAnalyzer(api_key=settings.openai_api_key)
    results: list[MatchResultResponse] = []

    for ann in announcements:
        try:
            match_result = await analyzer.analyze_match(
                company=company_profile,
                announcement=ann,
            )

            # Step 4: 결과를 Notion Match DB에 저장
            match_properties = {
                "매칭점수": build_number(match_result["match_score"]),
                "매칭사유": build_rich_text(match_result["match_reason"]),
                "공고제목": build_rich_text(ann.get("title", "")),
                "주관기관": build_rich_text(ann.get("organization", "")),
            }

            saved_page = await notion.create_page(
                database_id=settings.notion_db_match_id,
                properties=match_properties,
            )

            results.append(
                MatchResultResponse(
                    id=saved_page["id"],
                    match_score=match_result["match_score"],
                    match_reason=match_result["match_reason"],
                    announcement_title=ann.get("title", ""),
                    announcement_org=ann.get("organization", ""),
                    announcement_deadline=ann.get("deadline"),
                )
            )
        except Exception as e:
            logger.error("매칭 분석/저장 실패 (공고: %s): %s", ann.get("title"), e)
            continue

    return MatchAnalyzeResponse(results=results)


@router.get("/results", response_model=MatchResultListResponse)
async def get_matching_results(
    page: int = Query(1, ge=1, description="페이지 번호"),
    page_size: int = Query(20, ge=1, le=100, description="페이지 크기"),
    sort_by: Optional[str] = Query(None, description="정렬 기준 (score)"),
):
    """매칭 결과 목록을 조회한다.

    Raises:
        503: Notion DB 장애
    """
    notion = NotionDBClient(token=settings.notion_api_token)

    sorts = []
    if sort_by == "score":
        sorts = [{"property": "매칭점수", "direction": "descending"}]
    else:
        sorts = [{"property": "매칭점수", "direction": "descending"}]

    try:
        pages = await notion.query_database(
            database_id=settings.notion_db_match_id,
            sorts=sorts,
        )
    except NotionAPIError as e:
        logger.error("Notion DB 조회 실패: %s", e)
        raise HTTPException(
            status_code=503,
            detail="데이터베이스 서비스에 일시적 장애가 발생했습니다",
        )

    total = len(pages)
    start = (page - 1) * page_size
    end = start + page_size
    sliced = pages[start:end]

    items = [_page_to_match_result(p) for p in sliced]

    return MatchResultListResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/results/{result_id}", response_model=MatchResultResponse)
async def get_matching_result_detail(result_id: str):
    """매칭 결과 상세 정보를 조회한다.

    Args:
        result_id: Notion 페이지 ID

    Raises:
        404: 매칭 결과를 찾을 수 없음
        503: Notion DB 장애
    """
    notion = NotionDBClient(token=settings.notion_api_token)

    try:
        page = await notion.get_page(page_id=result_id)
    except NotionAPIError as e:
        if e.code == "object_not_found":
            raise HTTPException(
                status_code=404,
                detail=f"매칭 결과 '{result_id}'를 찾을 수 없습니다",
            )
        logger.error("Notion DB 조회 실패: %s", e)
        raise HTTPException(
            status_code=503,
            detail="데이터베이스 서비스에 일시적 장애가 발생했습니다",
        )

    return _page_to_match_result(page)
