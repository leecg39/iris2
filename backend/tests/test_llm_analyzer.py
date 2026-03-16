# @TASK P3-R2-T1 - LLM 분석 엔진 테스트
# @SPEC docs/planning/02-trd.md#AI-적합도-분석
# @TEST tests/test_llm_analyzer.py

import json
import pytest
from unittest.mock import AsyncMock, patch, MagicMock

from app.services.llm_analyzer import LLMAnalyzer


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

MOCK_COMPANY = {
    "company_name": "테스트 주식회사",
    "industry": "소프트웨어 개발",
    "research_fields": ["인공지능", "빅데이터"],
    "tech_keywords": ["자연어처리", "머신러닝", "데이터분석"],
    "revenue": 5_000_000_000,
    "employee_count": 50,
}

MOCK_ANNOUNCEMENT = {
    "title": "2026년 AI 기반 산업혁신 기술개발 사업",
    "organization": "과학기술정보통신부",
    "field": "인공지능",
    "content": "본 사업은 AI 기술을 활용한 산업 혁신을 목표로 합니다. "
               "자연어처리, 컴퓨터비전 등 핵심 AI 기술 개발을 지원합니다. "
               "총 사업비 100억원 규모이며, 과제당 최대 20억원을 지원합니다.",
}

MOCK_GPT_MATCH_RESPONSE = json.dumps({
    "match_score": 85,
    "match_reason": "해당 기업은 인공지능 분야의 자연어처리 기술을 보유하고 있어 "
                    "본 사업의 AI 기반 산업혁신 목표와 높은 연관성을 보입니다.",
})

MOCK_GPT_SUMMARY_RESPONSE = json.dumps({
    "summary": "AI 기술을 활용한 산업 혁신 기술개발 지원 사업으로, "
               "자연어처리 및 컴퓨터비전 등 핵심 AI 기술 개발을 목표로 합니다.",
    "requirements": ["AI 핵심 기술 연구개발 역량", "산업 적용 계획서"],
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
# 1. 기업+공고 데이터로 적합도 점수 산출
# ---------------------------------------------------------------------------


class TestAnalyzeMatchScore:
    """analyze_match에서 match_score를 올바르게 반환하는지 검증."""

    @pytest.mark.asyncio
    async def test_analyze_match_score(self, analyzer):
        """GPT 응답에서 match_score를 정확히 파싱한다."""
        mock_response = _mock_chat_response(MOCK_GPT_MATCH_RESPONSE)

        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock, return_value=mock_response,
        ):
            result = await analyzer.analyze_match(MOCK_COMPANY, MOCK_ANNOUNCEMENT)

        assert result["match_score"] == 85

    @pytest.mark.asyncio
    async def test_score_range_clamp_high(self, analyzer):
        """점수가 100을 초과하면 100으로 clamp한다."""
        over_score = json.dumps({"match_score": 150, "match_reason": "높은 적합도"})
        mock_response = _mock_chat_response(over_score)

        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock, return_value=mock_response,
        ):
            result = await analyzer.analyze_match(MOCK_COMPANY, MOCK_ANNOUNCEMENT)

        assert result["match_score"] == 100

    @pytest.mark.asyncio
    async def test_score_range_clamp_low(self, analyzer):
        """점수가 0 미만이면 0으로 clamp한다."""
        under_score = json.dumps({"match_score": -10, "match_reason": "낮은 적합도"})
        mock_response = _mock_chat_response(under_score)

        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock, return_value=mock_response,
        ):
            result = await analyzer.analyze_match(MOCK_COMPANY, MOCK_ANNOUNCEMENT)

        assert result["match_score"] == 0


# ---------------------------------------------------------------------------
# 2. 매칭 근거 텍스트 반환
# ---------------------------------------------------------------------------


class TestAnalyzeMatchReason:
    """analyze_match에서 match_reason을 올바르게 반환하는지 검증."""

    @pytest.mark.asyncio
    async def test_analyze_match_reason(self, analyzer):
        """GPT 응답에서 match_reason 텍스트를 정확히 파싱한다."""
        mock_response = _mock_chat_response(MOCK_GPT_MATCH_RESPONSE)

        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock, return_value=mock_response,
        ):
            result = await analyzer.analyze_match(MOCK_COMPANY, MOCK_ANNOUNCEMENT)

        assert "자연어처리" in result["match_reason"]
        assert len(result["match_reason"]) > 0


