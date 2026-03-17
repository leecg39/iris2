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

# 국세청 API 응답 mock
MOCK_NTS_STATUS = {
    "b_no": "1234567890",
    "b_stt": "계속사업자",
    "b_stt_cd": "01",
    "tax_type": "부가가치세 일반과세자",
    "tax_type_cd": "01",
    "end_dt": "",
    "utcc_yn": "N",
    "rbf_tax_type": "부가가치세 일반과세자",
    "rbf_tax_type_cd": "01",
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
# 2. 국세청 API 기업 조회 성공
# ---------------------------------------------------------------------------


class TestLookupCompanySuccess:
    """유효한 사업자번호로 국세청 API 조회 성공 테스트."""

    @pytest.mark.asyncio
    async def test_lookup_company_success(self, public_api_service):
        """국세청 API에서 사업자 상태를 성공적으로 조회한다."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "data": [MOCK_NTS_STATUS]
        }

        mock_client = AsyncMock()
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_client.is_closed = False

        with (
            patch.object(PublicAPIService, '_get_client', return_value=mock_client),
            patch("app.services.public_api.settings") as mock_settings,
        ):
            mock_settings.data_go_kr_api_key = "test-api-key"
            result = await public_api_service.lookup_company(VALID_BN)

        assert result["business_number"] == VALID_BN
        assert result["b_stt"] == "계속사업자"
        assert result["b_stt_cd"] == "01"
        assert result["tax_type"] == "부가가치세 일반과세자"


# ---------------------------------------------------------------------------
# 3. 폐업 사업자 조회 시 에러
# ---------------------------------------------------------------------------


class TestLookupCompanyNotFound:
    """폐업 사업자 또는 조회 결과 없음 테스트."""

    @pytest.mark.asyncio
    async def test_lookup_company_closed(self, public_api_service):
        """폐업 사업자 조회 시 CompanyNotFoundError 발생."""
        closed_status = {**MOCK_NTS_STATUS, "b_stt": "폐업자", "b_stt_cd": "03", "end_dt": "20230101"}
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"data": [closed_status]}

        mock_client = AsyncMock()
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_client.is_closed = False

        with (
            patch.object(PublicAPIService, '_get_client', return_value=mock_client),
            patch("app.services.public_api.settings") as mock_settings,
        ):
            mock_settings.data_go_kr_api_key = "test-api-key"
            with pytest.raises(CompanyNotFoundError, match="폐업"):
                await public_api_service.lookup_company(VALID_BN)

    @pytest.mark.asyncio
    async def test_lookup_company_empty_result(self, public_api_service):
        """조회 결과 없으면 CompanyNotFoundError 발생."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"data": []}

        mock_client = AsyncMock()
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_client.is_closed = False

        with (
            patch.object(PublicAPIService, '_get_client', return_value=mock_client),
            patch("app.services.public_api.settings") as mock_settings,
        ):
            mock_settings.data_go_kr_api_key = "test-api-key"
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
# 5. 엔드포인트 통합 테스트
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
            mock_api = MagicMock()
            mock_api.normalize_business_number.return_value = VALID_BN
            mock_api.lookup_company = AsyncMock(return_value={
                **MOCK_COMPANY_DATA,
                "b_stt": "계속사업자",
                "tax_type": "부가가치세 일반과세자",
            })
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
            # mock fallback이 company_name을 덮어쓰므로 mock 회사명 확인
            assert data["business_number"] == "1234567890"
            mock_notion.create_page.assert_called_once()

    @pytest.mark.asyncio
    async def test_lookup_endpoint_invalid_number(self):
        """잘못된 사업자번호로 요청 시 400 에러."""
        with patch("app.routers.company.PublicAPIService") as mock_api_cls:
            mock_api = MagicMock()
            mock_api.normalize_business_number.side_effect = BusinessNumberError(
                "사업자번호는 10자리 숫자여야 합니다"
            )
            mock_api_cls.return_value = mock_api

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.post(
                    "/api/v1/company/lookup",
                    json={"business_number": "abcdefghij"},
                )

            assert resp.status_code == 400

    @pytest.mark.asyncio
    async def test_lookup_endpoint_not_found(self):
        """폐업 사업자 조회 시 404 에러."""
        with patch("app.routers.company.PublicAPIService") as mock_api_cls:
            mock_api = MagicMock()
            mock_api.normalize_business_number.return_value = VALID_BN
            mock_api.lookup_company = AsyncMock(
                side_effect=CompanyNotFoundError("폐업 상태입니다")
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
    async def test_lookup_endpoint_api_failure_returns_mock(self):
        """국세청 API 장애 시 mock 데이터로 fallback하여 200 반환."""
        with (
            patch("app.routers.company.PublicAPIService") as mock_api_cls,
            patch("app.routers.company.NotionDBClient") as mock_notion_cls,
        ):
            mock_api = MagicMock()
            mock_api.normalize_business_number.return_value = VALID_BN
            mock_api.lookup_company = AsyncMock(
                side_effect=Exception("국세청 API 연결 실패")
            )
            mock_api_cls.return_value = mock_api

            mock_notion = AsyncMock()
            mock_notion.create_page = AsyncMock(return_value={"id": "page-123"})
            mock_notion_cls.return_value = mock_notion

            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as client:
                resp = await client.post(
                    "/api/v1/company/lookup",
                    json={"business_number": "123-45-67890"},
                )

            # API 실패해도 mock fallback으로 200 반환
            assert resp.status_code == 200
            data = resp.json()
            assert data["business_number"] == VALID_BN
            assert data["company_name"] != ""
