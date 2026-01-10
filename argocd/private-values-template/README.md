# AutoGit Private Values Template

This directory contains template files for setting up your private values repository.

## Usage

1. Create a new private repository
2. Copy the contents of this directory to your private repo
3. Fill in your actual values (remove `.example` suffix)
4. Configure ArgoCD to use both repositories

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
