#!/usr/bin/env python3
"""
DNS Record Manager
Automates DNS record creation for AutoGit platform services.

Supports:
- Cloudflare (API)
- AWS Route53
- Manual output (for unsupported providers)

Usage:
    python dns-manager.py --provider cloudflare --action create
    python dns-manager.py --provider manual --action list
"""

import os
import sys
import json
import argparse
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import List, Optional
from pathlib import Path

try:
    import requests
except ImportError:
    print("Installing requests...")
    os.system(f"{sys.executable} -m pip install requests")
    import requests


@dataclass
class DNSRecord:
    """DNS record definition"""
    name: str
    type: str
    content: str
    ttl: int = 300
    proxied: bool = False


class DNSProvider(ABC):
    """Abstract base class for DNS providers"""

    @abstractmethod
    def create_record(self, record: DNSRecord) -> bool:
        pass

    @abstractmethod
    def delete_record(self, name: str, type: str) -> bool:
        pass

    @abstractmethod
    def list_records(self) -> List[DNSRecord]:
        pass


class CloudflareProvider(DNSProvider):
    """Cloudflare DNS provider"""

    def __init__(self, zone_id: str, api_token: str):
        self.zone_id = zone_id
        self.api_token = api_token
        self.base_url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records"
        self.headers = {
            "Authorization": f"Bearer {api_token}",
            "Content-Type": "application/json"
        }

    def create_record(self, record: DNSRecord) -> bool:
        data = {
            "type": record.type,
            "name": record.name,
            "content": record.content,
            "ttl": record.ttl,
            "proxied": record.proxied
        }

        response = requests.post(self.base_url, headers=self.headers, json=data)
        result = response.json()

        if result.get("success"):
            print(f"✅ Created: {record.name} → {record.content}")
            return True
        else:
            # Check if record already exists
            errors = result.get("errors", [])
            if any("already exists" in str(e) for e in errors):
                print(f"⏭️  Exists: {record.name}")
                return True
            print(f"❌ Failed: {record.name} - {errors}")
            return False

    def delete_record(self, name: str, type: str) -> bool:
        # First find the record
        params = {"name": name, "type": type}
        response = requests.get(self.base_url, headers=self.headers, params=params)
        result = response.json()

        if not result.get("success") or not result.get("result"):
            print(f"⏭️  Not found: {name}")
            return True

        record_id = result["result"][0]["id"]
        response = requests.delete(f"{self.base_url}/{record_id}", headers=self.headers)

        if response.json().get("success"):
            print(f"✅ Deleted: {name}")
            return True
        return False

    def list_records(self) -> List[DNSRecord]:
        response = requests.get(self.base_url, headers=self.headers)
        result = response.json()

        records = []
        for r in result.get("result", []):
            records.append(DNSRecord(
                name=r["name"],
                type=r["type"],
                content=r["content"],
                ttl=r["ttl"],
                proxied=r.get("proxied", False)
            ))
        return records


class ManualProvider(DNSProvider):
    """Manual provider - outputs required DNS records"""

    def __init__(self, domain: str):
        self.domain = domain
        self.records: List[DNSRecord] = []

    def create_record(self, record: DNSRecord) -> bool:
        self.records.append(record)
        return True

    def delete_record(self, name: str, type: str) -> bool:
        return True

    def list_records(self) -> List[DNSRecord]:
        return self.records

    def output_instructions(self, target_ip: str):
        """Output manual DNS configuration instructions"""
        print("\n" + "=" * 70)
        print("DNS RECORDS REQUIRED")
        print("=" * 70)
        print(f"\nAdd these records to your DNS provider for {self.domain}:\n")

        print("Option 1: Wildcard (recommended)")
        print("-" * 40)
        print(f"  Type: A")
        print(f"  Name: *")
        print(f"  Value: {target_ip}")
        print(f"  TTL: 300")
        print()

        print("Option 2: Individual records")
        print("-" * 40)
        subdomains = ["gitlab", "grafana", "traefik", "api", "loki", "prometheus", "search"]
        for sub in subdomains:
            print(f"  {sub}.{self.domain}  A  {target_ip}  TTL:300")
        print()

        print("For local development (add to /etc/hosts):")
        print("-" * 40)
        for sub in subdomains:
            print(f"  {target_ip}  {sub}.{self.domain}")
        print()


