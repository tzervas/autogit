import os
import sys
import time
import unittest
from unittest.mock import MagicMock, patch

# Add tools directory to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../tools")))

from gitlab_client import GitLabApiError, GitLabClient


class TestGitServerIntegration(unittest.TestCase):
    """
    Integration tests for Git Server workflows.
    Note: These tests are designed to be run against a live GitLab instance,
    but for this environment, we will mock the network calls while testing
    the logical flow of a full repository lifecycle.
    """

    def setUp(self):
        self.token = "test-token"
        self.base_url = "http://localhost:3000"
        self.client = GitLabClient(base_url=self.base_url, token=self.token)
        self.project_name = f"test-project-{int(time.time())}"

    @patch("requests.request")
    def test_repository_lifecycle(self, mock_request):
        """Test the full lifecycle: Create -> Protect -> Add Webhook -> Delete"""

        # 1. Mock Create Project
        mock_create_resp = MagicMock()
        mock_create_resp.status_code = 201
        mock_create_resp.content = b'{"id": 101, "name": "test-project"}'
        mock_create_resp.json.return_value = {"id": 101, "name": "test-project"}

        # 2. Mock Protect Branch
        mock_protect_resp = MagicMock()
        mock_protect_resp.status_code = 201
        mock_protect_resp.content = b'{"name": "main"}'
        mock_protect_resp.json.return_value = {"name": "main"}

        # 3. Mock Add Webhook
        mock_webhook_resp = MagicMock()
        mock_webhook_resp.status_code = 201
        mock_webhook_resp.content = b'{"id": 1, "url": "http://runner:8080"}'
        mock_webhook_resp.json.return_value = {"id": 1, "url": "http://runner:8080"}

        # 4. Mock Delete Project
        mock_delete_resp = MagicMock()
        mock_delete_resp.status_code = 204
        mock_delete_resp.content = b""
        mock_delete_resp.json.return_value = None

        # Set side effects for sequential calls
        mock_request.side_effect = [
            mock_create_resp,
            mock_protect_resp,
            mock_webhook_resp,
            mock_delete_resp,
        ]

        # Execute Workflow
        # Step 1: Create
        project = self.client.create_project(self.project_name)
        self.assertEqual(project["id"], 101)

        # Step 2: Protect
        protection = self.client.protect_branch(101, "main")
        self.assertEqual(protection["name"], "main")

        # Step 3: Webhook
        webhook = self.client.add_project_webhook(101, "http://runner:8080")
        self.assertEqual(webhook["url"], "http://runner:8080")

        # Step 4: Delete
        self.client.delete_project(101)

        # Verify all calls were made
        self.assertEqual(mock_request.call_count, 4)

        # Verify specific call details
        calls = mock_request.call_args_list
        self.assertEqual(calls[0][0][0], "POST")  # Create
        self.assertIn("projects", calls[0][0][1])

        self.assertEqual(calls[1][0][0], "POST")  # Protect
        self.assertIn("protected_branches", calls[1][0][1])

        self.assertEqual(calls[2][0][0], "POST")  # Webhook
        self.assertIn("hooks", calls[2][0][1])

        self.assertEqual(calls[3][0][0], "DELETE")  # Delete
        self.assertIn("projects/101", calls[3][0][1])

    @patch("requests.request")
    def test_user_ssh_workflow(self, mock_request):
        """Test User SSH key management workflow"""

        # 1. Mock Get Keys
        mock_get_keys = MagicMock()
        mock_get_keys.status_code = 200
        mock_get_keys.content = b"[]"
        mock_get_keys.json.return_value = []

        # 2. Mock Add Key
        mock_add_key = MagicMock()
        mock_add_key.status_code = 201
        mock_add_key.content = b'{"id": 1, "title": "work-laptop"}'
        mock_add_key.json.return_value = {"id": 1, "title": "work-laptop"}

        mock_request.side_effect = [mock_get_keys, mock_add_key]

        # Step 1: Check existing keys
        keys = self.client.get_ssh_keys()
        self.assertEqual(len(keys), 0)

        # Step 2: Add new key
        new_key = self.client.add_ssh_key("work-laptop", "ssh-ed25519 AAAAC3Nza...")
        self.assertEqual(new_key["title"], "work-laptop")


if __name__ == "__main__":
    unittest.main()
