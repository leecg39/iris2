# @TASK P0-T0.2 - Health endpoint and schema validation tests
import pytest
from datetime import datetime
from httpx import AsyncClient, ASGITransport

from main import app
from app.models.schemas import (
    CompanyLookupRequest,
    CompanyProfile,
    AnnouncementResponse,
    MatchResultResponse,
    ConsultRequest,
    ReportResponse,
)


@pytest.mark.asyncio
async def test_health_endpoint():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_company_lookup_request_valid():
    req = CompanyLookupRequest(business_number="123-45-67890")
    assert req.business_number == "123-45-67890"


def test_company_lookup_request_too_short():
    with pytest.raises(Exception):
        CompanyLookupRequest(business_number="123")


def test_company_profile_defaults():
    profile = CompanyProfile(
        business_number="1234567890",
        company_name="Test Corp",
        ceo_name="Hong",
        industry="IT",
    )
    assert profile.research_fields == []
    assert profile.tech_keywords == []
    assert profile.revenue is None


def test_announcement_response():
    ann = AnnouncementResponse(
        iris_id="IRIS-001",
        title="AI R&D Support",
        organization="MSIT",
    )
    assert ann.status == "open"
    assert ann.attachments == []


def test_match_result_response_score_range():
    m = MatchResultResponse(
        id="m1",
        match_score=95.5,
        match_reason="High relevance",
        announcement_title="Test",
        announcement_org="MSIT",
    )
    assert 0 <= m.match_score <= 100


def test_match_result_response_invalid_score():
    with pytest.raises(Exception):
        MatchResultResponse(
            id="m1",
            match_score=150,
            match_reason="Invalid",
            announcement_title="Test",
            announcement_org="MSIT",
        )


def test_consult_request_valid():
    req = ConsultRequest(
        company_id="c1",
        announcement_id="a1",
        requester_name="Hong",
        email="hong@test.com",
        phone="010-1234-5678",
    )
    assert req.message is None


def test_report_response():
    r = ReportResponse(
        id="r1",
        announcement_title="Test",
        match_score=80.0,
        created_at=datetime(2026, 1, 1),
    )
    assert r.pdf_url is None
