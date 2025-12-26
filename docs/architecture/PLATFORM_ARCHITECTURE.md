# AutoGit Platform Architecture

# Comprehensive Self-Hosted GitOps Solution

# Version 2.0 - Full Stack Design

# ═══════════════════════════════════════════════════════════════════════════════

## Vision Statement

A **one-touch, self-healing, fully automated** GitOps platform that provides:

- Self-hosted Git (GitLab CE) with full-depth repository mirroring
- Automated DNS, SSL, and ingress management
- Lifecycle-managed compute runners (CPU + GPU)
- Comprehensive observability with semantic search
- Security-first design with prompt injection protection
- Infrastructure as Code for any environment
- Extensible Python API with OpenAPI specification

______________________________________________________________________

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET / LAN                                         │
│                                    │                                                │
│                            ┌───────▼───────┐                                        │
│                            │   DNS Server   │ (Cloudflare / Local BIND)            │
│                            │ *.vectorweight │                                       │
│                            └───────┬───────┘                                        │
│                                    │                                                │
│  ┌─────────────────────────────────▼─────────────────────────────────────────────┐  │
│  │                         INGRESS LAYER (Traefik/Nginx)                         │  │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐  │  │
│  │  │ • Wildcard SSL (*.vectorweight.com) via Let's Encrypt                   │  │  │
│  │  │ • Subdomain → Service routing                                            │  │  │
│  │  │ • Prompt Injection Filter (middleware)                                   │  │  │
│  │  │ • Rate limiting, WAF rules                                               │  │  │
│  │  └─────────────────────────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────┬─────────────────────────────────────────────┘  │
│                                    │                                                │
│  ┌─────────────────────────────────▼─────────────────────────────────────────────┐  │
│  │                         SERVICE MESH (Docker Network)                         │  │
│  │                                                                               │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │  │
│  │  │   GitLab    │  │   Grafana   │  │    Loki     │  │   Tempo     │         │  │
│  │  │   :8080     │  │   :3000     │  │   :3100     │  │   :3200     │         │  │
│  │  │ gitlab.*    │  │ grafana.*   │  │ loki.*      │  │ tempo.*     │         │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘         │  │
│  │                                                                               │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │  │
│  │  │  Promtail   │  │ Prometheus  │  │  Meilisearch│  │  AutoGit    │         │  │
│  │  │  (logs)     │  │  (metrics)  │  │  (semantic) │  │   API       │         │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘         │  │
│  │                                                                               │  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                     │
│  ┌───────────────────────────────────────────────────────────────────────────────┐  │
│  │                         GPU COMPUTE LAYER                                     │  │
│  │  ┌─────────────────────┐  ┌─────────────────────┐                            │  │
│  │  │ Desktop 1 (3090Ti)  │  │ Desktop 2 (5080)    │                            │  │
│  │  │ • GPU Runner        │  │ • GPU Runner        │                            │  │
│  │  │ • Inference jobs    │  │ • Render jobs       │                            │  │
│  │  └─────────────────────┘  └─────────────────────┘                            │  │
│  └───────────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

______________________________________________________________________

## Component Specifications

### 1. Service Registry & Discovery

All services register via environment-driven configuration:

```yaml
# .env - Single source of truth
BASE_DOMAIN=vectorweight.com
ACME_EMAIL=admin@vectorweight.com

# Service definitions (auto-discovered)
SERVICES_ENABLED=gitlab,grafana,loki,tempo,prometheus,meilisearch,api

# Dynamic port allocation (or explicit)
PORT_ALLOCATION=dynamic  # auto-assign from pool
# PORT_GITLAB=8080       # or explicit override
```

**Service Discovery Protocol:**

```json
{
  "service": "gitlab",
  "subdomain": "gitlab",
  "internal_port": 80,
  "external_port": 8080,
  "health_endpoint": "/-/health",
  "ready_endpoint": "/-/readiness",
  "labels": ["git", "ci", "registry"]
}
```

### 2. DNS Automation

**Supported Providers:**

- Cloudflare (API-driven)
- AWS Route53
- Google Cloud DNS
- Local BIND/dnsmasq (homelab)
- Manual (outputs required records)

**Auto-generated Records:**

```
# A Records (pointing to ingress)
*.vectorweight.com     → 192.168.1.170

# Or per-service (if no wildcard)
gitlab.vectorweight.com   → 192.168.1.170
grafana.vectorweight.com  → 192.168.1.170
api.vectorweight.com      → 192.168.1.170
```

**Implementation:**

