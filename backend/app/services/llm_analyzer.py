# @TASK P3-R2-T1, P3-R2-T2 - LLM 분석 엔진 + AI 요약 서비스
# @SPEC docs/planning/02-trd.md#AI-적합도-분석
"""
OpenAI GPT 기반 기업-공고 적합도 분석 및 공고 요약 서비스.

- analyze_match: 기업 프로필과 공고 정보를 받아 적합도 점수(0-100) 및 근거를 반환
- summarize_announcement: 공고 전문을 받아 요약, 핵심 요건, 자격 조건, 지원 규모를 반환
"""

from __future__ import annotations

import json
import logging
from typing import Any

from openai import AsyncOpenAI

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Default responses (API 에러 또는 JSON 파싱 실패 시)
# ---------------------------------------------------------------------------

_DEFAULT_MATCH_RESULT: dict[str, Any] = {
    "match_score": 0,
    "match_reason": "분석을 수행할 수 없습니다. 잠시 후 다시 시도해주세요.",
}

_DEFAULT_SUMMARY_RESULT: dict[str, Any] = {
    "summary": "",
    "requirements": [],
    "qualifications": [],
    "budget_info": "",
}


# ---------------------------------------------------------------------------
# LLMAnalyzer
# ---------------------------------------------------------------------------


class LLMAnalyzer:
    """OpenAI GPT 기반 분석 서비스.

    Args:
        api_key: OpenAI API 키
        model: 사용할 GPT 모델 (기본: gpt-4o)
    """

    def __init__(self, api_key: str, model: str = "gpt-4o") -> None:
        self.client = AsyncOpenAI(api_key=api_key)
        self.model = model

    # ------------------------------------------------------------------
    # 기업-공고 적합도 분석
    # ------------------------------------------------------------------

    async def analyze_match(
        self,
        company: dict[str, Any],
        announcement: dict[str, Any],
    ) -> dict[str, Any]:
        """기업-공고 적합도 분석.

        Args:
            company: 기업 프로필 딕셔너리
                (company_name, industry, research_fields, tech_keywords 등)
            announcement: 공고 정보 딕셔너리
                (title, organization, field, content 등)

        Returns:
            {
                "match_score": int (0-100),
                "match_reason": str (매칭 근거 한국어 텍스트)
            }
        """
        company_text = self._format_company(company)
        announcement_text = self._format_announcement(announcement)

        system_prompt = (
            "당신은 정부지원사업 적합도 분석 전문가입니다. "
            "기업 프로필과 공고 정보를 분석하여 적합도를 평가합니다.\n\n"
            "반드시 아래 JSON 형식으로만 응답하세요:\n"
            '{"match_score": 0~100 사이 정수, "match_reason": "매칭 근거 설명"}\n\n'
            "match_score 기준:\n"
            "- 80-100: 매우 높은 적합도 (핵심 기술/분야 일치)\n"
            "- 60-79: 높은 적합도 (관련 분야 일치)\n"
            "- 40-59: 보통 적합도 (일부 관련성)\n"
            "- 20-39: 낮은 적합도 (간접적 관련성)\n"
            "- 0-19: 매우 낮은 적합도 (관련성 없음)"
        )

        user_prompt = (
            f"다음 기업과 공고의 적합도를 분석해주세요.\n\n"
            f"[기업 정보]\n{company_text}\n\n"
            f"[공고 정보]\n{announcement_text}"
        )

        try:
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.3,
            )

            content = response.choices[0].message.content
            parsed = json.loads(content)

            # score clamp: 0-100 정수
            raw_score = parsed.get("match_score", 0)
            score = max(0, min(100, int(raw_score)))

            return {
                "match_score": score,
                "match_reason": str(parsed.get("match_reason", "")),
            }

        except json.JSONDecodeError:
            logger.warning("GPT 응답 JSON 파싱 실패: %s", content if "content" in dir() else "N/A")
            return dict(_DEFAULT_MATCH_RESULT)

        except Exception as e:
            logger.error("OpenAI API 호출 실패 (analyze_match): %s", e)
            return dict(_DEFAULT_MATCH_RESULT)

    # ------------------------------------------------------------------
    # 공고 전문 AI 요약
    # ------------------------------------------------------------------

    async def summarize_announcement(self, content: str) -> dict[str, Any]:
        """공고 전문 AI 요약.

        Args:
            content: 공고 전문 텍스트

        Returns:
            {
                "summary": str (3-5줄 요약),
                "requirements": list[str] (핵심 요건),
                "qualifications": list[str] (자격 조건),
                "budget_info": str (지원 규모)
            }
        """
        # 빈 콘텐츠 처리
        if not content or not content.strip():
            return dict(_DEFAULT_SUMMARY_RESULT)

        system_prompt = (
            "당신은 정부지원사업 공고 분석 전문가입니다. "
            "공고 전문을 분석하여 핵심 정보를 추출합니다.\n\n"
            "반드시 아래 JSON 형식으로만 응답하세요:\n"
            "{\n"
            '  "summary": "3-5줄 요약 텍스트",\n'
            '  "requirements": ["핵심 요건1", "핵심 요건2"],\n'
            '  "qualifications": ["자격 조건1", "자격 조건2"],\n'
            '  "budget_info": "지원 규모 정보"\n'
            "}"
        )

        user_prompt = f"다음 공고를 분석하여 요약해주세요.\n\n{content}"

        try:
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.3,
            )

            raw = response.choices[0].message.content
            parsed = json.loads(raw)

            return {
                "summary": str(parsed.get("summary", "")),
                "requirements": list(parsed.get("requirements", [])),
                "qualifications": list(parsed.get("qualifications", [])),
                "budget_info": str(parsed.get("budget_info", "")),
            }

        except json.JSONDecodeError:
            logger.warning("GPT 응답 JSON 파싱 실패 (summarize): %s", raw if "raw" in dir() else "N/A")
            return dict(_DEFAULT_SUMMARY_RESULT)

        except Exception as e:
            logger.error("OpenAI API 호출 실패 (summarize_announcement): %s", e)
            return dict(_DEFAULT_SUMMARY_RESULT)

    # ------------------------------------------------------------------
    # 내부 헬퍼: 데이터 포매팅
    # ------------------------------------------------------------------

    @staticmethod
    def _format_company(company: dict[str, Any]) -> str:
        """기업 프로필을 텍스트로 포매팅한다."""
        lines = []
        if name := company.get("company_name"):
            lines.append(f"- 기업명: {name}")
        if industry := company.get("industry"):
            lines.append(f"- 업종: {industry}")
        if fields := company.get("research_fields"):
            lines.append(f"- 연구 분야: {', '.join(fields)}")
        if keywords := company.get("tech_keywords"):
            lines.append(f"- 기술 키워드: {', '.join(keywords)}")
        if revenue := company.get("revenue"):
            lines.append(f"- 매출액: {revenue:,}원")
        if emp := company.get("employee_count"):
            lines.append(f"- 종업원 수: {emp}명")
        return "\n".join(lines) if lines else "정보 없음"

    @staticmethod
    def _format_announcement(announcement: dict[str, Any]) -> str:
        """공고 정보를 텍스트로 포매팅한다."""
        lines = []
        if title := announcement.get("title"):
            lines.append(f"- 공고명: {title}")
        if org := announcement.get("organization"):
            lines.append(f"- 주관기관: {org}")
        if field := announcement.get("field"):
            lines.append(f"- 분야: {field}")
        if content := announcement.get("content"):
            lines.append(f"- 내용: {content}")
        return "\n".join(lines) if lines else "정보 없음"
