# @TASK P0-T0.2 - Pydantic request/response schemas
# @SPEC docs/planning/02-trd.md

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field


# --- Company ---

class CompanyLookupRequest(BaseModel):
    """사업자번호로 기업 정보 조회 요청."""

    business_number: str = Field(
        ...,
        min_length=10,
        max_length=12,
        description="사업자등록번호 (10자리, 하이픈 포함 가능)",
        examples=["123-45-67890"],
    )


class CompanyProfile(BaseModel):
    """기업 프로필 응답."""

    business_number: str
    company_name: str
    ceo_name: str
    industry: str
    revenue: Optional[int] = Field(None, description="매출액 (원)")
    employee_count: Optional[int] = Field(None, description="종업원 수")
    address: Optional[str] = None
    research_fields: list[str] = Field(default_factory=list, description="연구 분야")
    tech_keywords: list[str] = Field(default_factory=list, description="기술 키워드")


class CompanyProfileUpdate(BaseModel):
    """기업 프로필 업데이트 요청."""

    business_number: str = Field(
        ...,
        min_length=10,
        max_length=12,
        description="사업자등록번호 (10자리, 하이픈 포함 가능)",
        examples=["123-45-67890"],
    )
    research_fields: Optional[list] = Field(
        None, description="연구 분야 (None이면 변경 안 함)"
    )
    tech_keywords: Optional[list] = Field(
        None, description="기술 키워드 (None이면 변경 안 함)"
    )


# --- Announcement ---

class AnnouncementResponse(BaseModel):
    """공고 정보 응답."""

    iris_id: str = Field(..., description="IRIS 공고 고유 ID")
    title: str
    organization: str = Field(..., description="주관기관")
    field: Optional[str] = Field(None, description="지원 분야")
    deadline: Optional[str] = Field(None, description="마감일 (YYYY-MM-DD)")
    budget: Optional[str] = Field(None, description="지원 예산")
    status: str = Field("open", description="공고 상태 (open/closed)")
    detail_url: Optional[str] = None
    ai_summary: Optional[str] = Field(None, description="AI 요약")
    attachments: list[str] = Field(default_factory=list, description="첨부파일 URL 목록")


# --- Match ---

class MatchResultResponse(BaseModel):
    """매칭 결과 응답."""

    id: str
    match_score: float = Field(..., ge=0, le=100, description="매칭 점수 (0-100)")
    match_reason: str = Field(..., description="매칭 사유")
    announcement_title: str
    announcement_org: str = Field(..., description="주관기관")
    announcement_deadline: Optional[str] = None
    report_url: Optional[str] = Field(None, description="리포트 PDF URL")


class AnnouncementListResponse(BaseModel):
    """공고 목록 페이지네이션 응답."""

    items: list[AnnouncementResponse]
    total: int
    page: int
    page_size: int


# --- Match ---


class MatchAnalyzeRequest(BaseModel):
    """매칭 분석 요청."""

    business_number: str = Field(
        ...,
        min_length=10,
        max_length=12,
        description="사업자등록번호 (10자리, 하이픈 포함 가능)",
        examples=["123-45-67890"],
    )


class MatchAnalyzeResponse(BaseModel):
    """매칭 분석 결과 응답."""

    results: list[MatchResultResponse]


class MatchResultListResponse(BaseModel):
    """매칭 결과 목록 페이지네이션 응답."""

    items: list[MatchResultResponse]
    total: int
    page: int
    page_size: int


# --- Consult ---

class ConsultRequest(BaseModel):
    """컨설팅 신청 요청."""

    company_id: str
    announcement_id: str
    requester_name: str = Field(..., min_length=1, max_length=50)
    email: EmailStr
    phone: str = Field(
        ...,
        pattern=r"^01[016789]-?\d{3,4}-?\d{4}$",
        description="휴대폰 번호",
    )
    message: Optional[str] = Field(None, max_length=1000)


class ConsultSubmitRequest(BaseModel):
    """상담 신청 요청 (POST /api/v1/consultation/submit)."""

    company_id: str = Field(..., description="기업 페이지 ID")
    announcement_id: str = Field(..., description="공고 페이지 ID")
    requester_name: str = Field(..., min_length=1, max_length=50, description="신청자 이름")
    email: EmailStr = Field(..., description="신청자 이메일")
    phone: str = Field(
        ...,
        pattern=r"^01[016789]-?\d{3,4}-?\d{4}$",
        description="휴대폰 번호",
    )
    message: str = Field(..., max_length=1000, description="상담 요청 메시지")


class ConsultSubmitResponse(BaseModel):
    """상담 신청 응답."""

    id: str = Field(..., description="생성된 상담 페이지 ID")
    status: str = Field(default="접수", description="신청 상태")
    email_sent: bool = Field(..., description="확인 이메일 발송 여부")


# --- Report ---

class ReportResponse(BaseModel):
    """리포트 응답."""

    id: str
    announcement_title: str
    match_score: float = Field(..., ge=0, le=100)
    pdf_url: Optional[str] = None
    created_at: datetime


class ReportListResponse(BaseModel):
    """리포트 목록 페이지네이션 응답."""

    items: list[ReportResponse]
    total: int
    page: int
    page_size: int
