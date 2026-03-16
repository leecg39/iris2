# @TASK P2-R1-T1 - 공공API 기업 조회 서비스 + 엔드포인트 테스트
# @SPEC docs/planning/02-trd.md#기업-조회
# @TEST tests/test_company.py

import pytest
from unittest.mock import AsyncMock, patch, MagicMock

from httpx import AsyncClient, ASGITransport

from main import app
from app.services.public_api import PublicAPIService, BusinessNumberError, CompanyNotFoundError


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

VALID_BN = "1234567890"
VALID_BN_WITH_HYPHEN = "123-45-67890"

MOCK_COMPANY_DATA = {
    "business_number": "1234567890",
    "company_name": "테스트 주식회사",
    "ceo_name": "홍길동",
    "industry": "소프트웨어 개발",
    "revenue": 5_000_000_000,
    "employee_count": 50,
    "address": "서울특별시 강남구 테헤란로 123",
}


@pytest.fixture
def public_api_service():
    return PublicAPIService()


# ---------------------------------------------------------------------------
# 1. 사업자번호 유효성 검증
# ---------------------------------------------------------------------------


class TestBusinessNumberValidation:
    """사업자번호 10자리 숫자 검증 테스트."""

    def test_valid_10_digit_number(self, public_api_service):
        """10자리 숫자는 유효하다."""
        result = public_api_service.normalize_business_number("1234567890")
        assert result == "1234567890"

    def test_valid_with_hyphens(self, public_api_service):
        """하이픈 포함 사업자번호도 정규화 후 유효하다."""
        result = public_api_service.normalize_business_number("123-45-67890")
        assert result == "1234567890"

    def test_invalid_too_short(self, public_api_service):
        """9자리 이하는 유효하지 않다."""
        with pytest.raises(BusinessNumberError, match="10자리"):
            public_api_service.normalize_business_number("123456789")

    def test_invalid_too_long(self, public_api_service):
        """11자리 이상은 유효하지 않다."""
        with pytest.raises(BusinessNumberError, match="10자리"):
            public_api_service.normalize_business_number("12345678901")

    def test_invalid_non_numeric(self, public_api_service):
        """숫자가 아닌 문자 포함 시 유효하지 않다."""
        with pytest.raises(BusinessNumberError, match="10자리"):
            public_api_service.normalize_business_number("12345abcde")

    def test_empty_string(self, public_api_service):
        """빈 문자열은 유효하지 않다."""
        with pytest.raises(BusinessNumberError, match="10자리"):
            public_api_service.normalize_business_number("")


# ---------------------------------------------------------------------------
# 2. 공공API 기업 조회 성공
# ---------------------------------------------------------------------------


class TestLookupCompanySuccess:
    """유효한 사업자번호로 기업 조회 성공 테스트."""

    @pytest.mark.asyncio
    async def test_lookup_company_success(self, public_api_service):
        """공공API에서 기업 정보를 성공적으로 조회한다."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "items": [
                {
                    "company_name": "테스트 주식회사",
                    "ceo_name": "홍길동",
                    "industry": "소프트웨어 개발",
                    "revenue": 5_000_000_000,
                    "employee_count": 50,
                    "address": "서울특별시 강남구 테헤란로 123",
                }
            ]
        }

        with patch("app.services.public_api.httpx.AsyncClient") as mock_client_cls:
            mock_client = AsyncMock()
            mock_client.get = AsyncMock(return_value=mock_response)
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=False)
            mock_client_cls.return_value = mock_client

            result = await public_api_service.lookup_company(VALID_BN)

        assert result["company_name"] == "테스트 주식회사"
        assert result["ceo_name"] == "홍길동"
        assert result["business_number"] == VALID_BN
        assert result["revenue"] == 5_000_000_000
        assert result["employee_count"] == 50


# ---------------------------------------------------------------------------
# 3. 공공API 기업 못 찾은 경우
# ---------------------------------------------------------------------------


class TestLookupCompanyNotFound:
    """API에서 기업을 찾지 못한 경우 테스트."""

    @pytest.mark.asyncio
    async def test_lookup_company_not_found(self, public_api_service):
        """존재하지 않는 사업자번호로 조회 시 CompanyNotFoundError 발생."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"items": []}

        with patch("app.services.public_api.httpx.AsyncClient") as mock_client_cls:
            mock_client = AsyncMock()
            mock_client.get = AsyncMock(return_value=mock_response)
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=False)
            mock_client_cls.return_value = mock_client

            with pytest.raises(CompanyNotFoundError):
                await public_api_service.lookup_company(VALID_BN)


