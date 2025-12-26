# Infrastructure as Code - Terraform/OpenTofu Implementation

**Priority:** Post-MVP (After smoke test validation)\
**Status:** Backlog\
**Created:** 2025-12-25

______________________________________________________________________

## Objective

Convert validated homelab deployment configuration into Infrastructure as Code (IaC) using
Terraform/OpenTofu for:

- Consistent deployments
- Idempotent operations
- Automated orchestration
- Version-controlled infrastructure
- Reproducible environments

______________________________________________________________________

## Scope

### Phase 1: Core Infrastructure

- [ ] Docker provider configuration
- [ ] GitLab container resource definition
- [ ] GitLab Runner container resource definition
- [ ] Network configuration (gitlab-network)
- [ ] Volume management (data persistence)

### Phase 2: Configuration Management

- [ ] GitLab OMNIBUS_CONFIG as Terraform variables
- [ ] PostgreSQL tuning parameters as variables
- [ ] SSL certificate management (file provisioners or external data)
- [ ] Environment variable templating
- [ ] Port mapping configuration

### Phase 3: Monitoring & Health Checks

- [ ] Container health check configuration
- [ ] Readiness probes
- [ ] Deployment timing outputs
- [ ] Resource usage metrics

### Phase 4: Backup & Recovery

- [ ] Automated backup schedules
- [ ] Volume snapshot configuration
- [ ] Restore procedures as modules
- [ ] Data migration scripts

______________________________________________________________________

## Design Principles

### 1. **Idempotency**

All operations must be safely re-runnable:

- No duplicate resource creation
- State tracking for all components
- Graceful handling of existing resources

### 2. **Modularity**

Break into reusable modules:

```
terraform/
├── modules/
│   ├── gitlab/           # GitLab CE container
│   ├── gitlab-runner/    # Runner container
│   ├── postgresql/       # DB tuning config
│   ├── networking/       # Docker networks
│   └── ssl/              # Certificate management
├── environments/
│   ├── homelab/          # Homelab-specific vars
│   ├── dev/              # Development environment
│   └── staging/          # Staging environment
└── main.tf               # Root module
```

### 3. **Known-Good Configuration**

Capture validated smoke test configuration:

- PostgreSQL tuning (shared_buffers, work_mem, etc.)
- Healthcheck timing (600s start_period)
- Resource limits (from successful deployment)
- Network settings
- Volume mounts

### 4. **Observability**

Output useful information:

- Container IDs
- Network IPs
- Volume paths
- Health check status
- Initialization timestamps

______________________________________________________________________

## Implementation Tasks

### Task 1: Setup Terraform Structure

```hcl
# main.tf
terraform {
  required_version = ">= 1.6"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}
```

### Task 2: Convert docker-compose.homelab.yml to HCL

```hcl
# modules/gitlab/main.tf
resource "docker_image" "gitlab" {
  name         = "gitlab/gitlab-ce:latest"
  keep_locally = false
}

resource "docker_container" "gitlab" {
  name  = "autogit-git-server"
  image = docker_image.gitlab.image_id

  restart = "unless-stopped"

  hostname = var.gitlab_hostname

  env = [
    "GITLAB_OMNIBUS_CONFIG=${local.omnibus_config}"
  ]

  # PostgreSQL tuning from smoke test
  locals {
    omnibus_config = templatefile("${path.module}/omnibus_config.tpl", {
      external_url       = var.external_url
      postgres_tuning    = var.postgres_tuning
      ssl_cert_path      = var.ssl_cert_path
      ssl_key_path       = var.ssl_key_path
      worker_processes   = var.worker_processes
      sidekiq_concurrency = var.sidekiq_concurrency
    })
  }

  # Health check with validated timing
  healthcheck {
    test     = ["CMD", "curl", "-f", "-k", "https://localhost/-/health"]
    interval = "60s"
    timeout  = "30s"
    retries  = 3
    start_period = "600s"  # From smoke test validation
  }

  # Ports
  ports {
    internal = 80
    external = 80
  }
  ports {
    internal = 443
    external = 443
  }
  ports {
    internal = 22
    external = 2222
  }

  # Volumes
  volumes {
    host_path      = "${var.data_dir}/config"
    container_path = "/etc/gitlab"
  }
  volumes {
    host_path      = "${var.data_dir}/logs"
    container_path = "/var/log/gitlab"
  }
  volumes {
    host_path      = "${var.data_dir}/data"
    container_path = "/var/opt/gitlab"
  }

  networks_advanced {
    name = docker_network.gitlab_network.name
  }
}
```

### Task 3: PostgreSQL Tuning Module

