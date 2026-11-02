# Kiratech — Cloud Native Support Engineer Junior Challenge

**English** | [Italiano](README.it.md)

WordPress and MySQL on local Kubernetes: deployment, persistence, security
remediation and operational troubleshooting, with recorded evidence.

## Why WordPress

I chose WordPress because its web tier, separate database and uploaded files
provide concrete checks for configuration, dependency failures and persistence.
A recently reported security issue affecting the PHP runtime in a WordPress
image also motivated the choice, following the senior's suggestion.

The security work covers two correction paths: replacing the published image
and inspecting its Dockerfile to rebuild with a corrected PHP/Apache base.
WordPress is the existing application; docker-library/wordpress supplies the
image packaging adapted in this project. No new CMS was developed.

## Architecture and environment

WordPress runs with Apache/PHP and connects to MySQL through an internal Service.
The original Kubernetes manifest was then adapted into a Helm chart with
release-specific names and configuration through values.

- Two single-replica Deployments using Recreate, with health probes and resource requests/limits.
- Configuration in a ConfigMap; database credentials referenced from a separately created Secret.
- Separate PVCs for MySQL data and WordPress content, including uploads.
- Local access through port-forward; optional hostname routing through Traefik Ingress.

Tested environment: Ubuntu 26.04 on WSL2, Docker Desktop, Minikube 1.39.0,
Kubernetes 1.36.1 and Helm 4.3.1. Cluster profile/context: `kiratech`.
See [architecture and diagrams](docs/architecture.md) and [local setup](docs/local-setup.md).

## Work performed and results

| Stage | Result | Record |
| --- | --- | --- |
| Initial deployment | Diagnosed HTTP 500 and MySQL error 1045; reproduced initialization failure with trailing-newline credentials and verified a corrected fresh installation | [MySQL incident](docs/incidents/mysql-initialization.md) |
| Persistence | Article and uploaded image survived separate WordPress and MySQL Pod replacement | [Persistence test](docs/persistence-test.md) |
| Published-image correction | Replaced the affected image: PHP 8.3.35 → 8.3.36; WordPress also changed 7.1.2 → 7.1.3 | [Security incident](docs/incidents/php-security-image-update.md) |
| Custom build and Helm | Changed the pinned PHP/Apache base in the Dockerfile, rebuilt and upgraded through Helm values; WordPress remained 7.1.3 and upload hashes matched | [Build and Helm incident](docs/incidents/php-security-custom-build.md) |
| Missing image | Diagnosed ErrImageNeverPull from an incorrect tag with Never policy; recovered the workload and reconciled Helm state after a reported rollback failure | [Image incident](docs/incidents/image-not-available.md) |
| Clean checkout | Installed, checked the application and removed a separate instance using new credentials/PVCs and existing cluster/images | [Checkout test](docs/fresh-checkout-test.md) |
| Ingress routing | Diagnosed HTTP 503 with Ready Pods: a Service selector matched no backends. Correcting it restored access without Pod restarts | [Ingress incident](docs/incidents/ingress-service-selector.md) |

The two security cases address the same assessed PHP issue through different
remediation paths. All five troubleshooting cases are included in the runbook.

## Use the project

Installation requires Bash, Git, Python 3, Docker, kubectl, Minikube and Helm.
Start Docker Desktop before running the WSL commands.

| Goal | Instructions |
| --- | --- |
| Clone, check tools and install | [Installation entry point](docs/delivery-workflow.md); [custom-image lab](labs/security-build/README.md) for build/load, credentials, install and upgrade |
| Verify or demonstrate | [Demonstration guide](docs/demo.md), including access and runtime checks; the full sequence has not been rehearsed |
| Diagnose a problem | [L2 runbook](docs/runbook.md): MySQL, published-image correction, custom build, missing image and Ingress |
| Set up Ingress | [Traefik and routing lab](labs/ingress/README.md) |
| Remove an installation | [Removal and data loss](labs/security-build/README.md#removal-and-data-loss); [verified cleanup](docs/fresh-checkout-test.md#removal) |
| Browse all records | [Documentation map](docs/README.md) and [evidence index](docs/evidence/README.md) |

Source layout: [original manifest](k8s/stack.yaml), [Helm chart](charts/kiratech-wordpress/),
[labs](labs/) and [documentation](docs/README.md).

## Credentials, data and limits

Credential files and backups stay under `.local/`, excluded from Git.
Values files reference a Secret name, not passwords. Changing a Secret does
not rotate passwords in an initialized MySQL database; see the
[configuration-update procedure](docs/runbook.md#configuration-updates-and-running-pods).

- Single-node lab with local storage and Recreate interruptions. PVC or cluster deletion can destroy data.
- Security checks assessed versions and verified application behavior; no exploit was executed and the update does not establish absence of other vulnerabilities. The additional PHP advisory of 23 October remains unassessed.
- Backup restoration, high availability, TLS/public Ingress and a complete new-machine rebuild were not tested. Clean-checkout validation reused existing images and cluster; builds are not claimed to be bit-for-bit reproducible.
- [Krateo integration](docs/krateo-proposal.md) and [CI/CD](docs/delivery-workflow.md#proposed-cicd-workflow) are proposals, not implemented integrations.

Detailed reports retain the scope, evidence and limitations of each test.

## AI assistance and sources

AI assisted with explanations, analysis, configuration, commands and documentation.
Commands were executed manually and results checked against actual outputs,
browser observations and vendor advisories. The [AI usage record](docs/ai-usage.md)
explains the assistance, corrections and verification limits.

- Application source mirror: https://github.com/WordPress/WordPress
- Docker image packaging: https://github.com/docker-library/wordpress
- Adapted deployment example: https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/
- [Complete source references](docs/sources.md).
