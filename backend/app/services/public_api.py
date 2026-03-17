# @TASK P2-R1-T1 - 공공API(국세청) 기업 조회 서비스
# @SPEC docs/planning/02-trd.md#기업-조회
"""
국세청 사업자등록정보 진위확인 및 상태조회 서비스 연동.

사업자번호(10자리)로 data.go.kr 국세청 API를 호출하여
사업자 상태를 확인하고, 기업 정보를 조회한다.
"""

from __future__ import annotations

import logging
import re
from typing import Any

import httpx

from app.config import settings

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
    """국세청 사업자등록정보 API를 통한 기업 조회 서비스.

    1단계: 사업자번호 유효성 검증 (포맷)
    2단계: 국세청 사업자등록 상태조회 API 호출
    3단계: 결과 반환
    """

    # 국세청 사업자등록정보 진위확인 및 상태조회 API (data.go.kr)
    NTS_STATUS_URL = (
        "https://api.odcloud.kr/api/nts-businessman/v1/status"
    )

    _shared_client: httpx.AsyncClient | None = None

    @classmethod
    def _get_client(cls) -> httpx.AsyncClient:
        """재사용 가능한 AsyncClient를 반환한다 (커넥션 풀링)."""
        if cls._shared_client is None or cls._shared_client.is_closed:
            cls._shared_client = httpx.AsyncClient(
                timeout=30.0,
                limits=httpx.Limits(max_connections=20, max_keepalive_connections=10),
            )
        return cls._shared_client

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
        normalized = re.sub(r"-", "", business_number)

        if not re.match(r"^\d{10}$", normalized):
            raise BusinessNumberError(
                "사업자번호는 10자리 숫자여야 합니다 "
                f"(입력값: {business_number!r})"
            )

        return normalized

    async def check_business_status(self, business_number: str) -> dict[str, Any]:
        """국세청 API로 사업자등록 상태를 조회한다.

        Args:
            business_number: 정규화된 10자리 사업자번호

        Returns:
            국세청 API 응답 데이터 (b_stt, tax_type 등)

        Raises:
            Exception: API 호출 실패
        """
        api_key = settings.data_go_kr_api_key
        if not api_key:
            raise Exception("DATA_GO_KR_API_KEY가 설정되지 않았습니다")

        client = self._get_client()
        response = await client.post(
            self.NTS_STATUS_URL,
            params={"serviceKey": api_key},
            json={"b_no": [business_number]},
            headers={"Content-Type": "application/json"},
        )

        if response.status_code != 200:
            logger.error(
                "국세청 API 응답 에러: status=%d, body=%s",
                response.status_code,
                response.text[:200],
            )
            raise Exception(
                f"국세청 API 호출 실패 (status={response.status_code})"
            )

        data = response.json()
        results = data.get("data", [])

        if not results:
            raise CompanyNotFoundError(
                f"사업자번호 {business_number}에 대한 조회 결과가 없습니다"
            )

        return results[0]

    async def lookup_company(self, business_number: str) -> dict[str, Any]:
        """사업자번호로 기업 정보를 조회한다.

        국세청 상태조회 API를 호출하여 사업자 유효성을 확인하고,
        기업 기본 정보를 반환한다.

        Args:
            business_number: 사업자등록번호 (10자리, 하이픈 포함 가능)

        Returns:
            기업 정보 딕셔너리

        Raises:
            BusinessNumberError: 사업자번호 유효성 검증 실패
            CompanyNotFoundError: 기업을 찾지 못한 경우
            Exception: 외부 API 호출 실패
        """
        normalized = self.normalize_business_number(business_number)

        logger.info("국세청 사업자 상태조회 요청: %s", normalized)

        # 국세청 API 호출
        status_data = await self.check_business_status(normalized)

        # 사업 상태 확인
        b_stt = status_data.get("b_stt", "")
        b_stt_cd = status_data.get("b_stt_cd", "")
        tax_type = status_data.get("tax_type", "")

        # 폐업 사업자 처리
        if b_stt_cd == "03":
            raise CompanyNotFoundError(
                f"사업자번호 {normalized}은(는) 폐업 상태입니다 (폐업일: {status_data.get('end_dt', '미상')})"
            )

        # 국세청 API는 법인명/대표자/주소를 직접 제공하지 않으므로
        # 상태 정보를 반환하고, 상세 정보는 별도 소스에서 보완
        return {
            "business_number": normalized,
            "company_name": status_data.get("rbf_tax_type", ""),
            "ceo_name": "",
            "industry": tax_type,
            "revenue": None,
            "employee_count": None,
            "address": "",
            "b_stt": b_stt,
            "b_stt_cd": b_stt_cd,
            "tax_type": tax_type,
        }
