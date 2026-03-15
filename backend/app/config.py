from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # OpenAI
    openai_api_key: str = ""

    # Notion
    notion_api_token: str = ""
    notion_db_company_id: str = ""
    notion_db_announcement_id: str = ""
    notion_db_match_id: str = ""
    notion_db_consult_id: str = ""
    notion_db_report_id: str = ""

    # SMTP
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""

    # IRIS
    iris_base_url: str = "https://www.iris.go.kr"
    scrape_delay: float = 1.0

    class Config:
        env_file = ".env"


settings = Settings()
