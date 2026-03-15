# @TASK P1-R1-T1 - Notion DB CRUD 클라이언트
# @SPEC docs/planning/02-trd.md#Notion-DB
"""
Notion API 비동기 CRUD 래퍼.

notion-client 패키지의 AsyncClient 를 감싸서
프로젝트 전반에서 일관된 인터페이스를 제공한다.
"""

from __future__ import annotations

import logging
from typing import Any, Optional, Union

from notion_client import AsyncClient
from notion_client.errors import APIResponseError

logger = logging.getLogger(__name__)


# -------------------------------------------------------------------
# Custom exception
# -------------------------------------------------------------------


class NotionAPIError(Exception):
    """Notion API 호출 실패 시 발생하는 예외.

    원본 에러를 래핑하여 호출부에서 일관되게 처리할 수 있도록 한다.
    """

    def __init__(self, message: str, code: str | None = None, original: Exception | None = None):
        self.code = code
        self.original = original
        super().__init__(message)


# -------------------------------------------------------------------
# Property builder helpers
# -------------------------------------------------------------------


def build_title(text: str) -> dict[str, Any]:
    """Notion Title 속성 빌더."""
    return {"title": [{"text": {"content": text}}]}


def build_rich_text(text: str) -> dict[str, Any]:
    """Notion Rich Text 속성 빌더."""
    return {"rich_text": [{"text": {"content": text}}]}


def build_number(value: int | float) -> dict[str, Any]:
    """Notion Number 속성 빌더."""
    return {"number": value}


def build_select(name: str) -> dict[str, Any]:
    """Notion Select 속성 빌더."""
    return {"select": {"name": name}}


def build_multi_select(names: list[str]) -> dict[str, Any]:
    """Notion Multi-select 속성 빌더."""
    return {"multi_select": [{"name": n} for n in names]}


def build_date(start: str, end: str | None = None) -> dict[str, Any]:
    """Notion Date 속성 빌더."""
    date_obj: dict[str, Any] = {"start": start}
    if end is not None:
        date_obj["end"] = end
    return {"date": date_obj}


def build_url(url: str) -> dict[str, Any]:
    """Notion URL 속성 빌더."""
    return {"url": url}


def build_email(email: str) -> dict[str, Any]:
    """Notion Email 속성 빌더."""
    return {"email": email}


def build_phone(phone: str) -> dict[str, Any]:
    """Notion Phone Number 속성 빌더."""
    return {"phone_number": phone}


def build_relation(page_ids: Union[str, list[str]]) -> dict[str, Any]:
    """Notion Relation 속성 빌더.

    단일 page_id 문자열 또는 page_id 리스트를 받는다.
    """
    if isinstance(page_ids, str):
        page_ids = [page_ids]
    return {"relation": [{"id": pid} for pid in page_ids]}


# -------------------------------------------------------------------
# Property value extractor
# -------------------------------------------------------------------


def extract_property_value(prop: dict[str, Any]) -> Any:
    """Notion property 객체에서 Python 값을 추출한다.

    지원 타입: title, rich_text, number, select, multi_select,
               date, url, email, phone_number, relation
    """
    prop_type = prop.get("type")

    if prop_type == "title":
        items = prop.get("title", [])
        return items[0]["text"]["content"] if items else ""

    if prop_type == "rich_text":
        items = prop.get("rich_text", [])
        return items[0]["text"]["content"] if items else ""

    if prop_type == "number":
        return prop.get("number")

    if prop_type == "select":
        sel = prop.get("select")
        return sel["name"] if sel else None

    if prop_type == "multi_select":
        return [item["name"] for item in prop.get("multi_select", [])]

    if prop_type == "date":
        date_obj = prop.get("date")
        return date_obj["start"] if date_obj else None

    if prop_type == "url":
        return prop.get("url")

    if prop_type == "email":
        return prop.get("email")

    if prop_type == "phone_number":
        return prop.get("phone_number")

    if prop_type == "relation":
        return [item["id"] for item in prop.get("relation", [])]

    # 미지원 타입
    logger.warning("Unsupported Notion property type: %s", prop_type)
    return None


# -------------------------------------------------------------------
# NotionDBClient
# -------------------------------------------------------------------