# ---------------------------------------------------------------------------
# 4. 잘못된 사업자번호로 조회 시 에러
# ---------------------------------------------------------------------------


class TestLookupCompanyInvalidNumber:
    """잘못된 사업자번호로 조회 시 에러 테스트."""

    @pytest.mark.asyncio
    async def test_lookup_company_invalid_number(self, public_api_service):
        """잘못된 사업자번호로 lookup_company 호출 시 BusinessNumberError 발생."""
        with pytest.raises(BusinessNumberError):
            await public_api_service.lookup_company("invalid")


# ---------------------------------------------------------------------------
# 5. Notion DB 저장 확인 (엔드포인트 통합)
# ---------------------------------------------------------------------------


class TestCompanyLookupEndpoint:
    """POST /api/v1/company/lookup 엔드포인트 테스트."""

    @pytest.mark.asyncio
    async def test_lookup_endpoint_success_saves_to_notion(self):
        """조회 성공 시 Notion DB에 저장하고 CompanyProfile을 반환한다."""
        with (
            patch("app.routers.company.PublicAPIService") as mock_api_cls,
            patch("app.routers.company.NotionDBClient") as mock_notion_cls,
        ):
            # PublicAPIService mock
            mock_api = AsyncMock()
            mock_api.lookup_company = AsyncMock(return_value=MOCK_COMPANY_DATA)
            mock_api_cls.return_value = mock_api

            # NotionDBClient mock
            mock_notion = AsyncMock()
            mock_notion.create_page = AsyncMock(return_value={"id": "page-123"})
            mock_notion_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.post(
                    "/api/v1/company/lookup",
                    json={"business_number": "123-45-67890"},
                )

            assert resp.status_code == 200
            data = resp.json()
            assert data["company_name"] == "테스트 주식회사"
            assert data["business_number"] == "1234567890"

            # Notion DB create_page 호출 확인
            mock_notion.create_page.assert_called_once()

    @pytest.mark.asyncio
    async def test_lookup_endpoint_invalid_number(self):
        """잘못된 사업자번호로 요청 시 400 에러.

        Pydantic min_length=10을 통과하지만 숫자가 아닌 값을 사용한다.
        """
        with patch("app.routers.company.PublicAPIService") as mock_api_cls:
            mock_api = AsyncMock()
            mock_api.lookup_company = AsyncMock(
                side_effect=BusinessNumberError("사업자번호는 10자리 숫자여야 합니다")
            )
            mock_api_cls.return_value = mock_api

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.post(
                    "/api/v1/company/lookup",
                    json={"business_number": "abcdefghij"},  # 10자리이지만 숫자가 아님
                )

            assert resp.status_code == 400

    @pytest.mark.asyncio
    async def test_lookup_endpoint_not_found(self):
        """기업을 찾지 못한 경우 404 에러."""
        with patch("app.routers.company.PublicAPIService") as mock_api_cls:
            mock_api = AsyncMock()
            mock_api.lookup_company = AsyncMock(
                side_effect=CompanyNotFoundError("기업을 찾을 수 없습니다")
            )
            mock_api_cls.return_value = mock_api

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.post(
                    "/api/v1/company/lookup",
                    json={"business_number": "123-45-67890"},
                )

            assert resp.status_code == 404

    @pytest.mark.asyncio
    async def test_lookup_endpoint_external_api_failure(self):
        """외부 API 장애 시 503 에러."""
        with patch("app.routers.company.PublicAPIService") as mock_api_cls:
            mock_api = AsyncMock()
            mock_api.lookup_company = AsyncMock(
                side_effect=Exception("외부 API 연결 실패")
            )
            mock_api_cls.return_value = mock_api

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.post(
                    "/api/v1/company/lookup",
                    json={"business_number": "123-45-67890"},
                )

            assert resp.status_code == 503
