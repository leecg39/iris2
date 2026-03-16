# @TASK P2-R1-T1 - 공공API(기업마당) 기업 조회 서비스
# @SPEC docs/planning/02-trd.md#기업-조회
"""
공공API를 통한 기업 정보 조회 서비스.

사업자번호(10자리)로 기업마당 등 공공API를 호출하여
기업 기본 정보를 조회한다.
"""

from __future__ import annotations

import logging
import re
from typing import Any

import httpx

logger = logging.getLogger(__name__)


# -------------------------------------------------------------------
# Custom exceptions
# -------------------------------------------------------------------


class BusinessNumberError(ValueError):
    """사업자번호 유효성 검증 실패 시 발생하는 예외."""

    pass


class CompanyNotFoundError(Exception):
    """공공API에서 기업을 찾지 못한 경우 발생하는 예외."""

    pass


# -------------------------------------------------------------------
# PublicAPIService
# -------------------------------------------------------------------


class PublicAPIService:
    """공공API(기업마당 등) 기업 조회 서비스.

    사업자번호로 기업 기본 정보를 조회한다.
    외부 API 호출에는 httpx.AsyncClient를 사용한다.
    """

    # 기업마당 API 엔드포인트 (예시 - 실제 URL은 환경변수로 관리 가능)
    BASE_URL = "https://www.bizinfo.go.kr/uss/rss/bizinfoApi.do"

    def normalize_business_number(self, business_number: str) -> str:
        """사업자번호를 정규화한다.

        하이픈을 제거하고 10자리 숫자인지 검증한다.

        Args:
            business_number: 사업자등록번호 (하이픈 포함/미포함)

        Returns:
            하이픈 제거된 10자리 숫자 문자열

        Raises:
            BusinessNumberError: 10자리 숫자가 아닌 경우
        """
        # 하이픈 제거
        normalized = re.sub(r"-", "", business_number)

        # 10자리 숫자 검증
        if not re.match(r"^\d{10}$", normalized):
            raise BusinessNumberError(
                "사업자번호는 10자리 숫자여야 합니다 "
                f"(입력값: {business_number!r})"
            )

        return normalized

    async def lookup_company(self, business_number: str) -> dict[str, Any]:
        """사업자번호로 기업 정보를 조회한다.

        Args:
            business_number: 사업자등록번호 (10자리, 하이픈 포함 가능)

        Returns:
            기업 정보 딕셔너리:
            - business_number: str (10자리)
            - company_name: str
            - ceo_name: str
            - industry: str
            - revenue: int (원)
            - employee_count: int
            - address: str

        Raises:
            BusinessNumberError: 사업자번호 유효성 검증 실패
            CompanyNotFoundError: API에서 기업을 찾지 못한 경우
            Exception: 외부 API 호출 실패
        """
        # Layer 1: 입력 검증
        normalized = self.normalize_business_number(business_number)

        # Layer 2: 공공API 호출
        logger.info("공공API 기업 조회 요청: %s", normalized)

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(
                self.BASE_URL,
                params={"business_number": normalized},
            )

        # Layer 3: 응답 처리
        if response.status_code != 200:
            logger.error(
                "공공API 응답 에러: status=%d, body=%s",
                response.status_code,
                response.text[:200],
            )
            raise Exception(
                f"공공API 호출 실패 (status={response.status_code})"
            )

        data = response.json()
        items = data.get("items", [])

        if not items:
            logger.warning("기업 정보 없음: business_number=%s", normalized)
            raise CompanyNotFoundError(
                f"사업자번호 {normalized}에 해당하는 기업을 찾을 수 없습니다"
            )

        # 첫 번째 결과 사용
        item = items[0]

        return {
            "business_number": normalized,
            "company_name": item.get("company_name", ""),
            "ceo_name": item.get("ceo_name", ""),
            "industry": item.get("industry", ""),
            "revenue": item.get("revenue"),
            "employee_count": item.get("employee_count"),
            "address": item.get("address", ""),
        }
