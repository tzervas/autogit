# Secrets Management

This directory contains templates for Kubernetes Secrets.

## Important Security Notes

1. **Never commit actual secrets** to any Git repository
2. Use one of these approaches for secret management:

### Option 1: Sealed Secrets (Recommended for GitOps)

```bash
# Install kubeseal CLI
brew install kubeseal  # macOS
# or
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz

# Seal a secret
kubeseal --format yaml < secret.yaml > sealed-secret.yaml

# Commit the sealed secret (safe to store in Git)
git add sealed-secret.yaml
```

### Option 2: External Secrets Operator

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: gitlab-secrets
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

### Option 3: Manual Secret Creation

```bash
# Create secrets manually (not tracked in Git)
kubectl create secret generic gitlab-secrets \
  --namespace autogit-gitlab \
  --from-literal=root-password='your-secure-password' \
  --from-literal=runner-token='your-runner-token'
```

## Secret Templates

The `.template` files in this directory show the structure of secrets needed.
Replace placeholder values and create the actual secrets using one of the methods above.