```python
# autogit/dns/providers/cloudflare.py
class CloudflareDNSProvider(DNSProvider):
    def create_record(self, name: str, type: str, content: str) -> DNSRecord: ...

    def ensure_wildcard(self, domain: str, target: str) -> None:
        """Create *.domain pointing to target"""
        ...
```

### 3. SSL/TLS Automation

**Certificate Strategy:**

- Wildcard certificate: `*.vectorweight.com`
- Auto-renewal via ACME (Let's Encrypt)
- DNS-01 challenge (works for internal services)
- Fallback to HTTP-01 for public services

**Implementation:**

```yaml
# Traefik configuration
certificatesResolvers:
  letsencrypt:
    acme:
      email: ${ACME_EMAIL}
      storage: /acme/acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
```

### 4. Ingress Layer

**Option A: Traefik (Recommended)**

- Native Docker integration
- Auto-discovery via labels
- Built-in Let's Encrypt
- Middleware support (for prompt injection filter)

**Option B: Nginx + Certbot**

- More manual but familiar
- Template-based configuration
- Separate renewal cron

**Routing Rules:**

```yaml
# Traefik dynamic config (auto-generated from .env)
http:
  routers:
    gitlab:
      rule: "Host(`gitlab.${BASE_DOMAIN}`)"
      service: gitlab
      tls:
        certResolver: letsencrypt
      middlewares:
        - security-headers
        - prompt-injection-filter

  middlewares:
    prompt-injection-filter:
      plugin:
        autogit-security:
          enabled: true
          quarantine_path: /var/log/autogit/quarantine
```

### 5. Prompt Injection Protection Module

**Threat Vectors:**

- Hidden text (zero-width chars, white-on-white)
- Unicode tricks (homoglyphs, RTL override)
- Markdown/HTML injection
- Base64/encoded payloads
- Instruction injection patterns

**Architecture:**

```python
# autogit/security/prompt_filter.py
class PromptInjectionFilter:
    """
    Multi-stage filter for detecting and quarantining potential prompt injections.

    Stage 1: Unicode normalization & hidden char detection
    Stage 2: Pattern matching (known injection patterns)
    Stage 3: Structural analysis (unexpected instruction blocks)
    Stage 4: ML-based classification (optional, for high-security)
    """

    def analyze(self, text: str) -> FilterResult:
        """
        Returns:
        - clean_text: Sanitized version
        - quarantined: Suspicious fragments
        - risk_score: 0.0-1.0
        - detected_patterns: List of what was found
        """
        ...

    def quarantine(self, fragment: str, metadata: dict) -> str:
        """Store suspicious content for analysis"""
        ...
```

**Quarantine Storage:**

```json
{
  "id": "q-20251226-001",
  "timestamp": "2025-12-26T21:30:00Z",
  "source": "api-request",
  "original_text": "...",
  "detected_patterns": ["zero_width_space", "instruction_prefix"],
  "risk_score": 0.85,
  "sanitized_text": "...",
  "analysis_status": "pending"
}
```

### 6. Observability Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                    OBSERVABILITY ARCHITECTURE                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  COLLECTION           STORAGE            QUERY/VISUALIZE        │
│  ───────────         ────────           ─────────────────       │
│                                                                 │
│  ┌─────────┐        ┌─────────┐        ┌─────────────────┐     │
│  │Promtail │───────►│  Loki   │───────►│                 │     │
│  │ (logs)  │        │         │        │                 │     │
│  └─────────┘        └─────────┘        │                 │     │
│                                        │                 │     │
│  ┌─────────┐        ┌─────────┐        │    Grafana      │     │
│  │ OTEL    │───────►│  Tempo  │───────►│                 │     │
│  │(traces) │        │         │        │   Dashboards    │     │
│  └─────────┘        └─────────┘        │                 │     │
│                                        │                 │     │
│  ┌─────────┐        ┌─────────┐        │                 │     │
│  │ Prom    │───────►│Prometheus───────►│                 │     │
│  │exporters│        │         │        │                 │     │
│  └─────────┘        └─────────┘        └─────────────────┘     │
│                                                                 │
│  SEMANTIC SEARCH                                                │
│  ───────────────                                                │
│  ┌─────────┐        ┌───────────┐      ┌─────────────────┐     │
│  │ Log     │───────►│Meilisearch│◄────►│  AutoGit API    │     │
│  │Enricher │        │           │      │  /search/logs   │     │
│  └─────────┘        └───────────┘      └─────────────────┘     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Log Enrichment Pipeline:**

```python
# autogit/observability/enricher.py
class LogEnricher:
    """
    Enriches log entries with:
    - Semantic embeddings (for search)
    - Entity extraction (IPs, URLs, errors)
    - Correlation IDs
    - Risk scoring
    """

    async def enrich(self, log_entry: LogEntry) -> EnrichedLog:
        return EnrichedLog(
            original=log_entry,
            embedding=await self.embed(log_entry.message),
            entities=self.extract_entities(log_entry.message),
            correlation_id=self.correlate(log_entry),
            risk_score=self.assess_risk(log_entry),
        )
```

### 7. Python API Architecture

**Framework:** FastAPI with OpenAPI 3.1 specification

**Provider/Consumer Pattern:**

```python
# autogit/api/providers/base.py
class Provider(ABC):
    """Base class for all service providers"""

    @abstractmethod
    async def health(self) -> HealthStatus: ...

    @abstractmethod
    async def configure(self, config: ProviderConfig) -> None: ...


# autogit/api/providers/dns/cloudflare.py
class CloudflareProvider(DNSProvider):
    """Cloudflare DNS provider implementation"""

    provider_type = "dns"
    provider_name = "cloudflare"

    async def create_record(self, record: DNSRecord) -> DNSRecord: ...


# autogit/api/connectors/gitlab.py
class GitLabConnector(Connector):
    """Connector for GitLab operations"""

    async def mirror_repository(self, source: str, dest: str) -> MirrorResult: ...
```

**OpenAPI Specification:**

```yaml
openapi: 3.1.0
info:
  title: AutoGit Platform API
  version: 1.0.0
  description: Self-hosted GitOps platform API

paths:
  /api/v1/services:
    get:
      summary: List all services
      responses:
        '200':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ServiceList'

  /api/v1/services/{service}/deploy:
    post:
      summary: Deploy or update a service
      parameters:
        - name: service
          in: path
          required: true
          schema:
            type: string
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/DeployRequest'

  /api/v1/dns/records:
    post:
      summary: Create DNS record
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/DNSRecord'

  /api/v1/security/analyze:
    post:
      summary: Analyze text for prompt injection
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/AnalyzeRequest'
      responses:
        '200':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AnalyzeResult'

  /api/v1/search/logs:
    get:
      summary: Semantic search across logs
      parameters:
        - name: q
          in: query
          required: true
          schema:
            type: string
        - name: timeRange
          in: query
          schema:
            type: string

components:
  schemas:
    ServiceList:
      type: array
      items:
        $ref: '#/components/schemas/Service'

    Service:
      type: object
      properties:
        name:
          type: string
        subdomain:
          type: string
        status:
          type: string
          enum: [healthy, degraded, unhealthy, unknown]
        ports:
          type: object
          properties:
            internal:
              type: integer
            external:
              type: integer
```

______________________________________________________________________

## Extension Framework

**Plugin Architecture:**

```python
# autogit/extensions/base.py
class Extension(ABC):
    """Base class for AutoGit extensions"""

    name: str
    version: str
    dependencies: List[str] = []

    @abstractmethod
    async def initialize(self, ctx: ExtensionContext) -> None: ...

    @abstractmethod
    async def shutdown(self) -> None: ...


# Example: Custom DNS provider
# autogit/extensions/dns_custom.py
class CustomDNSExtension(Extension):
    name = "custom-dns"
    version = "1.0.0"

    async def initialize(self, ctx: ExtensionContext) -> None:
        ctx.register_provider(
            provider_type="dns",
            provider_class=MyCustomDNSProvider,
        )
```

**Supported Provider Types:**

- `dns` - DNS record management
- `ssl` - Certificate management
- `storage` - Artifact/backup storage
- `notify` - Notifications (Slack, Discord, etc.)
- `auth` - Authentication providers (LDAP, OIDC)
- `compute` - GPU/CPU compute providers

______________________________________________________________________

## Infrastructure as Code

**Output Formats:**

- Docker Compose (current)
- Kubernetes manifests
- Terraform modules
- Pulumi programs
- Ansible playbooks

**IaC Generation:**

```python
# autogit/iac/generator.py
class IaCGenerator:
    """Generate Infrastructure as Code from running configuration"""

    async def capture(self) -> PlatformState:
        """Capture current platform state"""
        return PlatformState(
            services=await self.discover_services(),
            dns_records=await self.get_dns_records(),
            certificates=await self.get_certificates(),
            volumes=await self.get_volumes(),
        )

    def generate(self, state: PlatformState, format: str) -> str:
        """Generate IaC in specified format"""
        generator = self.generators[format]
        return generator.render(state)
```

______________________________________________________________________

## Implementation Phases

### Phase 1: Shell Foundation (Current)

- [x] GitLab deployment
- [x] Port conflict resolution
- [x] Resource right-sizing
- [x] Credential management
- [ ] DNS record documentation
- [ ] Basic SSL setup

### Phase 2: Ingress & SSL

- [ ] Traefik deployment
- [ ] Wildcard certificate automation
- [ ] Subdomain routing
- [ ] Service discovery via labels

### Phase 3: Observability

- [ ] Loki + Promtail (logs)
- [ ] Tempo (traces)
- [ ] Prometheus (metrics)
- [ ] Grafana dashboards
- [ ] Meilisearch (semantic search)

### Phase 4: Python Consolidation

- [ ] FastAPI scaffolding
- [ ] OpenAPI specification
- [ ] Provider framework
- [ ] Migrate shell scripts

### Phase 5: Security

- [ ] Prompt injection filter
- [ ] Quarantine system
- [ ] Security dashboards
- [ ] Audit logging

### Phase 6: IaC Export

- [ ] State capture
- [ ] Multi-format generation
- [ ] Cloud provider support

______________________________________________________________________

## File Structure

```
autogit/
├── docker-compose.yml              # Main orchestration
├── .env.example                    # Configuration template
├── traefik/
│   ├── traefik.yml                 # Static config
│   ├── dynamic/                    # Dynamic configs (auto-generated)
│   └── acme/                       # Certificate storage
├── observability/
│   ├── docker-compose.yml          # Observability stack
│   ├── loki/
│   ├── tempo/
│   ├── prometheus/
│   └── grafana/
│       └── dashboards/
├── src/
│   └── autogit/
│       ├── __init__.py
│       ├── cli.py
│       ├── api/
│       │   ├── main.py             # FastAPI app
│       │   ├── routes/
│       │   └── providers/
│       ├── core/
│       │   ├── config.py
│       │   ├── state.py
│       │   └── reconcile.py
│       ├── dns/
│       ├── ssl/
│       ├── security/
│       │   └── prompt_filter.py
│       ├── observability/
│       └── iac/
├── extensions/                     # Plugin directory
├── scripts/                        # Shell utilities
└── docs/
    ├── architecture/
    ├── api/
    └── guides/
```

______________________________________________________________________

## Security Considerations

| Layer    | Threat              | Mitigation                        |
| -------- | ------------------- | --------------------------------- |
| Ingress  | DDoS                | Rate limiting, Cloudflare proxy   |
| Ingress  | Prompt injection    | Filter middleware, quarantine     |
| Services | Credential exposure | Encrypted secrets, no logs        |
| DNS      | Hijacking           | DNSSEC, short TTL                 |
| SSL      | Certificate theft   | Secure ACME storage, auto-rotate  |
| API      | Unauthorized access | JWT auth, API keys, RBAC          |
| Logs     | Sensitive data leak | PII scrubbing, encryption at rest |

______________________________________________________________________

## Next Steps (Immediate)

1. **Run credential bootstrap** (root password expires in ~20h)
1. **Create DNS records** (manual or automated)
1. **Deploy Traefik** with wildcard SSL
1. **Test subdomain routing**
1. **Document current state** for IaC generation

______________________________________________________________________

## Resource Sizing Guide

| Component   | Minimal     | Homelab     | Team        | Production  |
| ----------- | ----------- | ----------- | ----------- | ----------- |
| GitLab      | 4C/4G       | 6C/6G       | 12C/16G     | 24C/32G     |
| Traefik     | 0.5C/128M   | 1C/256M     | 2C/512M     | 4C/1G       |
| Grafana     | 0.5C/256M   | 1C/512M     | 2C/1G       | 4C/2G       |
| Loki        | 1C/512M     | 2C/1G       | 4C/4G       | 8C/8G       |
| Tempo       | 0.5C/256M   | 1C/512M     | 2C/2G       | 4C/4G       |
| Prometheus  | 1C/512M     | 2C/1G       | 4C/4G       | 8C/8G       |
| Meilisearch | 1C/512M     | 2C/1G       | 4C/4G       | 8C/16G      |
| AutoGit API | 0.5C/256M   | 1C/512M     | 2C/1G       | 4C/2G       |
| **Total**   | **9C/6.5G** | **16C/11G** | **32C/33G** | **64C/73G** |

Your homelab (28C/120G) can easily run the full Homelab tier with room for GPU runners.
