# =============================================================================
# AutoGit ArgoCD Applications
# =============================================================================
# This directory contains ArgoCD Application manifests for GitOps deployment
# of the AutoGit platform.
#
# Structure:
#   apps/           - ArgoCD Application manifests
#   base/           - Base Kubernetes resources (namespaces, etc.)
#   overlays/       - Environment-specific overlays (homelab, staging, prod)
#
# Deployment Order (sync waves):
#   Wave -2: Namespaces and cluster-wide resources
#   Wave -1: Secrets and configuration
#   Wave 0:  Infrastructure (cert-manager, traefik)
#   Wave 1:  Core services (GitLab)
#   Wave 2:  Supporting services (runner-coordinator)
#   Wave 3:  Observability stack
#
# Usage:
#   # Apply the root application (app-of-apps pattern)
#   argocd app create autogit \
#     --repo https://github.com/tzervas/autogit.git \
#     --path argocd/apps \
#     --dest-server https://kubernetes.default.svc \
#     --dest-namespace argocd
#
#   # Or apply directly
#   kubectl apply -f argocd/apps/root.yaml
#
# Documentation: docs/installation/argocd.md
# =============================================================================
