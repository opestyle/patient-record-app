import os
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

_TEST_DB_PATH = Path(tempfile.gettempdir()) / "patient_app_test.db"
_TEST_DB_PATH.unlink(missing_ok=True)

os.environ["DATABASE_URL"] = f"sqlite:///{_TEST_DB_PATH}"
os.environ["ADMIN_EMAIL"] = "admin@example.com"
os.environ["ADMIN_PASSWORD"] = "test-only-password-123"

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_check() -> None:
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_list_patients_requires_auth() -> None:
    response = client.get("/api/patients")
    assert response.status_code == 401


def test_login_and_list_patients() -> None:
    with TestClient(app) as authed_client:
        login_response = authed_client.post(
            "/api/auth/login",
            data={"username": "admin@example.com", "password": "test-only-password-123"},
        )
        assert login_response.status_code == 200
        token = login_response.json()["access_token"]

        response = authed_client.get(
            "/api/patients", headers={"Authorization": f"Bearer {token}"}
        )
        assert response.status_code == 200


def test_login_with_wrong_password_rejected() -> None:
    with TestClient(app) as authed_client:
        response = authed_client.post(
            "/api/auth/login",
            data={"username": "admin@example.com", "password": "wrong-password"},
        )
        assert response.status_code == 401
