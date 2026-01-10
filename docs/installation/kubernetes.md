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
- DNS configured for your domain (e.g., `*.vectorweight.com`)

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

### Step 1: Connect Repository to ArgoCD

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

### Step 2: Create Required Secrets

Before deploying, create the required secrets:

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

### Step 3: Deploy the Root Application

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

Once deployed, services are accessible at:

| Service | URL | Notes |
|---------|-----|-------|
| GitLab | https://gitlab.vectorweight.com | Main Git server |
| Grafana | https://grafana.vectorweight.com | Monitoring dashboards |
| Traefik | https://traefik.vectorweight.com | Ingress dashboard |
| Runner API | https://runner.vectorweight.com | Runner coordinator API |

---

## Option 2: Helmfile Deployment

### Step 1: Install Helmfile

```bash
# macOS
brew install helmfile

# Linux
curl -Lo helmfile https://github.com/helmfile/helmfile/releases/latest/download/helmfile_linux_amd64
chmod +x helmfile
sudo mv helmfile /usr/local/bin/
```

### Step 2: Create Secrets

Same as ArgoCD Step 2 above.

### Step 3: Deploy with Helmfile

```bash
# Preview changes
helmfile -e homelab diff

# Deploy all releases
helmfile -e homelab sync

# Deploy specific release
helmfile -e homelab -l name=gitlab sync
```

### Step 4: Verify Deployment

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
   - Navigate to https://gitlab.vectorweight.com
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

Create DNS records:
- `gitlab.vectorweight.com` → LoadBalancer IP
- `grafana.vectorweight.com` → LoadBalancer IP
- `traefik.vectorweight.com` → LoadBalancer IP
- `runner.vectorweight.com` → LoadBalancer IP

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
  curl -k https://gitlab.vectorweight.com/-/health

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
