import unittest
from unittest.mock import patch, MagicMock
import os
import sys

# Add tools directory to path to import GitLabClient
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../tools')))

from gitlab_client import GitLabClient, GitLabApiError

class TestGitLabClient(unittest.TestCase):
    def setUp(self):
        self.token = "test-token"
        self.base_url = "http://gitlab.example.com"
        self.client = GitLabClient(base_url=self.base_url, token=self.token)

    @patch('requests.request')
    def test_request_success(self, mock_request):
        # Mock successful response
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.content = b'{"id": 1, "name": "test-project"}'
        mock_response.json.return_value = {"id": 1, "name": "test-project"}
        mock_request.return_value = mock_response

        result = self.client._request("GET", "projects")

        self.assertEqual(result, {"id": 1, "name": "test-project"})
        mock_request.assert_called_once_with(
            "GET",
            f"{self.base_url}/api/v4/projects",
            headers=self.client.headers,
            json=None,
            params=None,
            timeout=10
        )

    @patch('requests.request')
    def test_request_error(self, mock_request):
        # Mock error response
        mock_response = MagicMock()
        mock_response.status_code = 404
        mock_response.text = "Not Found"
        mock_response.json.return_value = {"message": "Project not found"}
        mock_request.return_value = mock_response

        with self.assertRaises(GitLabApiError) as cm:
            self.client._request("GET", "projects/999")

        self.assertEqual(cm.exception.status_code, 404)
        self.assertIn("Project not found", cm.exception.message)

    @patch('requests.request')
    def test_get_users(self, mock_request):
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.content = b'[{"id": 1, "username": "admin"}]'
        mock_response.json.return_value = [{"id": 1, "username": "admin"}]
        mock_request.return_value = mock_response

        result = self.client.get_users()
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["username"], "admin")

    @patch('requests.request')
    def test_create_project(self, mock_request):
        mock_response = MagicMock()
        mock_response.status_code = 201
        mock_response.content = b'{"id": 1, "name": "New Project"}'
        mock_response.json.return_value = {"id": 1, "name": "New Project"}
        mock_request.return_value = mock_response

        result = self.client.create_project("New Project")
        self.assertEqual(result["name"], "New Project")

        # Check if path was auto-generated
        args, kwargs = mock_request.call_args
        self.assertEqual(kwargs['json']['path'], "new-project")

    @patch('requests.request')
    def test_protect_branch(self, mock_request):
        mock_response = MagicMock()
        mock_response.status_code = 201
        mock_response.content = b'{"name": "main"}'
        mock_response.json.return_value = {"name": "main"}
        mock_request.return_value = mock_response

        result = self.client.protect_branch(1, "main")
        self.assertEqual(result["name"], "main")

        args, kwargs = mock_request.call_args
        self.assertEqual(kwargs['json']['name'], "main")
        self.assertEqual(kwargs['json']['push_access_level'], 40)

    @patch('requests.request')
    def test_unprotect_branch_encoding(self, mock_request):
        mock_response = MagicMock()
        mock_response.status_code = 204
        mock_response.content = b''
        mock_request.return_value = mock_response

        self.client.unprotect_branch(1, "feature/test")

        args, kwargs = mock_request.call_args
        # Check if branch name was URL encoded
        self.assertIn("feature%2Ftest", args[1])

if __name__ == '__main__':
    unittest.main()
