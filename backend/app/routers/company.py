# @TASK P2-R1-T1 - 기업 조회 라우터
# @TASK P2-R1-T2 - 기업 프로필 수정 API
# @SPEC docs/planning/02-trd.md#기업-조회
# @SPEC docs/planning/02-trd.md#기업-프로필-수정
"""
기업 조회/수정 API 엔드포인트.

POST /api/v1/company/lookup  - 사업자번호로 공공API 조회 + Notion DB 저장
PUT  /api/v1/company/profile - 기업 프로필(research_fields, tech_keywords) 수정
"""

from __future__ import annotations

import logging

from fastapi import APIRouter, HTTPException

from app.config import settings
from app.models.schemas import CompanyLookupRequest, CompanyProfile, CompanyProfileUpdate
from app.services.notion_db import (
    NotionDBClient,
    NotionAPIError,
    build_title,
    build_rich_text,
    build_number,
    build_select,
    build_multi_select,
    extract_property_value,
)
from app.services.public_api import (
    PublicAPIService,
    BusinessNumberError,
    CompanyNotFoundError,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/company", tags=["company"])


@router.post("/lookup", response_model=CompanyProfile)
async def lookup_company(request: CompanyLookupRequest):
    """사업자번호로 기업 정보를 조회하고 Notion DB에 저장한다.

    - 공공API(기업마당)에서 기업 기본 정보를 조회
    - 조회 결과를 Notion Company DB에 저장
    - CompanyProfile 응답 반환

    Raises:
        400: 잘못된 사업자번호
        404: 기업 정보를 찾을 수 없음
        503: 외부 API 장애
    """
    # Layer 1: 공공API 조회
    api_service = PublicAPIService()

    try:
        company_data = await api_service.lookup_company(request.business_number)
    except BusinessNumberError as e:
        logger.warning("잘못된 사업자번호: %s", e)
        raise HTTPException(status_code=400, detail=str(e))
    except CompanyNotFoundError as e:
        logger.warning("기업 미발견: %s", e)
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error("외부 API 장애: %s", e)
        raise HTTPException(
            status_code=503,
            detail="외부 API 서비스에 일시적 장애가 발생했습니다",
        )

    # Layer 2: Notion DB 저장
    try:
        notion = NotionDBClient(token=settings.notion_api_token)
        properties = {
            "기업명": build_title(company_data["company_name"]),
            "사업자번호": build_rich_text(company_data["business_number"]),
            "대표자명": build_rich_text(company_data.get("ceo_name", "")),
            "업종": build_select(company_data.get("industry", "기타")),
            "주소": build_rich_text(company_data.get("address", "")),
        }

        # 매출액, 종업원수는 값이 있을 때만 추가
        if company_data.get("revenue") is not None:
            properties["매출액"] = build_number(company_data["revenue"])
        if company_data.get("employee_count") is not None:
            properties["종업원수"] = build_number(company_data["employee_count"])

        await notion.create_page(
            database_id=settings.notion_db_company_id,
            properties=properties,
        )
        logger.info(
            "Notion DB 저장 완료: %s (%s)",
            company_data["company_name"],
            company_data["business_number"],
        )
    except NotionAPIError as e:
        # Notion 저장 실패는 로깅만 하고 조회 결과는 반환
        logger.error("Notion DB 저장 실패: %s", e)

    # Layer 3: 응답 생성
    return CompanyProfile(
        business_number=company_data["business_number"],
        company_name=company_data["company_name"],
        ceo_name=company_data.get("ceo_name", ""),
        industry=company_data.get("industry", ""),
        revenue=company_data.get("revenue"),
        employee_count=company_data.get("employee_count"),
        address=company_data.get("address"),
    )


# @TASK P2-R1-T2 - 기업 프로필 수정 엔드포인트
@router.put("/profile", response_model=CompanyProfile)
async def update_company_profile(request: CompanyProfileUpdate):
    """기업 프로필의 연구 분야/기술 키워드를 업데이트한다.

    - Notion DB에서 사업자번호로 기업을 조회
    - research_fields, tech_keywords를 선택적으로 업데이트
    - 업데이트된 프로필 반환

    Raises:
        404: 해당 사업자번호의 기업을 찾을 수 없음
        422: 요청 검증 실패
    """
    # Layer 1: 사업자번호 정규화 (하이픈 제거)
    normalized_bn = request.business_number.replace("-", "")

    # Layer 2: Notion DB에서 기업 조회
    notion = NotionDBClient(token=settings.notion_api_token)

    try:
        pages = await notion.query_database(
            database_id=settings.notion_db_company_id,
            filter={
                "property": "사업자번호",
                "rich_text": {"equals": normalized_bn},
            },
        )
    except NotionAPIError as e:
        logger.error("Notion DB 조회 실패: %s", e)
        raise HTTPException(
            status_code=503,
            detail="데이터베이스 서비스에 일시적 장애가 발생했습니다",
        )

    if not pages:
        raise HTTPException(
            status_code=404,
            detail=f"사업자번호 '{normalized_bn}'에 해당하는 기업을 찾을 수 없습니다",
        )

    page = pages[0]
    page_id = page["id"]

    # Layer 3: 업데이트할 속성 구성 (None이 아닌 필드만)
    update_properties: dict = {}

    if request.research_fields is not None:
        update_properties["연구분야"] = build_multi_select(request.research_fields)

    if request.tech_keywords is not None:
        update_properties["기술키워드"] = build_multi_select(request.tech_keywords)

    # 업데이트할 내용이 있으면 Notion DB 업데이트
    if update_properties:
        try:
            await notion.update_page(
                page_id=page_id,
                properties=update_properties,
            )
            logger.info("기업 프로필 업데이트 완료: %s", normalized_bn)
        except NotionAPIError as e:
            logger.error("Notion DB 업데이트 실패: %s", e)
            raise HTTPException(
                status_code=503,
                detail="데이터베이스 업데이트에 실패했습니다",
            )

    # Layer 4: 응답 생성 (기존 페이지 속성에서 추출)
    props = page["properties"]

    return CompanyProfile(
        business_number=extract_property_value(props.get("사업자번호", {})) or normalized_bn,
        company_name=extract_property_value(props.get("기업명", {})) or "",
        ceo_name=extract_property_value(props.get("대표자명", {})) or "",
        industry=extract_property_value(props.get("업종", {})) or "",
        revenue=extract_property_value(props.get("매출액", {})),
        employee_count=extract_property_value(props.get("종업원수", {})),
        address=extract_property_value(props.get("주소", {})),
        research_fields=(
            request.research_fields
            if request.research_fields is not None
            else extract_property_value(props.get("연구분야", {})) or []
        ),
        tech_keywords=(
            request.tech_keywords
            if request.tech_keywords is not None
            else extract_property_value(props.get("기술키워드", {})) or []
        ),
    )