# ---------------------------------------------------------------------------
# 3. 점수 0-100 범위 검증
# ---------------------------------------------------------------------------


class TestScoreRange:
    """match_score가 항상 0-100 정수 범위인지 검증."""

    @pytest.mark.asyncio
    async def test_score_is_integer(self, analyzer):
        """match_score는 정수(int)로 반환한다."""
        float_score = json.dumps({"match_score": 72.5, "match_reason": "적합"})
        mock_response = _mock_chat_response(float_score)

        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock, return_value=mock_response,
        ):
            result = await analyzer.analyze_match(MOCK_COMPANY, MOCK_ANNOUNCEMENT)

        assert isinstance(result["match_score"], int)
        assert 0 <= result["match_score"] <= 100


# ---------------------------------------------------------------------------
# 4. 불완전 데이터 처리
# ---------------------------------------------------------------------------


class TestAnalyzeWithMissingData:
    """필수 데이터가 누락된 경우에도 안전하게 처리한다."""

    @pytest.mark.asyncio
    async def test_missing_company_fields(self, analyzer):
        """기업 데이터에 일부 필드가 없어도 분석을 수행한다."""
        minimal_company = {"company_name": "최소 기업"}
        mock_response = _mock_chat_response(MOCK_GPT_MATCH_RESPONSE)

        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock, return_value=mock_response,
        ):
            result = await analyzer.analyze_match(minimal_company, MOCK_ANNOUNCEMENT)

        assert "match_score" in result
        assert "match_reason" in result

    @pytest.mark.asyncio
    async def test_missing_announcement_fields(self, analyzer):
        """공고 데이터에 일부 필드가 없어도 분석을 수행한다."""
        minimal_announcement = {"title": "최소 공고"}
        mock_response = _mock_chat_response(MOCK_GPT_MATCH_RESPONSE)

        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock, return_value=mock_response,
        ):
            result = await analyzer.analyze_match(MOCK_COMPANY, minimal_announcement)

        assert "match_score" in result
        assert "match_reason" in result

    @pytest.mark.asyncio
    async def test_json_parse_failure_returns_default(self, analyzer):
        """GPT 응답이 유효한 JSON이 아닌 경우 기본값을 반환한다."""
        invalid_json = "이것은 유효한 JSON이 아닙니다."
        mock_response = _mock_chat_response(invalid_json)

        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock, return_value=mock_response,
        ):
            result = await analyzer.analyze_match(MOCK_COMPANY, MOCK_ANNOUNCEMENT)

        assert result["match_score"] == 0
        assert isinstance(result["match_reason"], str)


# ---------------------------------------------------------------------------
# 5. OpenAI API 에러 처리
# ---------------------------------------------------------------------------


class TestOpenAIErrorHandling:
    """OpenAI API 호출 실패 시 에러 처리 검증."""

    @pytest.mark.asyncio
    async def test_openai_api_error(self, analyzer):
        """OpenAI API 에러 발생 시 기본값을 반환한다."""
        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock,
            side_effect=Exception("OpenAI API rate limit exceeded"),
        ):
            result = await analyzer.analyze_match(MOCK_COMPANY, MOCK_ANNOUNCEMENT)

        assert result["match_score"] == 0
        assert "오류" in result["match_reason"] or "에러" in result["match_reason"] or len(result["match_reason"]) > 0

    @pytest.mark.asyncio
    async def test_openai_timeout_error(self, analyzer):
        """OpenAI API 타임아웃 시 기본값을 반환한다."""
        with patch.object(
            analyzer.client.chat.completions, "create",
            new_callable=AsyncMock,
            side_effect=TimeoutError("Request timed out"),
        ):
            result = await analyzer.analyze_match(MOCK_COMPANY, MOCK_ANNOUNCEMENT)

        assert result["match_score"] == 0
        assert isinstance(result["match_reason"], str)
