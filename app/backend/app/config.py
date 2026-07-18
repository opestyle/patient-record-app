import os
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

APP_ENV = os.getenv("APP_ENV", "dev")

_database_url = os.getenv("DATABASE_URL")
if not _database_url:
    if APP_ENV != "dev":
        raise RuntimeError("DATABASE_URL must be set when APP_ENV is not 'dev'")
    _database_url = f"sqlite:///{BASE_DIR / 'patient.db'}"
DATABASE_URL = _database_url

S3_BUCKET = os.getenv("S3_BUCKET")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")

_secret_key = os.getenv("SECRET_KEY")
if not _secret_key:
    if APP_ENV != "dev":
        raise RuntimeError("SECRET_KEY must be set when APP_ENV is not 'dev'")
    _secret_key = "dev-only-insecure-secret-key"
SECRET_KEY = _secret_key

ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

# Optional: if set, an admin user is created at startup (once) with these
# credentials. Leave unset after the first login and rotate the password
# through a real user-management flow once one exists.
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD")
