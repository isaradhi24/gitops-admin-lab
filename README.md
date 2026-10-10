# GitOps Administrator Lab — GitHub Actions, Azure & Kubernetes

## Project Overview

This project demonstrates an enterprise-style GitOps deployment workflow using GitHub Actions, Helm, Argo CD, Kubernetes, and Microsoft Azure.

The objective is to automate and securely manage application deployments across Development, QA, UAT, and Production environments using immutable container images, environment-specific configurations, and GitOps reconciliation.

The project reuses Kubernetes and Helm configurations from an existing GitLab-based `k8s-platform-lab`.

## Technology Stack

- **Source Control:** GitHub
- **CI/CD:** GitHub Actions
- **Containerization:** Docker
- **Container Registry:** Azure Container Registry (ACR) — Planned
- **Infrastructure:** Kubernetes (kind locally; AKS integration planned)
- **Package Management:** Helm
- **GitOps:** Argo CD
- **Authentication:** Azure OIDC / Federated Identity — Planned
- **Secrets Management:** Azure Key Vault — Planned
- **Development:** VS Code on Windows and macOS

## Architecture

```text
Developer
   |
   v
GitHub Repository
   |
   v
GitHub Actions CI
   |-- Helm Validation
   |-- Build & Test (Planned)
   |-- Security Scanning (Planned)
   |
   v
Azure Container Registry (Planned)
   |
   v
GitOps Configuration Update
   |
   v
Argo CD
   |
   v
Kubernetes
   |
   |-- Development
   |-- QA
   |-- UAT
   |-- Production
```

## Repository Structure

```text
gitops-admin-lab/
├── .github/workflows/       # GitHub Actions workflows
├── helm/custom-nginx-chart/ # Reusable Helm chart
├── gitops/
│   ├── dev/                 # Development values
│   ├── qa/                  # QA values
│   ├── uat/                 # UAT values
│   └── prod/                # Production values
└── README.md
```

## Implementation Progress
``` table
| Component | Status |
|---|---|
| GitHub repository setup | Completed |
| Windows and macOS Git repository setup | Completed |
| Reuse existing Helm chart | Completed |
| Helm lint and template validation | Completed |
| Image digest support in Helm | Completed |
| Dev / QA / UAT / Production Helm values | Completed |
| GitHub Actions CI workflow | In Progress |
| Docker build and Git SHA tagging | Planned |
| Azure OIDC and ACR integration | Planned |
| Immutable image promotion | Planned |
| Argo CD multi-environment deployment | Planned |
| Azure Key Vault integration | Planned |
| GitOps drift detection and self-healing | Planned |
| Security hardening and troubleshooting | Planned |
```
## Multi-Environment Configuration

The same Helm chart is used across all four environments, with different replica counts.
``` table
| Environment | Replicas |
|---|---:|
| Dev | 1 |
| QA | 2 |
| UAT | 2 |
| Production | 3 |
```
Env## Daily Lab Startup and Verification
## Daily Lab Startup and Verification
### Architecture

- **Windows PC:** Docker Desktop, WSL2 Ubuntu, kind Kubernetes cluster, and Argo CD.
- **MacBook Pro:** VS Code, Git, Helm, kubectl, Terraform, and GitHub Actions development.
- **Connectivity:** Automatic SSH tunnel from Mac to Windows Kubernetes API.
- **GitHub repository:** `isaradhi24/gitops-admin-lab`
- **Kubernetes cluster:** `kind-gitops-admin`
- **Kubernetes version:** v1.35.1

### 1. Start and verify the Kubernetes cluster on Windows

Start Docker Desktop on Windows.

Open WSL Ubuntu and run:

```bash
docker info
kind get clusters
kubectl config current-context
kubectl get nodes -o wide
```

Expected Kubernetes context:

```text
kind-gitops-admin
```

Expected nodes:

```text
gitops-admin-control-plane   Ready
gitops-admin-worker          Ready
```

If the cluster exists but its Docker containers are stopped, check:

```bash
docker ps -a --filter "name=gitops-admin"
```

Start the existing cluster containers if needed:

