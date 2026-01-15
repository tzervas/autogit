# AutoGit Kubernetes Installation Guide

This guide covers deploying AutoGit to Kubernetes using ArgoCD for GitOps-based deployment
management.

## Prerequisites

### Required Tools

- **kubectl** v1.28+
- **helm** v3.14+
- **helmfile** v0.167+ (optional, for non-ArgoCD deployment)
- **argocd** CLI (for ArgoCD management)

### Cluster Requirements

- Kubernetes 1.28+
- At least 16GB RAM available for workloads
- 100GB persistent storage
- LoadBalancer service support (or MetalLB for bare metal)
- Default StorageClass configured

### Access Requirements

- ArgoCD installed and accessible
- GitHub repository access (for ArgoCD to pull manifests)
- DNS configured for your domain (e.g., `*.example.com`)

## Configuration Overview

AutoGit uses a **parameterized configuration approach** where all environment-specific values are
defined in a single `.env.k8s` file. The provided environment files in `environments/` contain
template values that you customize for your deployment.

### Quick Setup

1. **Copy the environment template:**
   ```bash
   cp .env.k8s.example .env.k8s
   ```

2. **Edit `.env.k8s` with your values:**
   ```bash
   nano .env.k8s
   ```
   
   Minimum required values:
   - `DOMAIN` - Your base domain (e.g., `example.com`)
   - `LETSENCRYPT_EMAIL` - Email for TLS certificate notifications
   - `GITLAB_TOKEN` - GitLab API token (after first boot)
   - `GITLAB_RUNNER_REGISTRATION_TOKEN` - Runner token (after first boot)

3. **Customize environment files:**
   ```bash
   ./scripts/customize-k8s-env.sh homelab
   ```
   
   This script will show your configuration and optionally update all YAML files
   with your domain and settings.

4. **Create Kubernetes secrets:**
   ```bash
   ./scripts/create-k8s-secrets.sh
   ```
   
   This creates all required secrets in your cluster from `.env.k8s` values.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              ArgoCD (GitOps)                                │
│                                    │                                        │
│                          ┌─────────┴─────────┐                              │
│                          │   App-of-Apps     │                              │
│                          │   (root.yaml)     │                              │
│                          └─────────┬─────────┘                              │
│                                    │                                        │
│     ┌──────────┬──────────┬───────┴───────┬──────────┬──────────┐          │
│     ▼          ▼          ▼               ▼          ▼          ▼          │
│ ┌────────┐ ┌────────┐ ┌────────┐   ┌──────────┐ ┌────────┐ ┌────────┐     │
│ │ Base   │ │Traefik │ │  Cert  │   │  GitLab  │ │ Runner │ │ Observ │     │
│ │(ns,rbac)│ │Ingress │ │Manager │   │   CE     │ │ Coord  │ │ Stack  │     │
│ │Wave:-2 │ │Wave:0  │ │Wave:0  │   │ Wave:1   │ │Wave:2  │ │Wave:3  │     │
│ └────────┘ └────────┘ └────────┘   └──────────┘ └────────┘ └────────┘     │
│                                                                             │
│ Namespaces:                                                                 │
│   - autogit-system      (runner-coordinator)                               │
│   - autogit-gitlab      (GitLab CE)                                        │
│   - autogit-runners     (CI/CD job pods)                                   │
│   - autogit-observability (Prometheus, Grafana, Loki)                      │
│   - traefik             (Ingress controller)                               │
│   - cert-manager        (TLS certificates)                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Deployment Options

### Option 1: ArgoCD (Recommended)

ArgoCD provides GitOps-based deployment with automatic sync, drift detection, and rollback
capabilities.

### Option 2: Helmfile

For environments without ArgoCD, Helmfile provides declarative Helm chart management.

---

## Option 1: ArgoCD Deployment

### Step 1: Configure Your Environment

**Important:** Before deploying, you must customize the configuration for your domain and environment.

```bash
# 1. Copy the environment template
cp .env.k8s.example .env.k8s

# 2. Edit with your values (at minimum: DOMAIN and LETSENCRYPT_EMAIL)
nano .env.k8s

# 3. Customize environment files with your domain
./scripts/customize-k8s-env.sh homelab

# 4. Review the changes
git diff environments/homelab
```

### Step 2: Connect Repository to ArgoCD

