# @TASK P0-T0.2 - FastAPI application entry point
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import announcement, company, consult, match, report

app = FastAPI(
    title="IRIS 자동 매칭 API",
    description="정부지원사업 자동 매칭 백엔드 서버",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Routers ---
app.include_router(company.router)
app.include_router(announcement.router)
app.include_router(match.router)
app.include_router(consult.router)
app.include_router(report.router)


@app.get("/health")
async def health_check():
    return {"status": "ok"}