```bash
docker start gitops-admin-control-plane gitops-admin-worker
```

Do not recreate the kind cluster unless recovery is necessary.

### 2. Verify Argo CD and application health

From Windows WSL:

```bash
kubectl get pods -n argocd
kubectl get applications -n argocd
kubectl get deployments,pods,svc -n dev
```

Expected Argo CD application:

```text
nginx-dev   Synced   Healthy
```

For local Argo CD UI access from Windows WSL:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open `https://localhost:8080` from the Windows browser.

### 3. Verify MacBook Pro connectivity

The Mac uses a LaunchAgent to establish an SSH tunnel automatically at login.

SSH target:

```text
vijay@192.168.1.200
```

Kubernetes API tunnel:

```text
127.0.0.1:46319
```

Verify the SSH connection:

```bash
ssh -o BatchMode=yes vijay@192.168.1.200 hostname
```

Verify the automatic tunnel:

```bash
lsof -nP -iTCP:46319 -sTCP:LISTEN
```

Verify Kubernetes access:

```bash
kubectl --kubeconfig ~/.kube/gitops-admin-config get nodes
kubectl --kubeconfig ~/.kube/gitops-admin-config get applications -n argocd
```

Expected:

- Both Kubernetes nodes are Ready.
- `nginx-dev` is Synced and Healthy.

### 4. Troubleshoot Mac-to-Kubernetes connectivity

Check the LaunchAgent:

```bash
launchctl print gui/$(id -u)/com.gitops.k8s-tunnel
```

If it is not loaded, start it:

```bash
launchctl bootstrap gui/$(id -u) \
  ~/Library/LaunchAgents/com.gitops.k8s-tunnel.plist
```

If the agent is loaded but not working, verify Windows SSH connectivity and check that Docker Desktop and the kind cluster are running.

If the Windows IP address or kind API port changes, update the tunnel configuration and kubeconfig as appropriate.

### 5. Verify the Git repository and CI pipeline

On Mac:

```bash
cd ~/Documents/devops/gitops-admin-lab

git status -sb
git fetch origin
git log -1 --oneline
```

GitHub Actions workflow:

```text
.github/workflows/ci.yml
```

The CI workflow performs:

1. Repository checkout
2. Helm installation
3. Helm chart linting
4. Kubernetes manifest rendering for Dev, QA, UAT, and Production

GitHub Actions validates application configuration. Argo CD handles Kubernetes deployments.

### 6. Daily shutdown

No special Kubernetes shutdown is required for ordinary Mac logout.

The automatic SSH tunnel stops when the Mac user session ends and starts again at login.

For longer lab breaks, Docker Desktop may be stopped after confirming that no workloads are actively needed.

**Important:** Never commit kubeconfig files, private SSH keys, Azure credentials, or Terraform state files containing sensitive data to GitHub.ironment configuration is maintained in `gitops/<environment>/values.yml`.

## Immutable Image Strategy

The Helm chart supports image references using either a tag or a SHA-256 digest.

The planned CI/CD strategy is:

1. Build the container image once using GitHub Actions.
2. Tag the image with the Git commit SHA.
3. Push the image to Azure Container Registry.
4. Capture the immutable image digest.
5. Update the GitOps environment configuration through controlled Git changes.
6. Promote the same image digest across Dev, QA, UAT, and Production.
7. Allow Argo CD to reconcile the approved configuration with Kubernetes.

## Security and Deployment Controls

Planned production-style controls include:

- GitHub Actions permissions restricted to least privilege
- Azure OIDC authentication instead of long-lived credentials
- GitHub Environments and production approval gates
- Azure Key Vault integration for application secrets
- Immutable image references
- Git-based change approvals and audit history
- Argo CD drift detection and automated reconciliation

## Project Status

**Day 1 — In Progress**

Completed repository setup, Helm chart reuse, digest rendering support, and four-environment configuration validation.

Next milestone: Implement and validate the first GitHub Actions CI workflow.

---

*This repository is a hands-on GitOps Administrator interview preparation lab. Azure cloud integrations and production controls are implemented progressively and are not assumed to be operational until verified.*