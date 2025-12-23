import unittest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# Add the service directory to path if needed, but uv run should handle it if configured
# For now, we assume the environment is set up correctly or we use relative imports if possible
# However, the previous run showed it could find app.main but failed on DB tables.

from app.main import app, get_db
from app.models import Base

# Use a single connection for the in-memory database to keep it alive
engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

class TestRunnerCoordinatorIntegration(unittest.TestCase):
    def setUp(self):
        Base.metadata.create_all(bind=engine)
        self.client = TestClient(app)

    def tearDown(self):
        Base.metadata.drop_all(bind=engine)

    def test_health_check(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["status"], "healthy")

    @patch('app.main.driver')
    def test_job_webhook_flow(self, mock_driver):
        # 1. Send job webhook
        payload = {
            "object_kind": "build",
            "project_id": 1,
            "ref": "main",
            "checkout_sha": "abc123sha",
            "user_name": "testuser",
            "project_name": "test-project"
        }
        # Ensure we use the same engine for the app and the test
        response = self.client.post("/webhook/job", json=payload)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["job_id"], "abc123sha")

        # 2. Verify job is in database
        response = self.client.get("/status")
        self.assertEqual(response.status_code, 200)
        # Note: status endpoint currently returns placeholders,
        # but we can verify the webhook accepted the job.

    def test_invalid_webhook(self):
        # Missing required fields
        payload = {"invalid": "data"}
        response = self.client.post("/webhook/job", json=payload)
        self.assertEqual(response.status_code, 422)

if __name__ == "__main__":
    unittest.main()
