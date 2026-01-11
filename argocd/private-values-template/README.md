# AutoGit Private Values Template

This directory contains template files for setting up your private values repository.

## Overview

AutoGit now uses a **parameterized configuration approach** with `.env.k8s` for all deployments.
This directory provides templates for organizations that want to maintain environment-specific
overrides in a separate private repository.

## Two Configuration Approaches

### Approach 1: Single Repository with .env.k8s (Recommended)

Use `.env.k8s.example` in the root of the AutoGit repository:

1. Copy `.env.k8s.example` to `.env.k8s`
2. Fill in your values
3. Run `./scripts/customize-k8s-env.sh` to update YAML files
4. Run `./scripts/create-k8s-secrets.sh` to create Kubernetes secrets

**Advantages:**
- Simpler setup
- Single source of truth
- Automated tooling provided
- No need for private repository

### Approach 2: Private Values Repository (Advanced)

For organizations requiring additional separation of configuration:

1. Create a new private repository
2. Copy the contents of this directory to your private repo
3. Fill in your actual values (remove `.example` suffix)
4. Configure ArgoCD to use both repositories (multi-source pattern)

**Advantages:**
- Separation of public defaults and private overrides
- Additional security layer
- Per-environment Git access control

## Structure

```
├── environments/
│   ├── homelab/          # Homelab environment values
│   ├── staging/          # Staging environment values  
│   └── production/       # Production environment values
└── secrets/              # Kubernetes Secret templates (use Sealed Secrets)
```

## Important

- **Never commit actual secrets** - use Sealed Secrets or external secret management
- Keep this repository **private**
- Enable **branch protection** on main/master
- For most deployments, Approach 1 (.env.k8s) is sufficient and recommended
