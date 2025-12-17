# Copilot Instructions for Kubernetes VPS Setup

## Project Overview

This is a **template generator** for deploying Laravel applications to Kubernetes on VPS. It's NOT a Laravel app itself—it's a configuration toolkit that creates all necessary files for deploying Laravel apps to K8s.

**Core Concept**: Run `./setup.sh` to interactively generate Kubernetes manifests, Docker configs, and GitHub Actions workflows for a Laravel project.

## Architecture & File Organization

### Template-Based Generation
- **Templates** (`templates/*.stub`): Source files with `{{PLACEHOLDER}}` variables
- **Generated Files**: Created in the target Laravel project's directories (`kubernetes/`, `docker/`, `.github/workflows/`)
- **Main Script**: `setup.sh` orchestrates the entire generation process

### Template Categories
1. **Kubernetes manifests** (10 files): namespace, secrets, configmap, postgres, redis, deployment, service, ingress, cert-issuer, migration-job
2. **Docker configs** (2 files): nginx/default.conf, supervisor/supervisord.conf
3. **Dev environment** (6 files): docker-compose, Dockerfile.dev, nginx-dev.conf, php-local.ini, supervisord-dev.conf, env.local
4. **CI/CD**: GitHub Actions workflow for automated deployment

### Multi-App Architecture
- Single VPS can host multiple Laravel apps via namespaces
- **Shared**: Ingress Controller (Nginx), cert-manager (SSL)
- **Isolated per app**: Namespace, PostgreSQL, Redis, secrets
- See [MULTIPLE_APPS.md](MULTIPLE_APPS.md) for deployment patterns

## Critical Workflows

### Primary Workflow: Generate Config for New Laravel Project

```bash
cd kubernetes-vps-setup
./setup.sh
```

Script prompts for:
- Project name, namespace, domain
- VPS IP address
- GitHub user/repo (for Container Registry)
- Laravel APP_KEY (auto-generates if empty)
- Database credentials (auto-generates passwords)
- Resource limits (CPU/memory)

**Output**: Creates `kubernetes/`, `docker/`, `.github/workflows/` in the parent Laravel project directory.

### Secondary Workflow: VPS Initial Setup (One-Time)

Before using this toolkit, VPS must have:
- Docker + Kubernetes (kubeadm, kubectl, kubelet)
- Ingress Controller (Nginx)
- cert-manager for SSL
- Firewall configured (UFW)

See **PART 1** of [DEPLOY_VPS.md](DEPLOY_VPS.md) for complete VPS setup.

## Key Conventions

### Documentation Organization
- All user-facing documentation lives in `docs/` directory
- `setup.sh` copies the entire `docs/` folder to the target Laravel project
- **Documentation is personalized**: All `{{PLACEHOLDER}}` variables in docs are replaced with actual project values
- Main README.md stays at root for GitHub visibility
- After setup, users get complete docs in their project's `docs/` folder with **their specific project values**

Example: `kubectl get pods -n {{NAMESPACE}}` becomes `kubectl get pods -n my-app`

### Placeholder System
- All templates use `{{VARIABLE}}` syntax (not `${VAR}` or `$VAR`)
- Common placeholders: `{{NAMESPACE}}`, `{{DOMAIN}}`, `{{GITHUB_REPO}}`, `{{DB_PASSWORD}}`
- `setup.sh` uses `sed` to replace placeholders with user-provided values

### File Naming
- Templates end with `.stub`
- Generated files drop the `.stub` suffix
- Dev files go in `.dev/` directory (git-ignored)
- Production files go in `kubernetes/`, `docker/`, `.github/workflows/`

### Resource Allocation Pattern
Default values in `setup.sh`:
```bash
REPLICAS=2
MEM_REQUEST="256Mi"    # Per pod
MEM_LIMIT="512Mi"
CPU_REQUEST="200m"
CPU_LIMIT="500m"
```

### Namespace Isolation
- Each Laravel app gets its own K8s namespace
- Pattern: Use project name as namespace (e.g., `kb-app`, `meu-app`)
- Namespace is set in ALL generated manifests

## Documentation Structure

All documentation is organized in the `docs/` directory:

**For quick starts**: [docs/QUICK_START.md](docs/QUICK_START.md) - 30-minute deploy guide
**For comprehensive setup**: [docs/DEPLOY_VPS.md](docs/DEPLOY_VPS.md) - Simplified guide with PART 1 (VPS) + PART 2 (Laravel apps)
**For deep technical details**: [docs/DEPLOY_VPS_ADVANCED.md](docs/DEPLOY_VPS_ADVANCED.md) - Complete YAML explanations
**For navigation**: [docs/INDEX.md](docs/INDEX.md) - Choose your learning path
**For multiple apps**: [docs/MULTIPLE_APPS.md](docs/MULTIPLE_APPS.md) - Running multiple Laravel apps on same VPS
**For file structure**: [docs/FILE_STRUCTURE.md](docs/FILE_STRUCTURE.md) - Understanding generated files

## Important Commands

### Deployment Commands (After setup.sh)
```bash
# Apply all K8s manifests
kubectl apply -f kubernetes/

# Check deployment status
kubectl get all -n <namespace>

# View logs
kubectl logs -f deployment/app -n <namespace>

# Run migrations
kubectl apply -f kubernetes/migration-job.yaml
```

### Updating Existing Projects
When modifying templates, re-run `./setup.sh` and it will regenerate all files with new values.

## Common Patterns

### Adding New Template Variables
1. Add placeholder to `.stub` file: `{{NEW_VAR}}`
2. Add prompt in `setup.sh` using `read_input` function
3. Add `sed` replacement in the file generation section

### Supporting New Services
1. Create `templates/newservice.yaml.stub`
2. Add service generation in `setup.sh` (search for "postgres.yaml" section as reference)
3. Update documentation in README.md

### Dev vs Production Environments
- **Dev**: Local Docker Compose (`.dev/` directory), manual execution
- **Production**: Kubernetes + GitHub Actions, automatic CI/CD on push
- Both configurations generated by single `setup.sh` execution

## GitHub Actions Integration

Generated workflow (`deploy.yml`) automates:
1. Checkout code
2. Build Docker image
3. Push to GitHub Container Registry
4. Update Kubernetes deployment (kubectl rollout restart)

**Required GitHub Secrets**: `KUBE_CONFIG`, `GHCR_TOKEN`

## Testing & Verification

No automated tests exist for this toolkit. Manual verification:
1. Run `./setup.sh` with test values
2. Inspect generated files in `kubernetes/`, `docker/`
3. Validate YAML syntax: `kubectl apply --dry-run=client -f kubernetes/`
4. Check placeholder replacement completeness