```bash
# Add the AutoGit repository to ArgoCD
argocd repo add https://github.com/tzervas/autogit.git \
  --name autogit \
  --type git
```

For private repositories:

```bash
# Using SSH key
argocd repo add git@github.com:tzervas/autogit.git \
  --ssh-private-key-path ~/.ssh/id_ed25519

# Or using HTTPS with token
argocd repo add https://github.com/tzervas/autogit.git \
  --username git \
  --password <github-token>
```

### Step 3: Create Required Secrets

Use the provided script to create all required secrets from your `.env.k8s` file:

```bash
# Create all secrets automatically
./scripts/create-k8s-secrets.sh
```

This script creates:
- GitLab API tokens secret in `autogit-system` namespace
- Grafana admin password secret in `autogit-observability` namespace  
- SMTP credentials (if `SMTP_ENABLED=true`)
- External database credentials (if configured)
- S3 backup credentials (if `ENABLE_BACKUPS=true`)

**Note:** If you don't have GitLab tokens yet (first deployment), the script will create
placeholder secrets that you'll update after GitLab starts.

<details>
<summary>Manual Secret Creation (alternative)</summary>

If you prefer to create secrets manually:

```bash
# Create namespace first
kubectl create namespace autogit-system

# Create GitLab tokens secret
kubectl create secret generic autogit-gitlab-tokens \
  --namespace autogit-system \
  --from-literal=GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx" \
  --from-literal=GITLAB_RUNNER_REGISTRATION_TOKEN="GR1348941xxxxxxxxxxxxxxxxxxxx"

# Create Grafana admin password (optional - will auto-generate if not set)
kubectl create namespace autogit-observability
kubectl create secret generic grafana-admin \
  --namespace autogit-observability \
  --from-literal=admin-password="your-secure-password"
```
</details>

### Step 4: Deploy the Root Application

Apply the root application manifest to bootstrap the entire platform:

```bash
# Using kubectl
kubectl apply -f argocd/apps/root.yaml

# Or using ArgoCD CLI
argocd app create autogit \
  --repo https://github.com/tzervas/autogit.git \
  --path argocd/apps \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace argocd \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

### Step 4: Monitor Deployment

```bash
# Watch application status
argocd app list

# Get detailed status
argocd app get autogit

# View sync status of all child apps
argocd app get autogit-gitlab
argocd app get autogit-runner-coordinator
argocd app get autogit-observability

# View logs for troubleshooting
argocd app logs autogit-gitlab
```

### Step 5: Access Services

Once deployed, services are accessible at (replace `example.com` with your domain):

| Service | URL | Notes |
|---------|-----|-------|
| GitLab | https://gitlab.example.com | Main Git server |
| Grafana | https://grafana.example.com | Monitoring dashboards |
| Traefik | https://traefik.example.com | Ingress dashboard |
| Runner API | https://runner.example.com | Runner coordinator API |

---

## Option 2: Helmfile Deployment

### Step 1: Configure Your Environment

Same as ArgoCD Step 1 - customize your configuration:

```bash
# 1. Copy and edit environment file
cp .env.k8s.example .env.k8s
nano .env.k8s

# 2. Customize environment files
./scripts/customize-k8s-env.sh homelab
```

### Step 2: Install Helmfile

```bash
# macOS
brew install helmfile

# Linux - Install specific version with checksum verification
HELMFILE_VERSION="0.167.1"
curl -LO "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_amd64.tar.gz"
curl -LO "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_checksums.txt"

# Verify checksum
sha256sum -c helmfile_${HELMFILE_VERSION}_checksums.txt --ignore-missing

# Extract and install
tar -xzf helmfile_${HELMFILE_VERSION}_linux_amd64.tar.gz
chmod +x helmfile
sudo mv helmfile /usr/local/bin/

# Verify installation
helmfile version
```

### Step 3: Create Secrets

Same as ArgoCD Step 3:

```bash
./scripts/create-k8s-secrets.sh
```

### Step 4: Deploy with Helmfile

```bash
# Preview changes
helmfile -e homelab diff

# Deploy all releases
helmfile -e homelab sync

# Deploy specific release
helmfile -e homelab -l name=gitlab sync
```

### Step 5: Verify Deployment

```bash
# Check all pods
kubectl get pods -A | grep autogit