```hcl
# modules/postgresql/variables.tf
variable "postgres_tuning" {
  description = "PostgreSQL performance tuning from smoke test"
  type = object({
    shared_buffers              = string
    effective_cache_size        = string
    work_mem                    = string
    maintenance_work_mem        = string
    checkpoint_completion_target = number
    wal_buffers                 = string
    max_wal_size                = string
    min_wal_size                = string
    random_page_cost            = number
  })

  default = {
    # Validated from smoke test
    shared_buffers              = "256MB"
    effective_cache_size        = "1GB"
    work_mem                    = "16MB"
    maintenance_work_mem        = "64MB"
    checkpoint_completion_target = 0.9
    wal_buffers                 = "16MB"
    max_wal_size                = "1GB"
    min_wal_size                = "80MB"
    random_page_cost            = 1.1
  }
}
```

### Task 4: Environment-Specific Variables

```hcl
# environments/homelab/terraform.tfvars
gitlab_hostname = "gitlab.vectorweight.com"
external_url    = "https://gitlab.vectorweight.com"
data_dir        = "./data/gitlab"

# Resource limits from successful smoke test
worker_processes    = 1
sidekiq_concurrency = 2
db_pool            = 10

# PostgreSQL tuning (validated configuration)
postgres_tuning = {
  shared_buffers              = "256MB"
  effective_cache_size        = "1GB"
  work_mem                    = "16MB"
  maintenance_work_mem        = "64MB"
  checkpoint_completion_target = 0.9
  wal_buffers                 = "16MB"
  max_wal_size                = "1GB"
  min_wal_size                = "80MB"
  random_page_cost            = 1.1
}

# Timing from smoke test
healthcheck_start_period = "600s"
```

### Task 5: Outputs for Monitoring

```hcl
# outputs.tf
output "gitlab_container_id" {
  value = docker_container.gitlab.id
}

output "gitlab_ip_address" {
  value = docker_container.gitlab.network_data[0].ip_address
}

output "gitlab_health_url" {
  value = "https://localhost/-/health"
}

output "deployment_timestamp" {
  value = timestamp()
}

output "postgres_tuning_applied" {
  value = var.postgres_tuning
}
```

______________________________________________________________________

## Migration Strategy

### Step 1: Validate Current Deployment

- [ ] Complete smoke test with docker-compose.homelab.yml
- [ ] Document successful configuration
- [ ] Record initialization times
- [ ] Capture resource usage

### Step 2: Create Terraform Equivalent

- [ ] Convert docker-compose.homelab.yml to Terraform HCL
- [ ] Preserve all tuning parameters
- [ ] Test in isolated environment

### Step 3: Parallel Run

- [ ] Deploy with Terraform alongside docker-compose
- [ ] Compare configurations
- [ ] Validate identical behavior

### Step 4: Cutover

- [ ] Transition from docker-compose to Terraform
- [ ] Update documentation
- [ ] Archive docker-compose.homelab.yml as reference

______________________________________________________________________

## OpenTofu Compatibility

All code should be compatible with both:

- **Terraform** (HashiCorp)
- **OpenTofu** (CNCF/Linux Foundation fork)

Use OpenTofu-compatible syntax:

- Standard HCL features only
- No proprietary Terraform Cloud features
- Open-source provider ecosystem

______________________________________________________________________

## Success Metrics

- [ ] Deployment time < 12 minutes (same as docker-compose)
- [ ] No manual intervention required
- [ ] State management working correctly
- [ ] Rollback capability functional
- [ ] All PostgreSQL tuning applied correctly
- [ ] Health checks passing consistently

______________________________________________________________________

## Benefits

1. **Consistency:** Same deployment every time
1. **Version Control:** Infrastructure changes tracked in git
1. **Rollback:** Easy revert to previous configurations
1. **Documentation:** Code is documentation
1. **Scalability:** Easy to add new environments
1. **Automation:** CI/CD integration ready
1. **Drift Detection:** Terraform state tracks actual vs desired

______________________________________________________________________

## Dependencies

- Smoke test MUST pass first
- Known-good configuration validated
- Resource requirements documented
- Timing parameters confirmed

______________________________________________________________________

## Future Enhancements

- [ ] Multi-region deployment support
- [ ] Auto-scaling runner configuration
- [ ] Secrets management integration (Vault)
- [ ] Monitoring stack (Prometheus/Grafana)
- [ ] Backup automation
- [ ] Blue-green deployment support
- [ ] Canary deployment capability

______________________________________________________________________

**Next Step:** Complete smoke test, validate configuration, then begin Terraform conversion.
