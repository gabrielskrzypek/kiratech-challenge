# Kiratech — Cloud Native Support Engineer Junior Challenge

**English** | [Italiano](README.it.md)

WordPress and MySQL deployed on local Kubernetes, with persistent storage, health checks and documented troubleshooting.

**Status as of 27 October 2026:** work in progress, prepared for an intermediate technical review. The final submission is not yet complete.

## Architecture

WordPress is an existing open source CMS. Its container includes Apache and PHP and connects to MySQL through an internal Service.

- Two Deployments, each with one replica and the Recreate strategy.
- Configuration through a ConfigMap and credentials through a Secret.
- Two PVCs: MySQL data at /var/lib/mysql and WordPress content at /var/www/html/wp-content.
- Access through ClusterIP Services and local port-forward.
- Startup, readiness and liveness probes.
- CPU and memory requests and limits.

The cluster has a single node. This is a lab without high availability; replacing Pods causes a brief interruption.

## Environment

Windows, Ubuntu on WSL2, Docker Desktop and Minikube.
Profile: kiratech. Kubernetes: v1.36.1.

Verified configuration: [docs/local-setup.md](docs/local-setup.md).

## Verified work

- WordPress web installation and Dashboard access.
- Fresh installation without manual database repairs.
- Post and image persistence after replacing the Pods separately.
- Reproduction and diagnosis of the MySQL initialization failure.
- Correction of credentials containing trailing newlines.
- Lab update: PHP 8.3.35 → 8.3.36, WordPress 7.1.2 → 7.1.3, Apache 2.4.68 → 2.4.69.
- PHP version checks using both CLI and the web interface.
- Post preservation and matching SHA-256 hashes of uploaded files after the update.

## Documentation

| Topic | File |
| --- | --- |
| Local environment | [docs/local-setup.md](docs/local-setup.md) |
| Main manifest | [k8s/stack.yaml](k8s/stack.yaml) |
| MySQL incident | [docs/incidents/mysql-initialization.md](docs/incidents/mysql-initialization.md) |
| Fresh installation | [docs/clean-install-test.md](docs/clean-install-test.md) |
| Persistence | [docs/persistence-test.md](docs/persistence-test.md) |
| Security update | [labs/security/README.md](labs/security/README.md) |
| Evidence | [docs/evidence/](docs/evidence/) |
| Work history | [docs/work-log.md](docs/work-log.md) |
| Upstream references | [docs/sources.md](docs/sources.md) |

## Resume the existing installation

Start Docker Desktop and verify Docker access from Ubuntu.
From the repository root:

    minikube start --profile kiratech
    kubectl --context=kiratech --namespace=wordpress get pods,pvc
    kubectl --context=kiratech --namespace=wordpress port-forward service/wordpress 8080:80

Open http://localhost:8080. Keep port-forward running; Ctrl+C closes the tunnel.

For the security lab, in a separate terminal:

    kubectl --context=kiratech --namespace=wordpress-security port-forward service/wordpress 8082:80

Open http://localhost:8082. The lab currently uses the corrected image.

These commands resume existing installations. Complete fresh-installation, verification and removal instructions are still being consolidated.

## Credentials and data

Credentials and backups are kept under .local/, excluded from Git.
Changing a Secret does not change existing MySQL account passwords.

The main installation retains its original credentials after the manual repair. The fresh-installation test and security lab use credentials without trailing newlines.

Storage is local to the Minikube node. Deleting PVCs or the cluster can cause data loss.

## Verification limits

- No exploit was executed and remote code execution was not demonstrated.
- Backup restoration and rollback were not tested.
- The reviewed post-update log is a 60-line sample.
- The update does not guarantee the absence of other vulnerabilities.
- The additional PHP advisory of 23 October remains a follow-up item.
- The complete project has not yet been verified from a fresh Git checkout.

## Remaining work before final submission

- Second operational troubleshooting scenario and final runbook.
- Reproducible installation, verification and removal instructions.
- Validation from a fresh Git checkout.
- Architecture diagram.
- Conceptual Krateo proposal.
- Consolidated AI usage and manual-verification record.
- Repository sharing and technical demonstration rehearsal.

## AI assistance

AI supported explanations, source analysis, manifest preparation, diagnostic commands and documentation. Commands were executed manually and conclusions were checked using actual output and official advisories.

Unexecuted activities are not presented as tested. The consolidated record is still pending; the MySQL incident and security-lab documents already describe specific results and limitations.

## Software origin

- Image packaging: https://github.com/docker-library/wordpress
- Adapted Kubernetes example: https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/

Changes concern configuration, deployment, verification and operational procedures. No new WordPress application was developed.
