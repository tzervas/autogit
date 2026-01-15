# AutoGit ArgoCD Deployment Guide

This guide covers deploying AutoGit using ArgoCD's GitOps approach.

## Overview

AutoGit uses the **App-of-Apps** pattern with ArgoCD, where a single root application manages all
child applications. This provides:

- **Declarative deployment**: All configuration stored in Git
- **Automatic sync**: Changes in Git automatically deployed
- **Drift detection**: ArgoCD detects and can correct manual changes
- **Rollback**: Easy rollback to any previous Git commit

## Directory Structure

```
argocd/
├── README.md               # This file
├── apps/                   # ArgoCD Application manifests
│   ├── root.yaml          # Root app-of-apps (deploy this)
│   ├── base.yaml          # Namespaces and cluster resources
│   ├── cert-manager.yaml  # TLS certificate management
│   ├── traefik.yaml       # Ingress controller
│   ├── gitlab.yaml        # GitLab CE
│   ├── runner-coordinator.yaml  # Runner management
│   ├── observability.yaml # Prometheus/Grafana stack
│   └── loki.yaml          # Log aggregation
├── base/                   # Base Kubernetes resources
│   ├── kustomization.yaml # Kustomize configuration
│   ├── namespaces.yaml    # Namespace definitions
│   ├── cluster-issuers.yaml # Let's Encrypt issuers
│   ├── runner-rbac.yaml   # RBAC for runners
│   ├── network-policies.yaml # Network isolation
│   └── resource-quotas.yaml  # Resource limits
└── overlays/              # Environment-specific overlays
    └── homelab/           # Homelab-specific configs
```

## Sync Waves

Applications are deployed in order using ArgoCD sync waves:

| Wave | Applications | Purpose |
|------|--------------|---------|
| -2 | Base | Namespaces, cluster resources |
| -1 | Secrets, RBAC | Prerequisites for apps |
| 0 | cert-manager, Traefik | Infrastructure |
| 1 | GitLab | Core service |
| 2 | Runner Coordinator | Supporting service |
| 3 | Observability, Loki | Monitoring |

## Quick Start

### 1. Prerequisites

Ensure ArgoCD is installed and you have access:

```bash
# Verify ArgoCD is running
kubectl get pods -n argocd

# Login to ArgoCD
argocd login <argocd-server>
```

### 2. Add Repository

```bash
argocd repo add https://github.com/tzervas/autogit.git
```

### 3. Create Secrets

```bash
# Create namespace
kubectl create namespace autogit-system

# Create GitLab tokens
kubectl create secret generic autogit-gitlab-tokens \
  --namespace autogit-system \
  --from-literal=GITLAB_TOKEN="<your-gitlab-pat>" \
  --from-literal=GITLAB_RUNNER_REGISTRATION_TOKEN="<your-runner-token>"
```

### 4. Deploy

```bash
kubectl apply -f argocd/apps/root.yaml
```

### 5. Monitor

```bash
# Watch deployment
argocd app get autogit --refresh

# View all apps
argocd app list
```

## Application Details

### autogit (Root)

The root application that manages all other applications.

- **Path**: `argocd/apps`
- **Sync Policy**: Automated with prune and self-heal

### autogit-base

Deploys foundational Kubernetes resources.

- **Path**: `argocd/base`
- **Resources**: Namespaces, RBAC, Network Policies, Resource Quotas

### autogit-gitlab

Deploys GitLab CE using the official Helm chart.

- **Chart**: `gitlab/gitlab`
- **Version**: 8.7.0
- **Namespace**: `autogit-gitlab`

### autogit-runner-coordinator

Deploys the custom runner coordinator.

- **Chart**: `charts/runner-coordinator`
- **Namespace**: `autogit-system`

### autogit-observability

Deploys monitoring stack.

- **Chart**: `prometheus-community/kube-prometheus-stack`
- **Namespace**: `autogit-observability`

### autogit-loki

Deploys log aggregation.

- **Chart**: `grafana/loki-stack`
- **Namespace**: `autogit-observability`

## Customization

### Environment-Specific Values

Modify values in `environments/homelab/` for your environment:

- `gitlab.yaml` - GitLab configuration
- `runner-coordinator.yaml` - Runner settings
- `prometheus.yaml` - Monitoring config

### Adding Applications

1. Create Application manifest in `argocd/apps/`
2. Set appropriate `sync-wave` annotation
3. Commit and push to Git
4. ArgoCD will automatically deploy

## Troubleshooting

### Application Stuck in Progressing

```bash
# Check application details
argocd app get <app-name>

# Check resource events
kubectl describe <resource> -n <namespace>
```

### Sync Failed

```bash
# View sync details
argocd app sync <app-name> --dry-run

# Force sync
argocd app sync <app-name> --force
```

### Webhook Issues

```bash
# Check webhook logs
kubectl logs -n cert-manager -l app=webhook

# Restart webhook
kubectl rollout restart deployment -n cert-manager cert-manager-webhook
```

## Maintenance

### Manual Sync

```bash
argocd app sync autogit
```

### Refresh

```bash
argocd app get autogit --refresh
```

### Rollback

```bash
# List history
argocd app history autogit-gitlab

# Rollback to specific revision
argocd app rollback autogit-gitlab <revision>
```

### Delete Application

```bash
# Delete with cascade (removes managed resources)
argocd app delete autogit --cascade

# Delete without cascade (keeps resources)
argocd app delete autogit
```
