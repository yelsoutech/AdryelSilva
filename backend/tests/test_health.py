from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "healthy"
    assert body["service"] == "Marketplace Intelligence"
    assert "version" in body
    assert "environment" in body


def test_unauthorized_without_token():
    response = client.get("/api/v1/organizations/current")
    assert response.status_code == 401
    assert response.json()["code"] == "unauthorized"


def test_request_id_header():
    response = client.get("/health")
    assert "x-request-id" in response.headers
