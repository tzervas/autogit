# Private Values Repository Setup

This document describes how to set up a private repository for sensitive configuration
values that should not be stored in the public AutoGit repository.

## Overview

The ArgoCD applications in this repository use a **multi-source pattern** where:
- **Public defaults** are stored in `charts/values/*.yaml` (this repo)
- **Private/sensitive values** should be stored in a separate private repository

## Setting Up Your Private Values Repository

### 1. Create the Private Repository

```bash
# Create a new private repository (e.g., autogit-values-private)
gh repo create autogit-values-private --private --description "Private values for AutoGit deployment"

# Or manually create on GitHub/GitLab with the following structure
```

### 2. Repository Structure

```
autogit-values-private/
├── README.md
├── environments/
│   ├── homelab/
│   │   ├── gitlab.yaml           # GitLab sensitive values
│   │   ├── traefik.yaml          # Traefik sensitive values
│   │   ├── prometheus.yaml       # Prometheus sensitive values
│   │   ├── loki.yaml             # Loki sensitive values
│   │   ├── cert-manager.yaml     # cert-manager sensitive values
│   │   └── runner-coordinator.yaml
│   ├── staging/
│   │   └── ... (same structure)
│   └── production/
│       └── ... (same structure)
└── secrets/
    ├── homelab/
    │   ├── gitlab-root-password.yaml
    │   ├── gitlab-runner-token.yaml
    │   ├── smtp-credentials.yaml
    │   └── tls-certificates.yaml
    └── ... (per environment)
```

### 3. Example Private Values Files

#### `environments/homelab/gitlab.yaml`
```yaml
# GitLab private values - DO NOT COMMIT TO PUBLIC REPO
global:
  hosts:
    domain: vectorweight.com  # Your actual domain
  
  smtp:
    enabled: true
    address: smtp.example.com
    port: 587
    user_name: gitlab@example.com
    # password stored in Kubernetes Secret

  appConfig:
    omniauth:
      providers:
        - name: google_oauth2
          app_id: "YOUR_GOOGLE_CLIENT_ID"
          # app_secret stored in Kubernetes Secret

certmanager-issuer:
  email: your-real-email@example.com
```

#### `environments/homelab/traefik.yaml`
```yaml
# Traefik private values
service:
  spec:
    loadBalancerIP: 192.168.1.100  # Your actual IP

# If using external DNS
providers:
  cloudflare:
    email: your-cloudflare-email@example.com
    # API key stored in Kubernetes Secret
```

#### `environments/homelab/prometheus.yaml`
```yaml
# Prometheus private values
alertmanager:
  config:
    route:
      receiver: 'slack-notifications'
    receivers:
      - name: 'slack-notifications'
        slack_configs:
          - channel: '#alerts'
            # api_url stored in Kubernetes Secret

grafana:
  adminPassword: ""  # Set via Kubernetes Secret
  ingress:
    hosts:
      - grafana.vectorweight.com
```

### 4. Updating ArgoCD Applications for Private Values

To use private values, update the ArgoCD Application manifests to include
an additional source for your private repository:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: autogit-gitlab
spec:
  sources:
    # Primary source: GitLab Helm chart
    - repoURL: https://charts.gitlab.io
      chart: gitlab
      targetRevision: "8.7.0"
      helm:
        releaseName: gitlab
        valueFiles:
          # Public defaults from autogit repo
          - $public/charts/values/gitlab.yaml
          # Private overrides from private repo
          - $private/environments/homelab/gitlab.yaml
    
    # Public values source (this repo)
    - repoURL: https://github.com/tzervas/autogit.git
      targetRevision: main
      ref: public
    
    # Private values source (your private repo)
    - repoURL: https://github.com/YOUR_ORG/autogit-values-private.git
      targetRevision: main
      ref: private
```

### 5. ArgoCD Repository Credentials

Add your private repository to ArgoCD:

```bash
# Using argocd CLI
argocd repo add https://github.com/YOUR_ORG/autogit-values-private.git \
  --username git \
  --password $GITHUB_TOKEN \
  --name autogit-values-private

# Or via Kubernetes Secret
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: autogit-values-private-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: https://github.com/YOUR_ORG/autogit-values-private.git
  username: git
  password: ${GITHUB_TOKEN}
EOF
```

### 6. Alternative: Using Sealed Secrets

If you prefer to keep everything in one repository, you can use
[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets):

```bash
# Install kubeseal
brew install kubeseal

# Seal a secret
kubeseal --format yaml < secret.yaml > sealed-secret.yaml

# The sealed secret can be safely committed to Git
```

### 7. Alternative: Using External Secrets Operator

For integration with external secret stores (AWS Secrets Manager, HashiCorp Vault, etc.):

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: gitlab-secrets
  namespace: autogit-gitlab
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: gitlab-secrets
  data:
    - secretKey: root-password
      remoteRef:
        key: secret/autogit/gitlab
        property: root-password
```

## Security Best Practices

1. **Never commit sensitive values** to the public repository
2. **Use Kubernetes Secrets** for passwords and API keys
3. **Rotate credentials regularly**
4. **Limit repository access** to deployment systems and authorized personnel
5. **Enable audit logging** on your private repository
6. **Use branch protection** on the private values repository

## Quick Start Checklist

- [ ] Create private values repository
- [ ] Copy template structure from this guide
- [ ] Populate environment-specific values
- [ ] Add repository credentials to ArgoCD
- [ ] Update Application manifests (optional - for multi-source)
- [ ] Test deployment with private values
- [ ] Document any environment-specific configuration

## Need Help?

See the main documentation:
- [Kubernetes Installation](../docs/installation/kubernetes.md)
- [ArgoCD Setup](../docs/installation/argocd.md)