def load_config() -> dict:
    """Load configuration from .env file"""
    config = {
        "BASE_DOMAIN": "vectorweight.com",
        "TARGET_IP": "192.168.1.170",
        "CF_DNS_API_TOKEN": "",
        "CF_ZONE_ID": "",
        "DNS_PROVIDER": "manual"
    }

    # Load from .env if exists
    env_files = [".env", ".env.platform"]
    for env_file in env_files:
        if Path(env_file).exists():
            with open(env_file) as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        key, value = line.split("=", 1)
                        config[key.strip()] = value.strip().strip('"\'')

    # Override from environment
    for key in config:
        if os.environ.get(key):
            config[key] = os.environ[key]

    return config


def get_required_records(domain: str, target_ip: str) -> List[DNSRecord]:
    """Get list of required DNS records for the platform"""
    subdomains = [
        "gitlab",      # Git server
        "grafana",     # Dashboards
        "traefik",     # Ingress dashboard
        "api",         # AutoGit API
        "loki",        # Log aggregation
        "prometheus",  # Metrics
        "search",      # Meilisearch
        "tempo",       # Tracing
    ]

    records = []
    for sub in subdomains:
        records.append(DNSRecord(
            name=f"{sub}.{domain}",
            type="A",
            content=target_ip,
            ttl=300,
            proxied=False
        ))

    return records


def main():
    parser = argparse.ArgumentParser(description="DNS Record Manager for AutoGit Platform")
    parser.add_argument("--provider", choices=["cloudflare", "route53", "manual"],
                       default="manual", help="DNS provider")
    parser.add_argument("--action", choices=["create", "delete", "list", "verify"],
                       default="list", help="Action to perform")
    parser.add_argument("--target-ip", help="Target IP address for DNS records")
    parser.add_argument("--domain", help="Base domain")

    args = parser.parse_args()
    config = load_config()

    domain = args.domain or config.get("BASE_DOMAIN", "vectorweight.com")
    target_ip = args.target_ip or config.get("TARGET_IP", "192.168.1.170")

    print(f"🌐 DNS Manager for {domain}")
    print(f"📍 Target IP: {target_ip}")
    print()

    # Initialize provider
    if args.provider == "cloudflare":
        token = config.get("CF_DNS_API_TOKEN")
        zone_id = config.get("CF_ZONE_ID")

        if not token or not zone_id:
            print("❌ Cloudflare requires CF_DNS_API_TOKEN and CF_ZONE_ID")
            print("   Set these in .env or as environment variables")
            sys.exit(1)

        provider = CloudflareProvider(zone_id, token)
    else:
        provider = ManualProvider(domain)

    # Get required records
    records = get_required_records(domain, target_ip)

    # Perform action
    if args.action == "create":
        print(f"📝 Creating {len(records)} DNS records...")
        for record in records:
            provider.create_record(record)

    elif args.action == "delete":
        print(f"🗑️  Deleting DNS records...")
        for record in records:
            provider.delete_record(record.name, record.type)

    elif args.action == "list":
        if isinstance(provider, ManualProvider):
            provider.records = records
            provider.output_instructions(target_ip)
        else:
            existing = provider.list_records()
            print(f"📋 Found {len(existing)} records:")
            for r in existing:
                print(f"   {r.type:5} {r.name:40} → {r.content}")

    elif args.action == "verify":
        print("🔍 Verifying DNS resolution...")
        import socket
        for record in records:
            try:
                resolved = socket.gethostbyname(record.name)
                if resolved == target_ip:
                    print(f"   ✅ {record.name} → {resolved}")
                else:
                    print(f"   ⚠️  {record.name} → {resolved} (expected {target_ip})")
            except socket.gaierror:
                print(f"   ❌ {record.name} - not resolving")


if __name__ == "__main__":
    main()
