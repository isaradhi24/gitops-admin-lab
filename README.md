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

## Multi-Environment Configuration

The same Helm chart is used across all four environments, with different replica counts.

| Environment | Replicas |
|---|---:|
| Dev | 1 |
| QA | 2 |
| UAT | 2 |
| Production | 3 |

Environment configuration is maintained in `gitops/<environment>/values.yml`.

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