class NotionDBClient:
    """Notion API 비동기 CRUD 클라이언트.

    Args:
        token: Notion Integration 토큰
    """

    def __init__(self, token: str) -> None:
        self.client = AsyncClient(auth=token)

    # -- Create --

    async def create_page(self, database_id: str, properties: dict[str, Any]) -> dict[str, Any]:
        """Notion 데이터베이스에 새 페이지(행)를 생성한다.

        Args:
            database_id: 대상 데이터베이스 ID
            properties: Notion property 딕셔너리 (build_* 헬퍼로 생성)

        Returns:
            생성된 페이지 객체

        Raises:
            NotionAPIError: API 호출 실패 시
        """
        try:
            return await self.client.pages.create(
                parent={"database_id": database_id},
                properties=properties,
            )
        except APIResponseError as e:
            logger.error("Notion create_page failed: %s (code=%s)", str(e), e.code)
            raise NotionAPIError(
                message=f"Failed to create page: {str(e)}",
                code=e.code,
                original=e,
            ) from e
        except Exception as e:
            logger.error("Unexpected error in create_page: %s", e)
            raise NotionAPIError(
                message=f"Unexpected error: {e}",
                original=e,
            ) from e

    # -- Read (query) --

    async def query_database(
        self,
        database_id: str,
        filter: Optional[dict[str, Any]] = None,
        sorts: Optional[list[dict[str, Any]]] = None,
        page_size: int = 100,
    ) -> list[dict[str, Any]]:
        """Notion 데이터베이스를 쿼리한다.

        자동 페이지네이션으로 모든 결과를 반환한다.

        Args:
            database_id: 대상 데이터베이스 ID
            filter: Notion 필터 객체 (선택)
            sorts: 정렬 조건 리스트 (선택)
            page_size: 한 번에 가져올 페이지 수 (기본 100)

        Returns:
            페이지 객체 리스트

        Raises:
            NotionAPIError: API 호출 실패 시
        """
        try:
            all_results: list[dict[str, Any]] = []
            start_cursor: str | None = None

            while True:
                response = await self.client.databases.query(
                    database_id=database_id,
                    filter=filter,
                    sorts=sorts,
                    start_cursor=start_cursor,
                    page_size=page_size,
                )
                all_results.extend(response.get("results", []))

                if not response.get("has_more", False):
                    break
                start_cursor = response.get("next_cursor")

            return all_results

        except APIResponseError as e:
            logger.error("Notion query_database failed: %s (code=%s)", str(e), e.code)
            raise NotionAPIError(
                message=f"Failed to query database: {str(e)}",
                code=e.code,
                original=e,
            ) from e
        except Exception as e:
            logger.error("Unexpected error in query_database: %s", e)
            raise NotionAPIError(
                message=f"Unexpected error: {e}",
                original=e,
            ) from e

    # -- Read (single page) --

    async def get_page(self, page_id: str) -> dict[str, Any]:
        """단일 페이지를 조회한다.

        Args:
            page_id: 페이지 ID

        Returns:
            페이지 객체

        Raises:
            NotionAPIError: API 호출 실패 시
        """
        try:
            return await self.client.pages.retrieve(page_id=page_id)
        except APIResponseError as e:
            logger.error("Notion get_page failed: %s (code=%s)", str(e), e.code)
            raise NotionAPIError(
                message=f"Failed to get page: {str(e)}",
                code=e.code,
                original=e,
            ) from e
        except Exception as e:
            logger.error("Unexpected error in get_page: %s", e)
            raise NotionAPIError(
                message=f"Unexpected error: {e}",
                original=e,
            ) from e

    # -- Update --

    async def update_page(self, page_id: str, properties: dict[str, Any]) -> dict[str, Any]:
        """페이지의 속성을 업데이트한다.

        Args:
            page_id: 페이지 ID
            properties: 업데이트할 property 딕셔너리

        Returns:
            업데이트된 페이지 객체

        Raises:
            NotionAPIError: API 호출 실패 시
        """
        try:
            return await self.client.pages.update(
                page_id=page_id,
                properties=properties,
            )
        except APIResponseError as e:
            logger.error("Notion update_page failed: %s (code=%s)", str(e), e.code)
            raise NotionAPIError(
                message=f"Failed to update page: {str(e)}",
                code=e.code,
                original=e,
            ) from e
        except Exception as e:
            logger.error("Unexpected error in update_page: %s", e)
            raise NotionAPIError(
                message=f"Unexpected error: {e}",
                original=e,
            ) from e
