#!/usr/bin/env python3
"""
Fresh GitLab Configuration Script
Sets up users, groups, and tokens for repository mirroring
"""

import os
import sys
import json
import requests
from typing import Dict, List, Optional

class GitLabConfigurator:
    def __init__(self, url: str, token: str):
        self.url = url.rstrip('/')
        self.token = token
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        })

    def api_call(self, method: str, endpoint: str, data: Optional[Dict] = None) -> Dict:
        """Make API call to GitLab"""
        url = f"{self.url}/api/v4{endpoint}"
        response = self.session.request(method, url, json=data)
        response.raise_for_status()
        return response.json()

    def create_user(self, username: str, email: str, name: str, password: str) -> Dict:
        """Create a new user"""
        data = {
            'username': username,
            'email': email,
            'name': name,
            'password': password,
            'skip_confirmation': True
        }
        return self.api_call('POST', '/users', data)

    def create_group(self, name: str, path: str, description: str = "") -> Dict:
        """Create a new group"""
        data = {
            'name': name,
            'path': path,
            'description': description,
            'visibility': 'private'
        }
        return self.api_call('POST', '/groups', data)

    def add_user_to_group(self, user_id: int, group_id: int, access_level: int = 30) -> Dict:
        """Add user to group with specified access level"""
        data = {'user_id': user_id, 'access_level': access_level}
        return self.api_call('POST', f'/groups/{group_id}/members', data)

    def create_personal_access_token(self, user_id: int, name: str, scopes: List[str]) -> Dict:
        """Create a personal access token for a user"""
        data = {
            'name': name,
            'scopes': scopes
        }
        return self.api_call('POST', f'/users/{user_id}/personal_access_tokens', data)

    def create_project(self, name: str, namespace_id: int, description: str = "", visibility: str = 'private') -> Dict:
        """Create a new project"""
        data = {
            'name': name,
            'namespace_id': namespace_id,
            'description': description,
            'visibility': visibility,
            'initialize_with_readme': False
        }
        return self.api_call('POST', '/projects', data)

def main():
    # Configuration
    gitlab_url = os.getenv('GITLAB_URL', 'http://homelab:8080')
    root_token = os.getenv('GITLAB_ROOT_TOKEN')

    if not root_token:
        print("❌ GITLAB_ROOT_TOKEN environment variable required")
        sys.exit(1)

    print(f"🔧 Configuring GitLab at {gitlab_url}")

    # Initialize configurator
    config = GitLabConfigurator(gitlab_url, root_token)

    # Create users
    print("👤 Creating users...")
    users = {}

    # CI User for automated operations
    users['ci_user'] = config.create_user(
        username='ci-user',
        email='ci@homelab.local',
        name='CI User',
        password='ChangeMe123!'  # pragma: allowlist secret - Will be changed after setup
    )
    print(f"  ✅ Created CI user: {users['ci_user']['username']}")

    # Admin user for management
    users['admin_user'] = config.create_user(
        username='admin',
        email='admin@homelab.local',
        name='Administrator',
        password='ChangeMe123!'  # Will be changed after setup
    )
    print(f"  ✅ Created admin user: {users['admin_user']['username']}")

    # Create groups
    print("📁 Creating groups...")
    groups = {}

    # Main projects group
    groups['projects'] = config.create_group(
        name='Projects',
        path='projects',
        description='Mirrored repositories from GitHub and GitLab'
    )
    print(f"  ✅ Created group: {groups['projects']['name']}")

    # Add users to groups
    print("🔗 Adding users to groups...")
    config.add_user_to_group(users['ci_user']['id'], groups['projects']['id'], access_level=40)  # Maintainer
    config.add_user_to_group(users['admin_user']['id'], groups['projects']['id'], access_level=50)  # Owner
    print("  ✅ Added users to groups")

    # Create personal access tokens
    print("🔑 Creating access tokens...")
    tokens = {}

    # CI token for repository operations
    tokens['ci_token'] = config.create_personal_access_token(
        user_id=users['ci_user']['id'],
        name='CI Operations',
        scopes=['api', 'read_repository', 'write_repository']
    )
    print("  ✅ Created CI token")

    # Admin token for management
    tokens['admin_token'] = config.create_personal_access_token(
        user_id=users['admin_user']['id'],
        name='Admin Operations',
        scopes=['api', 'read_user', 'sudo']
    )
    print("  ✅ Created admin token")

    # Save configuration
    config_data = {
        'gitlab_url': gitlab_url,
        'users': {k: {'id': v['id'], 'username': v['username'], 'email': v['email']}
                 for k, v in users.items()},
        'groups': {k: {'id': v['id'], 'name': v['name'], 'path': v['path']}
                  for k, v in groups.items()},
        'tokens': {k: {'token': v['token'], 'name': v['name'], 'scopes': v['scopes']}
                  for k, v in tokens.items()},
        'root_token': root_token  # Save for reference (should be discarded after setup)
    }

    with open('gitlab-fresh-config.json', 'w') as f:
        json.dump(config_data, f, indent=2)

    print("💾 Configuration saved to gitlab-fresh-config.json")

    # Print summary
    print("\n" + "="*50)
    print("🎉 GitLab Configuration Complete!")
    print("="*50)
    print(f"GitLab URL: {gitlab_url}")
    print(f"CI Token: {tokens['ci_token']['token']}")
    print(f"Admin Token: {tokens['admin_token']['token']}")
    print("="*50)
    print("⚠️  IMPORTANT:")
    print("  - Change default passwords for all users")
    print("  - Store tokens securely")
    print("  - Consider revoking root token after setup")
    print("="*50)

if __name__ == '__main__':
    main()
