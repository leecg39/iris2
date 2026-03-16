# @TASK P4-R1-T2 - 보고서 API 테스트
# @SPEC docs/planning/02-trd.md#보고서-API

"""
보고서 API 엔드포인트 테스트.

GET /api/v1/reports          - 보고서 목록
GET /api/v1/reports/{id}/download  - PDF 다운로드
"""

from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime

import pytest
from fastapi.testclient import TestClient

from main import app


client = TestClient(app)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


def _make_notion_report_page(page_id: str, title: str, score: float, created: str) -> dict:
    """Notion 보고서 페이지 목 객체 생성."""
    return {
        "id": page_id,
        "created_time": created,
        "properties": {
            "공고제목": {
                "type": "rich_text",
                "rich_text": [{"text": {"content": title}}],
            },
            "매칭점수": {
                "type": "number",
                "number": score,
            },
            "PDF_URL": {
                "type": "url",
                "url": f"/api/v1/reports/{page_id}/download",
            },
            "기업명": {
                "type": "rich_text",
                "rich_text": [{"text": {"content": "테스트기업"}}],
            },
            "기업정보": {
                "type": "rich_text",
                "rich_text": [{"text": {"content": '{"company_name":"테스트기업","industry":"IT"}'}}],
            },
            "공고정보": {
                "type": "rich_text",
                "rich_text": [{"text": {"content": '{"title":"' + title + '","organization":"IITP"}'}}],
            },
            "매칭결과": {
                "type": "rich_text",
                "rich_text": [{"text": {"content": '{"match_score":' + str(score) + ',"match_reason":"매칭 사유"}'}}],
            },
        },
    }


# ---------------------------------------------------------------------------
# Tests: GET /api/v1/reports (목록)
# ---------------------------------------------------------------------------


@patch("app.routers.report.NotionDBClient")
def test_get_reports_list(mock_notion_cls):
    """보고서 목록 API가 정상 응답해야 한다."""
    mock_notion = AsyncMock()
    mock_notion_cls.return_value = mock_notion
    mock_notion.query_database.return_value = [
        _make_notion_report_page("page-1", "AI 개발사업", 85.0, "2026-03-15T10:00:00.000Z"),
        _make_notion_report_page("page-2", "빅데이터 사업", 72.0, "2026-03-14T10:00:00.000Z"),
    ]

    response = client.get("/api/v1/reports")

    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert len(data["items"]) == 2
    assert data["total"] == 2
    assert data["items"][0]["announcement_title"] == "AI 개발사업"
    assert data["items"][0]["match_score"] == 85.0


@patch("app.routers.report.NotionDBClient")
def test_get_reports_empty(mock_notion_cls):
    """보고서가 없으면 빈 목록을 반환해야 한다."""
    mock_notion = AsyncMock()
    mock_notion_cls.return_value = mock_notion
    mock_notion.query_database.return_value = []

    response = client.get("/api/v1/reports")

    assert response.status_code == 200
    data = response.json()
    assert data["items"] == []
    assert data["total"] == 0


# ---------------------------------------------------------------------------
# Tests: GET /api/v1/reports/{id}/download (PDF 다운로드)
# ---------------------------------------------------------------------------


@patch("app.routers.report.PDFReportGenerator")
@patch("app.routers.report.NotionDBClient")
def test_download_report(mock_notion_cls, mock_pdf_cls):
    """PDF 다운로드 API가 PDF 바이트를 스트리밍 응답해야 한다."""
    mock_notion = AsyncMock()
    mock_notion_cls.return_value = mock_notion
    mock_notion.get_page.return_value = _make_notion_report_page(
        "page-1", "AI 개발사업", 85.0, "2026-03-15T10:00:00.000Z"
    )

    # PDF 생성 목 (generate_report는 async, generate_filename은 sync)
    mock_pdf = MagicMock()
    mock_pdf_cls.return_value = mock_pdf
    fake_pdf = b"%PDF-1.4 fake pdf content"
    mock_pdf.generate_report = AsyncMock(return_value=fake_pdf)
    mock_pdf.generate_filename.return_value = "IRIS_보고서_테스트기업_AI개발사업_20260315.pdf"

    response = client.get("/api/v1/reports/page-1/download")

    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert "IRIS_" in response.headers.get("content-disposition", "")
    assert response.content == fake_pdf


@patch("app.routers.report.NotionDBClient")
def test_download_not_found(mock_notion_cls):
    """존재하지 않는 보고서 다운로드 시 404를 반환해야 한다."""
    from app.services.notion_db import NotionAPIError

    mock_notion = AsyncMock()
    mock_notion_cls.return_value = mock_notion
    mock_notion.get_page.side_effect = NotionAPIError(
        message="Not found",
        code="object_not_found",
    )

    response = client.get("/api/v1/reports/nonexistent-id/download")

    assert response.status_code == 404
