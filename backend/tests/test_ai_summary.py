# @TASK P3-R2-T2 - AI 요약 서비스 테스트
# @SPEC docs/planning/02-trd.md#AI-공고-요약
# @TEST tests/test_ai_summary.py

import json
import pytest
from unittest.mock import AsyncMock, patch, MagicMock

from app.services.llm_analyzer import LLMAnalyzer


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

MOCK_ANNOUNCEMENT_CONTENT = (
    "2026년 AI 기반 산업혁신 기술개발 사업 공고\n\n"
    "1. 사업 개요\n"
    "본 사업은 인공지능 기술을 활용한 산업 혁신을 목표로 합니다.\n\n"
    "2. 지원 분야\n"
    "자연어처리, 컴퓨터비전 등 핵심 AI 기술 개발\n\n"
    "3. 지원 자격\n"
    "- 중소기업 또는 중견기업\n"
    "- AI 관련 연구 실적 보유\n"
    "- 기업부설연구소 보유 우대\n\n"
    "4. 지원 규모\n"
    "총 사업비 100억원, 과제당 최대 20억원\n\n"
    "5. 신청 요건\n"
    "- 사업계획서 제출\n"
    "- AI 핵심 기술 연구개발 역량 증빙\n"
)

MOCK_GPT_SUMMARY_RESPONSE = json.dumps({
    "summary": "AI 기술을 활용한 산업 혁신 기술개발 지원 사업으로, "
               "자연어처리 및 컴퓨터비전 등 핵심 AI 기술 개발을 목표로 합니다.",
    "requirements": ["AI 핵심 기술 연구개발 역량", "사업계획서 제출"],
    "qualifications": ["중소기업 또는 중견기업", "AI 관련 연구 실적 보유"],
    "budget_info": "총 사업비 100억원, 과제당 최대 20억원",
})


@pytest.fixture
def analyzer():
    return LLMAnalyzer(api_key="test-api-key")


def _mock_chat_response(content: str) -> MagicMock:
    """OpenAI chat completion 응답 mock 생성."""
    message = MagicMock()
    message.content = content
    choice = MagicMock()
    choice.message = message
    response = MagicMock()
    response.choices = [choice]
    return response


# ---------------------------------------------------------------------------
# 1. 공고 전문 요약
# ---------------------------------------------------------------------------


class TestSummarizeAnnouncement:
    """공고 전문을 AI로 요약하는 기능 테스트."""

    @pytest.mark.asyncio
    async def test_summarize_announcement(self, analyzer):
        """공고 전문에서 요약 텍스트를 생성한다."""
        mock_response = _mock_chat_response(MOCK_GPT_SUMMARY_RESPONSE)

        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock, return_value=mock_response,
        ):
            result = await analyzer.summarize_announcement(MOCK_ANNOUNCEMENT_CONTENT)

        assert "summary" in result
        assert len(result["summary"]) > 0
        assert "AI" in result["summary"] or "인공지능" in result["summary"]

    @pytest.mark.asyncio
    async def test_summary_returns_all_fields(self, analyzer):
        """요약 결과에 summary, requirements, qualifications, budget_info 필드가 포함된다."""
        mock_response = _mock_chat_response(MOCK_GPT_SUMMARY_RESPONSE)

        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock, return_value=mock_response,
        ):
            result = await analyzer.summarize_announcement(MOCK_ANNOUNCEMENT_CONTENT)

        assert "summary" in result
        assert "requirements" in result
        assert "qualifications" in result
        assert "budget_info" in result


# ---------------------------------------------------------------------------
# 2. 핵심 요건 추출
# ---------------------------------------------------------------------------


class TestExtractRequirements:
    """공고에서 핵심 요건을 추출하는 기능 테스트."""

    @pytest.mark.asyncio
    async def test_extract_requirements(self, analyzer):
        """핵심 요건을 리스트로 추출한다."""
        mock_response = _mock_chat_response(MOCK_GPT_SUMMARY_RESPONSE)

        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock, return_value=mock_response,
        ):
            result = await analyzer.summarize_announcement(MOCK_ANNOUNCEMENT_CONTENT)

        assert isinstance(result["requirements"], list)
        assert len(result["requirements"]) > 0


# ---------------------------------------------------------------------------
# 3. 자격 조건 추출
# ---------------------------------------------------------------------------


class TestExtractQualifications:
    """공고에서 자격 조건을 추출하는 기능 테스트."""

    @pytest.mark.asyncio
    async def test_extract_qualifications(self, analyzer):
        """자격 조건을 리스트로 추출한다."""
        mock_response = _mock_chat_response(MOCK_GPT_SUMMARY_RESPONSE)

        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock, return_value=mock_response,
        ):
            result = await analyzer.summarize_announcement(MOCK_ANNOUNCEMENT_CONTENT)

        assert isinstance(result["qualifications"], list)
        assert len(result["qualifications"]) > 0


# ---------------------------------------------------------------------------
# 4. 빈 콘텐츠 처리
# ---------------------------------------------------------------------------


class TestSummaryWithEmptyContent:
    """빈 콘텐츠 입력 시 안전하게 처리한다."""

    @pytest.mark.asyncio
    async def test_empty_string(self, analyzer):
        """빈 문자열 입력 시 기본값을 반환한다."""
        result = await analyzer.summarize_announcement("")

        assert result["summary"] == ""
        assert result["requirements"] == []
        assert result["qualifications"] == []
        assert result["budget_info"] == ""

    @pytest.mark.asyncio
    async def test_whitespace_only(self, analyzer):
        """공백만 있는 입력 시 기본값을 반환한다."""
        result = await analyzer.summarize_announcement("   \n\t  ")

        assert result["summary"] == ""
        assert result["requirements"] == []
        assert result["qualifications"] == []
        assert result["budget_info"] == ""

    @pytest.mark.asyncio
    async def test_json_parse_failure_returns_default(self, analyzer):
        """GPT 응답이 유효한 JSON이 아닌 경우 기본값을 반환한다."""
        invalid_json = "요약할 수 없습니다."
        mock_response = _mock_chat_response(invalid_json)

        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock, return_value=mock_response,
        ):
            result = await analyzer.summarize_announcement(MOCK_ANNOUNCEMENT_CONTENT)

        assert result["summary"] == ""
        assert result["requirements"] == []
        assert result["qualifications"] == []
        assert result["budget_info"] == ""

    @pytest.mark.asyncio
    async def test_openai_error_returns_default(self, analyzer):
        """OpenAI API 에러 시 기본값을 반환한다."""
        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock,
            side_effect=Exception("API Error"),
        ):
            result = await analyzer.summarize_announcement(MOCK_ANNOUNCEMENT_CONTENT)

        assert result["summary"] == ""
        assert result["requirements"] == []
        assert result["qualifications"] == []
        assert result["budget_info"] == ""
