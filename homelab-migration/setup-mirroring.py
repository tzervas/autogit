#!/usr/bin/env python3
"""
GitLab Repository Mirroring Setup
Automatically mirrors repositories from GitHub and GitLab
"""

import os
import sys
import json
import requests
from datetime import datetime
from typing import Dict, List, Optional

class RepositoryMirror:
    def __init__(self, gitlab_url: str, gitlab_token: str):
        self.gitlab_url = gitlab_url.rstrip('/')
        self.gitlab_token = gitlab_token
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {gitlab_token}',
            'Content-Type': 'application/json'
        })

    def api_call(self, method: str, endpoint: str, data: Optional[Dict] = None) -> Dict:
        """Make API call to GitLab"""
        url = f"{self.gitlab_url}/api/v4{endpoint}"
        response = self.session.request(method, url, json=data)
        response.raise_for_status()
        return response.json()

    def get_github_repos(self, github_token: str, username: str) -> List[Dict]:
        """Get all public repositories from GitHub user"""
        headers = {'Authorization': f'token {github_token}'}
        url = f'https://api.github.com/users/{username}/repos'
        params = {'type': 'public', 'sort': 'updated', 'per_page': 100}

        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        return response.json()

    def get_gitlab_repos(self, gitlab_token: str, username: str) -> List[Dict]:
        """Get all repositories from GitLab user"""
        headers = {'Authorization': f'Bearer {gitlab_token}'}
        url = f'https://gitlab.com/api/v4/users/{username}/projects'
        params = {'owned': 'true', 'per_page': 100}

        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        return response.json()

    def create_mirror_project(self, name: str, namespace_id: int, mirror_url: str,
                            mirror_credentials: str, description: str = "") -> Dict:
        """Create a mirrored project in GitLab"""
        data = {
            'name': name,
            'namespace_id': namespace_id,
            'description': description,
            'visibility': 'private',
            'mirror': True,
            'import_url': mirror_url,
            'mirror_trigger_builds': False,
            'only_mirror_protected_branches': False,
            'mirror_overwrites_diverged_branches': True
        }

        # Add mirror credentials if provided
        if mirror_credentials:
            data['mirror_user_id'] = mirror_credentials

        return self.api_call('POST', '/projects', data)

    def setup_mirroring(self, github_token: str, github_username: str,
                       gitlab_token: str, gitlab_username: str, group_id: int):
        """Set up mirroring for all repositories"""

        print("🔄 Setting up repository mirroring...")

        # Get repositories from GitHub
        print(f"📥 Fetching GitHub repositories for {github_username}...")
        github_repos = self.get_github_repos(github_token, github_username)
        print(f"  Found {len(github_repos)} GitHub repositories")

        # Get repositories from GitLab
        print(f"📥 Fetching GitLab repositories for {gitlab_username}...")
        gitlab_repos = self.get_gitlab_repos(gitlab_token, gitlab_username)
        print(f"  Found {len(gitlab_repos)} GitLab repositories")

        # Create mirrors
        mirrors_created = []

        # GitHub mirrors
        print("🔗 Creating GitHub repository mirrors...")
        for repo in github_repos:
            if repo['private']:
                print(f"  ⏭️  Skipping private repo: {repo['name']}")
                continue

            try:
                mirror_url = repo['clone_url']
                description = f"Mirror of {repo['html_url']}\n\n{repo.get('description', '')}"

                project = self.create_mirror_project(
                    name=f"github-{repo['name']}",
                    namespace_id=group_id,
                    mirror_url=mirror_url,
                    mirror_credentials=github_token,
                    description=description
                )

                mirrors_created.append({
                    'type': 'github',
                    'name': repo['name'],
                    'mirror_name': f"github-{repo['name']}",
                    'url': mirror_url,
                    'project_id': project['id']
                })

                print(f"  ✅ Created mirror: github-{repo['name']}")

            except Exception as e:
                print(f"  ❌ Failed to create mirror for {repo['name']}: {e}")

        # GitLab mirrors
        print("🔗 Creating GitLab repository mirrors...")
        for repo in gitlab_repos:
            try:
                mirror_url = repo['http_url_to_repo']
                description = f"Mirror of {repo['web_url']}\n\n{repo.get('description', '')}"

                project = self.create_mirror_project(
                    name=f"gitlab-{repo['name']}",
                    namespace_id=group_id,
                    mirror_url=mirror_url,
                    mirror_credentials=gitlab_token,
                    description=description
                )

                mirrors_created.append({
                    'type': 'gitlab',
                    'name': repo['name'],
                    'mirror_name': f"gitlab-{repo['name']}",
                    'url': mirror_url,
                    'project_id': project['id']
                })

                print(f"  ✅ Created mirror: gitlab-{repo['name']}")

            except Exception as e:
                print(f"  ❌ Failed to create mirror for {repo['name']}: {e}")

        return mirrors_created

def main():
    # Load configuration
    if not os.path.exists('gitlab-fresh-config.json'):
        print("❌ gitlab-fresh-config.json not found. Run configure-gitlab-fresh.py first.")
        sys.exit(1)

    with open('gitlab-fresh-config.json', 'r') as f:
        config = json.load(f)

    # Get tokens from environment or prompt
    github_token = os.getenv('GITHUB_TOKEN')
    gitlab_token = os.getenv('GITLAB_MIRROR_TOKEN')

    if not github_token:
        github_token = input("Enter GitHub personal access token: ").strip()

    if not gitlab_token:
        gitlab_token = input("Enter GitLab personal access token: ").strip()

    # Initialize mirror
    mirror = RepositoryMirror(config['gitlab_url'], config['tokens']['ci_token']['token'])

    # Setup mirroring
    mirrors = mirror.setup_mirroring(
        github_token=github_token,
        github_username='tzervas',
        gitlab_token=gitlab_token,
        gitlab_username='vector_weight',
        group_id=config['groups']['projects']['id']
    )

    # Save mirror configuration
    mirror_config = {
        'mirrors': mirrors,
        'github_username': 'tzervas',
        'gitlab_username': 'vector_weight',
        'last_updated': str(datetime.now())
    }

    with open('repository-mirrors.json', 'w') as f:
        json.dump(mirror_config, f, indent=2)

    print(f"\n✅ Created {len(mirrors)} repository mirrors")
    print("💾 Mirror configuration saved to repository-mirrors.json")

    print("\n📋 Mirror Summary:")
    github_count = len([m for m in mirrors if m['type'] == 'github'])
    gitlab_count = len([m for m in mirrors if m['type'] == 'gitlab'])
    print(f"  GitHub mirrors: {github_count}")
    print(f"  GitLab mirrors: {gitlab_count}")

if __name__ == '__main__':
    main()
