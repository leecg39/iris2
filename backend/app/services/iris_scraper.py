# @TASK P3-R1-T1 - IRIS 공고 스크래퍼 서비스
# @SPEC docs/planning/02-trd.md#IRIS-스크래핑
# @TEST tests/test_iris_scraper.py
"""
IRIS(https://www.iris.go.kr) 정부 R&D 공고 스크래퍼.

httpx.AsyncClient + BeautifulSoup4 기반 비동기 스크래퍼.
robots.txt 준수를 위해 요청 간 딜레이를 적용한다.
"""

from __future__ import annotations

import asyncio
import logging
import re
import time
from typing import Any, Optional

import httpx
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Custom exception
# ---------------------------------------------------------------------------


class ScrapingError(Exception):
    """IRIS 스크래핑 실패 시 발생하는 예외."""

    def __init__(self, message: str, url: str | None = None, original: Exception | None = None):
        self.url = url
        self.original = original
        super().__init__(message)


# ---------------------------------------------------------------------------
# IRISScraper
# ---------------------------------------------------------------------------


class IRISScraper:
    """IRIS(https://www.iris.go.kr) 공고 스크래퍼.

    Args:
        base_url: IRIS 사이트 기본 URL
        delay: 요청 간 딜레이 (초). robots.txt 준수 목적. 기본 1.0초.
    """

    # 목록 페이지 경로
    LIST_PATH = "/usr/bsn/pbs/selectBsnPbsList.do"
    # 상세 페이지 경로
    DETAIL_PATH = "/usr/bsn/pbs/selectBsnPbsDtl.do"

    def __init__(self, base_url: str = "https://www.iris.go.kr", delay: float = 1.0) -> None:
        self.base_url = base_url.rstrip("/")
        self.delay = delay
        self._last_request_time: float = 0.0

    # ---------------------------------------------------------------------------
    # Internal: HTTP fetch with delay
    # ---------------------------------------------------------------------------

    async def _wait_for_delay(self) -> None:
        """이전 요청 이후 delay 초가 경과할 때까지 대기한다."""
        if self.delay <= 0:
            return
        now = time.monotonic()
        elapsed = now - self._last_request_time
        if elapsed < self.delay and self._last_request_time > 0:
            await asyncio.sleep(self.delay - elapsed)

    async def _fetch_page(self, url: str, params: dict[str, Any] | None = None) -> str:
        """URL에서 HTML 페이지를 가져온다.

        Args:
            url: 요청 URL
            params: 쿼리 파라미터

        Returns:
            HTML 문자열

        Raises:
            ScrapingError: HTTP 오류 또는 연결 실패 시
        """
        await self._wait_for_delay()

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.get(url, params=params)
                response.raise_for_status()
                self._last_request_time = time.monotonic()
                return response.text
        except httpx.HTTPStatusError as e:
            logger.error("HTTP error fetching %s: %s", url, e)
            raise ScrapingError(
                message=f"HTTP {e.response.status_code}: {e}",
                url=url,
                original=e,
            ) from e
        except httpx.ConnectError as e:
            logger.error("Connection error fetching %s: %s", url, e)
            raise ScrapingError(
                message=f"Connection failed: {e}",
                url=url,
                original=e,
            ) from e
        except httpx.RequestError as e:
            logger.error("Request error fetching %s: %s", url, e)
            raise ScrapingError(
                message=f"Request failed: {e}",
                url=url,
                original=e,
            ) from e

    # ---------------------------------------------------------------------------
    # Public: 공고 목록 스크래핑
    # ---------------------------------------------------------------------------

    async def scrape_announcement_list(
        self, page: int = 1, keyword: str | None = None
    ) -> list[dict[str, Any]]:
        """IRIS 공고 목록 페이지를 스크래핑한다.

        Args:
            page: 페이지 번호 (1부터 시작)
            keyword: 검색 키워드 (선택)

        Returns:
            공고 목록. 각 항목:
            {iris_id, title, organization, field, deadline, budget, status, detail_url}

        Raises:
            ScrapingError: 스크래핑 실패 시
        """
        await self._wait_for_delay()

        url = f"{self.base_url}{self.LIST_PATH}"
        params: dict[str, Any] = {"pageIndex": page}
        if keyword:
            params["searchKeyword"] = keyword

        try:
            html = await self._fetch_page(url, params=params)
        except (httpx.HTTPStatusError, httpx.ConnectError, httpx.RequestError) as e:
            raise ScrapingError(
                message=str(e),
                url=url,
                original=e,
            ) from e

        self._last_request_time = time.monotonic()
        return self._parse_list_html(html)

    def _parse_list_html(self, html: str) -> list[dict[str, Any]]:
        """목록 HTML을 파싱한다."""
        soup = BeautifulSoup(html, "html.parser")
        table = soup.find("table", class_="board_list")
        if not table:
            return []

        tbody = table.find("tbody")
        if not tbody:
            return []

        results: list[dict[str, Any]] = []
        rows = tbody.find_all("tr")

        for row in rows:
            try:
                title_td = row.find("td", class_="title")
                if not title_td:
                    continue

                link = title_td.find("a")
                if not link:
                    continue

                href = link.get("href", "")
                iris_id = self._extract_iris_id(href)
                title = link.get_text(strip=True)

                org_td = row.find("td", class_="org")
                organization = org_td.get_text(strip=True) if org_td else ""

                field_td = row.find("td", class_="field")
                field = field_td.get_text(strip=True) if field_td else ""

                deadline_td = row.find("td", class_="deadline")
                raw_deadline = deadline_td.get_text(strip=True) if deadline_td else ""
                deadline = self.parse_deadline(raw_deadline)

                budget_td = row.find("td", class_="budget")
                raw_budget = budget_td.get_text(strip=True) if budget_td else ""
                budget = self.parse_budget(raw_budget)

                status_td = row.find("td", class_="status")
                status = self._parse_status(status_td)

                detail_url = f"{self.base_url}{self.DETAIL_PATH}?irisId={iris_id}" if iris_id else ""

                results.append(
                    {
                        "iris_id": iris_id,
                        "title": title,
                        "organization": organization,
                        "field": field,
                        "deadline": deadline,
                        "budget": budget,
                        "status": status,
                        "detail_url": detail_url,
                    }
                )
            except Exception:
                logger.warning("Failed to parse row: %s", row, exc_info=True)
                continue

        return results

    # ---------------------------------------------------------------------------
    # Public: 공고 상세 스크래핑
    # ---------------------------------------------------------------------------

    async def scrape_announcement_detail(self, iris_id: str) -> dict[str, Any]:
        """IRIS 공고 상세 페이지를 스크래핑한다.

        Args:
            iris_id: IRIS 공고 고유 ID

        Returns:
            공고 상세 정보:
            {iris_id, title, organization, field, deadline, budget,
             status, detail_url, content, attachments}

        Raises:
            ScrapingError: 스크래핑 실패 시
        """
        await self._wait_for_delay()

        url = f"{self.base_url}{self.DETAIL_PATH}"
        params = {"irisId": iris_id}

        try:
            html = await self._fetch_page(url, params=params)
        except (httpx.HTTPStatusError, httpx.ConnectError, httpx.RequestError) as e:
            raise ScrapingError(
                message=str(e),
                url=url,
                original=e,
            ) from e

        self._last_request_time = time.monotonic()
        return self._parse_detail_html(html, iris_id)

    def _parse_detail_html(self, html: str, iris_id: str) -> dict[str, Any]:
        """상세 HTML을 파싱한다."""
        soup = BeautifulSoup(html, "html.parser")

        view_cont = soup.find("div", class_="view_cont")
        if not view_cont:
            return {
                "iris_id": iris_id,
                "title": "",
                "organization": "",
                "field": "",
                "deadline": None,
                "budget": "",
                "status": "",
                "detail_url": f"{self.base_url}{self.DETAIL_PATH}?irisId={iris_id}",
                "content": "",
                "attachments": [],
            }

        # 제목
        title_tag = view_cont.find("h3", class_="tit")
        title = title_tag.get_text(strip=True) if title_tag else ""

        # 테이블에서 상세 정보 추출
        org = self._extract_table_value(view_cont, "org")
        field = self._extract_table_value(view_cont, "field")
        raw_deadline = self._extract_table_value(view_cont, "deadline")
        raw_budget = self._extract_table_value(view_cont, "budget")
        status = self._extract_table_value(view_cont, "status")

        # 본문 내용
        content_div = view_cont.find("div", class_="content")
        content = content_div.get_text(separator="\n", strip=True) if content_div else ""

        # 첨부파일
        attachments: list[str] = []
        attach_div = view_cont.find("div", class_="attach_list")
        if attach_div:
            for link in attach_div.find_all("a"):
                href = link.get("href", "")
                if href:
                    full_url = f"{self.base_url}{href}" if href.startswith("/") else href
                    attachments.append(full_url)

        return {
            "iris_id": iris_id,
            "title": title,
            "organization": org,
            "field": field,
            "deadline": self.parse_deadline(raw_deadline),
            "budget": self.parse_budget(raw_budget),
            "status": status,
            "detail_url": f"{self.base_url}{self.DETAIL_PATH}?irisId={iris_id}",
            "content": content,
            "attachments": attachments,
        }

    # ---------------------------------------------------------------------------
    # Public: Notion DB 저장
    # ---------------------------------------------------------------------------

    async def save_announcements_to_notion(
        self,
        announcements: list[dict[str, Any]],
        notion_client: Any,
        db_id: str,
    ) -> int:
        """스크래핑 결과를 Notion DB에 저장한다.

        Args:
            announcements: 공고 목록 (scrape_announcement_list/detail 반환값)
            notion_client: NotionDBClient 인스턴스
            db_id: Notion 데이터베이스 ID

        Returns:
            저장된 공고 수
        """
        from app.services.notion_db import (
            build_date,
            build_rich_text,
            build_select,
            build_title,
            build_url,
        )

        saved_count = 0

        for ann in announcements:
            try:
                properties: dict[str, Any] = {
                    "제목": build_title(ann.get("title", "")),
                    "IRIS ID": build_rich_text(ann.get("iris_id", "")),
                    "주관기관": build_rich_text(ann.get("organization", "")),
                    "분야": build_rich_text(ann.get("field", "")),
                    "지원규모": build_rich_text(ann.get("budget", "")),
                    "상태": build_select(ann.get("status", "진행중")),
                }

                if ann.get("deadline"):
                    properties["마감일"] = build_date(ann["deadline"])

                if ann.get("detail_url"):
                    properties["상세URL"] = build_url(ann["detail_url"])

                await notion_client.create_page(
                    database_id=db_id,
                    properties=properties,
                )
                saved_count += 1
                logger.info("Saved announcement to Notion: %s", ann.get("iris_id"))

            except Exception:
                logger.error(
                    "Failed to save announcement %s to Notion",
                    ann.get("iris_id"),
                    exc_info=True,
                )

        return saved_count

    # ---------------------------------------------------------------------------
    # Parse helpers
    # ---------------------------------------------------------------------------

    @staticmethod
    def parse_deadline(raw: str) -> str | None:
        """다양한 형식의 마감일 문자열을 YYYY-MM-DD로 파싱한다.

        지원 형식:
        - YYYY-MM-DD
        - YYYY.MM.DD
        - YYYY년 MM월 DD일

        Args:
            raw: 원본 마감일 문자열

        Returns:
            YYYY-MM-DD 형식 문자열 또는 파싱 실패 시 None
        """
        if not raw or not raw.strip():
            return None

        raw = raw.strip()

        # YYYY-MM-DD
        match = re.match(r"(\d{4})-(\d{1,2})-(\d{1,2})", raw)
        if match:
            return f"{match.group(1)}-{match.group(2).zfill(2)}-{match.group(3).zfill(2)}"

        # YYYY.MM.DD
        match = re.match(r"(\d{4})\.(\d{1,2})\.(\d{1,2})", raw)
        if match:
            return f"{match.group(1)}-{match.group(2).zfill(2)}-{match.group(3).zfill(2)}"

        # YYYY년 MM월 DD일
        match = re.match(r"(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일", raw)
        if match:
            return f"{match.group(1)}-{match.group(2).zfill(2)}-{match.group(3).zfill(2)}"

        logger.debug("Cannot parse deadline: %s", raw)
        return None

    @staticmethod
    def parse_budget(raw: str) -> str:
        """예산 문자열에서 핵심 금액을 추출한다.

        Args:
            raw: 원본 예산 문자열

        Returns:
            정규화된 예산 문자열. 파싱 실패 시 원본 반환.
        """
        if not raw or not raw.strip():
            return ""

        raw = raw.strip()

        # "N억원" 또는 "N만원" 패턴 추출
        match = re.search(r"(\d[\d,]*)\s*(억원|만원)", raw)
        if match:
            amount = match.group(1).replace(",", "")
            unit = match.group(2)
            return f"{amount}{unit}"

        return raw

    # ---------------------------------------------------------------------------
    # Internal helpers
    # ---------------------------------------------------------------------------

    @staticmethod
    def _extract_iris_id(href: str) -> str:
        """URL에서 irisId 파라미터를 추출한다."""
        match = re.search(r"irisId=([A-Za-z0-9\-]+)", href)
        return match.group(1) if match else ""

    @staticmethod
    def _parse_status(td: Any) -> str:
        """상태 셀에서 상태 텍스트를 추출한다."""
        if not td:
            return ""
        # <span class="ing">진행중</span> 또는 <span class="end">마감</span>
        span = td.find("span")
        if span:
            return span.get_text(strip=True)
        return td.get_text(strip=True)

    @staticmethod
    def _extract_table_value(container: Any, css_class: str) -> str:
        """view_table에서 특정 클래스의 td 값을 추출한다."""
        td = container.find("td", class_=css_class)
        return td.get_text(strip=True) if td else ""
