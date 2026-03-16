# @TASK P4-R1-T1 - PDF 보고서 생성 서비스
# @SPEC docs/planning/02-trd.md#보고서-생성
"""
ReportLab 기반 PDF 보고서 생성 서비스.

매칭 분석 결과를 기반으로 한국어 PDF 보고서를 생성한다.
CID 폰트(HYSMyeongJo-Medium)를 사용하여 한글을 지원한다.
"""

from __future__ import annotations

import io
import logging
import re
from datetime import datetime
from typing import Any

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.cidfonts import UnicodeCIDFont
from reportlab.platypus import (
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# 한글 폰트 등록 (CID 폰트 - 별도 파일 불필요)
# ---------------------------------------------------------------------------
_FONT_NAME = "HYSMyeongJo-Medium"
pdfmetrics.registerFont(UnicodeCIDFont(_FONT_NAME))


# ---------------------------------------------------------------------------
# 스타일 정의
# ---------------------------------------------------------------------------

def _build_styles() -> dict[str, ParagraphStyle]:
    """PDF 문서에 사용할 ParagraphStyle 딕셔너리를 반환한다."""
    base = getSampleStyleSheet()

    return {
        "title": ParagraphStyle(
            "KorTitle",
            parent=base["Title"],
            fontName=_FONT_NAME,
            fontSize=18,
            leading=24,
            spaceAfter=12,
            textColor=colors.HexColor("#1a237e"),
        ),
        "heading": ParagraphStyle(
            "KorHeading",
            parent=base["Heading2"],
            fontName=_FONT_NAME,
            fontSize=13,
            leading=18,
            spaceBefore=14,
            spaceAfter=6,
            textColor=colors.HexColor("#283593"),
        ),
        "body": ParagraphStyle(
            "KorBody",
            parent=base["Normal"],
            fontName=_FONT_NAME,
            fontSize=10,
            leading=15,
            spaceAfter=4,
        ),
        "small": ParagraphStyle(
            "KorSmall",
            parent=base["Normal"],
            fontName=_FONT_NAME,
            fontSize=8,
            leading=11,
            textColor=colors.grey,
        ),
        "score": ParagraphStyle(
            "KorScore",
            parent=base["Normal"],
            fontName=_FONT_NAME,
            fontSize=24,
            leading=30,
            alignment=1,  # center
            textColor=colors.HexColor("#1b5e20"),
        ),
    }


# ---------------------------------------------------------------------------
# PDFReportGenerator
# ---------------------------------------------------------------------------


class PDFReportGenerator:
    """PDF 보고서 생성 서비스 (ReportLab 기반).

    매칭 분석 보고서를 PDF 바이트로 생성한다.
    """

    def __init__(self) -> None:
        self.styles = _build_styles()

    # -- Public API --

    async def generate_report(
        self,
        company: dict[str, Any],
        announcement: dict[str, Any],
        match_result: dict[str, Any],
    ) -> bytes:
        """매칭 분석 보고서 PDF를 생성한다.

        보고서 구조:
        1. 헤더: IRIS 매칭 분석 보고서
        2. 기업 정보: 회사명, 업종, 연구분야, 기술키워드
        3. 공고 정보: 공고명, 기관, 분야, 마감일, 지원규모
        4. 적합도 분석: 점수(0-100), 매칭 근거
        5. AI 요약: 핵심 요건, 자격 조건
        6. 푸터: 생성일시

        Args:
            company: 기업 정보 딕셔너리
            announcement: 공고 정보 딕셔너리
            match_result: 매칭 결과 딕셔너리

        Returns:
            PDF 바이트 (bytes)
        """
        buffer = io.BytesIO()

        doc = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            topMargin=20 * mm,
            bottomMargin=20 * mm,
            leftMargin=20 * mm,
            rightMargin=20 * mm,
        )

        elements = self._build_elements(company, announcement, match_result)
        doc.build(elements)

        pdf_bytes = buffer.getvalue()
        buffer.close()

        return pdf_bytes

    def generate_filename(self, company_name: str, announcement_title: str) -> str:
        """보고서 파일명을 생성한다.

        형식: IRIS_보고서_{회사명}_{공고명}_{날짜}.pdf

        파일시스템에 안전하지 않은 문자는 제거된다.

        Args:
            company_name: 기업명
            announcement_title: 공고명

        Returns:
            안전한 파일명 문자열
        """
        today = datetime.now().strftime("%Y%m%d")
        safe_company = self._sanitize_filename(company_name)
        safe_title = self._sanitize_filename(announcement_title)

        return f"IRIS_보고서_{safe_company}_{safe_title}_{today}.pdf"

    # -- Private helpers --

    def _build_elements(
        self,
        company: dict[str, Any],
        announcement: dict[str, Any],
        match_result: dict[str, Any],
    ) -> list:
        """PDF Platypus 요소 리스트를 구성한다."""
        elements: list = []

        # 1. 헤더
        elements.append(Paragraph("IRIS 매칭 분석 보고서", self.styles["title"]))
        elements.append(Spacer(1, 6 * mm))

        # 2. 기업 정보
        elements.append(Paragraph("1. 기업 정보", self.styles["heading"]))
        company_data = self._build_company_table(company)
        elements.append(company_data)
        elements.append(Spacer(1, 4 * mm))

        # 3. 공고 정보
        elements.append(Paragraph("2. 공고 정보", self.styles["heading"]))
        announcement_data = self._build_announcement_table(announcement)
        elements.append(announcement_data)
        elements.append(Spacer(1, 4 * mm))

        # 4. 적합도 분석
        elements.append(Paragraph("3. 적합도 분석", self.styles["heading"]))
        score = match_result.get("match_score", 0)
        elements.append(Paragraph(f"{score}점", self.styles["score"]))
        elements.append(Spacer(1, 2 * mm))

        reason = match_result.get("match_reason", "")
        if reason:
            elements.append(Paragraph(f"매칭 근거: {reason}", self.styles["body"]))
        elements.append(Spacer(1, 4 * mm))

        # 5. AI 요약
        ai_summary = match_result.get("ai_summary", "")
        if ai_summary:
            elements.append(Paragraph("4. AI 분석 요약", self.styles["heading"]))
            elements.append(Paragraph(ai_summary, self.styles["body"]))
            elements.append(Spacer(1, 4 * mm))

        # 6. 푸터
        now = datetime.now().strftime("%Y-%m-%d %H:%M")
        elements.append(Spacer(1, 10 * mm))
        elements.append(
            Paragraph(
                f"본 보고서는 {now}에 IRIS 자동 매칭 시스템에 의해 생성되었습니다.",
                self.styles["small"],
            )
        )

        return elements

    def _build_company_table(self, company: dict[str, Any]) -> Table:
        """기업 정보 테이블을 생성한다."""
        name = company.get("company_name", "-") or "-"
        industry = company.get("industry", "-") or "-"
        fields = company.get("research_fields", [])
        keywords = company.get("tech_keywords", [])
        revenue = company.get("revenue")
        employees = company.get("employee_count")

        data = [
            [
                Paragraph("기업명", self.styles["body"]),
                Paragraph(name, self.styles["body"]),
            ],
            [
                Paragraph("업종", self.styles["body"]),
                Paragraph(industry, self.styles["body"]),
            ],
            [
                Paragraph("연구분야", self.styles["body"]),
                Paragraph(", ".join(fields) if fields else "-", self.styles["body"]),
            ],
            [
                Paragraph("기술키워드", self.styles["body"]),
                Paragraph(", ".join(keywords) if keywords else "-", self.styles["body"]),
            ],
        ]

        if revenue is not None:
            data.append([
                Paragraph("매출액", self.styles["body"]),
                Paragraph(f"{revenue:,}원", self.styles["body"]),
            ])

        if employees is not None:
            data.append([
                Paragraph("종업원 수", self.styles["body"]),
                Paragraph(f"{employees}명", self.styles["body"]),
            ])

        return self._styled_table(data)

    def _build_announcement_table(self, announcement: dict[str, Any]) -> Table:
        """공고 정보 테이블을 생성한다."""
        title = announcement.get("title", "-") or "-"
        org = announcement.get("organization", "-") or "-"
        field = announcement.get("field", "-") or "-"
        deadline = announcement.get("deadline", "-") or "-"
        budget = announcement.get("budget", "-") or "-"

        data = [
            [
                Paragraph("공고명", self.styles["body"]),
                Paragraph(title, self.styles["body"]),
            ],
            [
                Paragraph("주관기관", self.styles["body"]),
                Paragraph(org, self.styles["body"]),
            ],
            [
                Paragraph("지원분야", self.styles["body"]),
                Paragraph(field, self.styles["body"]),
            ],
            [
                Paragraph("마감일", self.styles["body"]),
                Paragraph(deadline, self.styles["body"]),
            ],
            [
                Paragraph("지원규모", self.styles["body"]),
                Paragraph(budget, self.styles["body"]),
            ],
        ]

        return self._styled_table(data)

    def _styled_table(self, data: list) -> Table:
        """공통 스타일이 적용된 테이블을 반환한다."""
        col_widths = [80 * mm, 90 * mm]
        table = Table(data, colWidths=col_widths)

        table.setStyle(
            TableStyle([
                ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#e8eaf6")),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#9fa8da")),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
            ])
        )

        return table

    @staticmethod
    def _sanitize_filename(name: str) -> str:
        """파일명에 사용할 수 없는 문자를 제거한다."""
        # 파일시스템에 안전하지 않은 문자 제거
        sanitized = re.sub(r'[\\/*?:"<>|]', "", name)
        # 공백을 언더스코어로 대체
        sanitized = sanitized.replace(" ", "_")
        # 빈 문자열 방지
        return sanitized or "unknown"
