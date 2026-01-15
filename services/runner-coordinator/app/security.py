import logging
import secrets
from typing import Any, Dict

logger = logging.getLogger(__name__)


class SecurityManager:
    """
    Handles secure secret generation and environment variable sanitization.
    """

    @staticmethod
    def generate_runner_token() -> str:
        """
        Generate a secure random token for runner registration.
        """
        return secrets.token_urlsafe(32)

    @staticmethod
    def sanitize_environment(env: Dict[str, str]) -> Dict[str, str]:
        """
        Sanitize environment variables to prevent sensitive data leakage.
        """
        sensitive_keys = ["GITLAB_TOKEN", "AWS_SECRET_ACCESS_KEY", "DATABASE_URL"]
        sanitized = env.copy()
        for key in sensitive_keys:
            if key in sanitized:
                sanitized[key] = "********"
        return sanitized

    @staticmethod
    def get_isolated_network_config(runner_name: str) -> Dict[str, Any]:
        """
        Generate configuration for an isolated Docker network per runner.
        """
        # Placeholder for per-runner network isolation logic
        return {
            "Name": f"net-{runner_name}",
            "Internal": True,
            "Labels": {"autogit-managed": "true"},
        }