# Check services
kubectl get svc -A | grep autogit

# Check ingresses
kubectl get ingress -A
```

---

## Post-Installation Configuration

### GitLab Initial Setup

1. **Get Initial Root Password**:
   ```bash
   kubectl get secret -n autogit-gitlab gitlab-gitlab-initial-root-password \
     -o jsonpath='{.data.password}' | base64 -d
   ```

2. **Login and Change Password**:
   - Navigate to https://gitlab.example.com (replace with your domain)
   - Login as `root` with the initial password
   - Change the password immediately

3. **Create Runner Registration Token**:
   - Go to Admin > CI/CD > Runners
   - Click "New instance runner"
   - Copy the registration token
   - Update the secret:
     ```bash
     kubectl patch secret autogit-gitlab-tokens -n autogit-system \
       --type='json' \
       -p='[{"op": "replace", "path": "/data/GITLAB_RUNNER_REGISTRATION_TOKEN", "value":"'$(echo -n "YOUR_NEW_TOKEN" | base64)'"}]'
     ```

### Verify Runner Coordinator

```bash
# Check coordinator logs
kubectl logs -n autogit-system -l app.kubernetes.io/name=runner-coordinator -f

# Check health endpoint
kubectl port-forward -n autogit-system svc/runner-coordinator 8080:8080
curl http://localhost:8080/health
```

### Configure DNS

Ensure your DNS is configured to point to the cluster's ingress IP:

```bash
# Get Traefik LoadBalancer IP
kubectl get svc -n traefik traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Create DNS records (replace `example.com` with your domain):
- `gitlab.example.com` → LoadBalancer IP
- `grafana.example.com` → LoadBalancer IP
- `traefik.example.com` → LoadBalancer IP
- `runner.example.com` → LoadBalancer IP

---

## Troubleshooting

### ArgoCD Sync Issues

```bash
# Force sync
argocd app sync autogit --force

# Check sync details
argocd app sync autogit --dry-run

# View application manifests
argocd app manifests autogit
```

### GitLab Not Starting

```bash
# Check pod status
kubectl get pods -n autogit-gitlab

# Check pod events
kubectl describe pod -n autogit-gitlab -l app=webservice

# Check logs
kubectl logs -n autogit-gitlab -l app=webservice --tail=100
```

### Certificate Issues

```bash
# Check certificate status
kubectl get certificates -A

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Check certificate requests
kubectl get certificaterequests -A
```

### Runner Coordinator Not Connecting

```bash
# Verify GitLab URL is accessible from the cluster
kubectl run -it --rm debug --image=curlimages/curl -- \
  curl -k https://gitlab.example.com/-/health

# Check network policies
kubectl get networkpolicies -n autogit-system

# Verify secrets
kubectl get secret autogit-gitlab-tokens -n autogit-system -o yaml
```

---

## Upgrading

### Via ArgoCD

ArgoCD automatically syncs changes when the Git repository is updated. For manual upgrades:

```bash
# Sync specific app
argocd app sync autogit-gitlab

# Sync all apps
argocd app sync autogit
```

### Via Helmfile

```bash
# Update repositories
helmfile -e homelab repos

# Preview changes
helmfile -e homelab diff

# Apply updates
helmfile -e homelab sync
```

---

## Uninstalling

### Via ArgoCD

```bash
# Delete root application (cascading delete)
argocd app delete autogit --cascade

# Or delete individual apps
argocd app delete autogit-observability
argocd app delete autogit-runner-coordinator
argocd app delete autogit-gitlab
argocd app delete autogit-traefik
argocd app delete autogit-cert-manager
argocd app delete autogit-base
```

### Via Helmfile

```bash
helmfile -e homelab destroy
```

### Manual Cleanup

```bash
# Delete namespaces
kubectl delete namespace autogit-system autogit-gitlab autogit-runners autogit-observability

# Delete cluster-wide resources
kubectl delete clusterissuer letsencrypt-staging letsencrypt-prod
kubectl delete clusterrole runner-coordinator
kubectl delete clusterrolebinding runner-coordinator
```

---

## Next Steps

- [Configure SSO with Authelia](../configuration/sso.md)
- [Set up GPU runners](../gpu/README.md)
- [Configure monitoring alerts](../operations/alerting.md)
- [Backup and restore procedures](../operations/backup.md)
