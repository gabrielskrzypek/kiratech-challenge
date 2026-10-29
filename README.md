# Kiratech — Cloud Native Support Engineer Junior Challenge

**English** | [Italiano](README.it.md)

WordPress and MySQL deployed on local Kubernetes, with persistent storage, health checks, custom container images, a Helm chart and documented troubleshooting.

**Status as of 29 October 2026:** the custom-image patch lab and Helm upgrade are implemented, functionally verified and documented. The final challenge submission is still in progress.

## Architecture

WordPress is an existing open source CMS. Its container includes Apache and PHP and connects to MySQL through an internal Service.

- Two Deployments, each with one replica and the Recreate strategy.
- Configuration through a ConfigMap and credentials through a Secret.
- Two PVCs: MySQL data at /var/lib/mysql and WordPress content at /var/www/html/wp-content.
- Access through ClusterIP Services and local port-forward.
- Startup, readiness and liveness probes.
- CPU and memory requests and limits.

The Helm chart derives from the working Kubernetes manifest. It uses release-specific names and exposes images, pull policies, database settings, storage sizes, resource limits and the existing Secret name through values. Lab override files select the baseline or corrected image.

The cluster has a single node. This is a lab without high availability; replacing Pods causes a brief interruption.

## Environment

Windows, Ubuntu on WSL2, Docker Desktop and Minikube.
Profile: kiratech. Kubernetes: v1.36.1. Helm: v4.3.1.

Verified configuration: [docs/local-setup.md](docs/local-setup.md).

## Verified work

- WordPress web installation and Dashboard access.
- Fresh installation without manual database repairs.
- Post and image persistence after replacing the Pods separately.
- Reproduction and diagnosis of the MySQL initialization failure.
- Correction of credentials containing trailing newlines.
- Published-image lab: PHP 8.3.35 → 8.3.36, WordPress 7.1.2 → 7.1.3, Apache 2.4.68 → 2.4.69.
- Custom-image lab: built two WordPress 7.1.3 images using PHP/Apache bases pinned by version and digest; PHP 8.3.35 → 8.3.36.
- Helm chart validation and rendered-manifest comparison: only the WordPress image differed between the lab configurations.
- Helm installation and upgrade: patch-lab moved from revision 1 to revision 2 in namespace wordpress-build.
- Custom-image upgrade: PHP 8.3.36 verified through CLI and the web; MySQL and PVCs retained; article and image preserved with matching upload hashes.
- PHP version checks using both CLI and the web interface.
- Post preservation and matching SHA-256 hashes of uploaded files after the update.

## Documentation

| Topic | File |
| --- | --- |
| Local environment | [docs/local-setup.md](docs/local-setup.md) |
| Main manifest | [k8s/stack.yaml](k8s/stack.yaml) |
| Helm chart | [charts/kiratech-wordpress/](charts/kiratech-wordpress/) |
| MySQL incident | [docs/incidents/mysql-initialization.md](docs/incidents/mysql-initialization.md) |
| Missing-image incident | [docs/incidents/image-not-available.md](docs/incidents/image-not-available.md) |
| L2 runbook | [docs/runbook.md](docs/runbook.md) |
| Architecture and diagram | [docs/architecture.md](docs/architecture.md) |
| Krateo proposal | [docs/krateo-proposal.md](docs/krateo-proposal.md) |
| AI usage and verification | [docs/ai-usage.md](docs/ai-usage.md) |
| Fresh installation | [docs/clean-install-test.md](docs/clean-install-test.md) |
| Persistence | [docs/persistence-test.md](docs/persistence-test.md) |
| Published-image security update | [labs/security/README.md](labs/security/README.md) |
| Custom-image build and Helm upgrade | [labs/security-build/README.md](labs/security-build/README.md) |
| Custom-image lab evidence | [docs/evidence/security-build/](docs/evidence/security-build/) |
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

For the custom-image Helm lab, in a separate terminal:

    helm list --kube-context kiratech -n wordpress-build
    kubectl --context=kiratech -n wordpress-build get deployments,pods,pvc
    kubectl --context=kiratech -n wordpress-build port-forward service/patch-lab-wordpress 8083:80

Open http://localhost:8083; administration is at http://localhost:8083/wp-admin/.
At the last verification, this release used the custom PHP 8.3.36 image.

These commands resume existing installations. The [custom-image lab guide](labs/security-build/README.md) contains build, fresh-installation, backup, upgrade, verification and removal instructions. A full replay from a fresh checkout remains pending; do not rerun credential initialization against an existing database.

## Credentials and data

Credentials and backups are kept under .local/, excluded from Git.
Changing a Secret does not change existing MySQL account passwords.

The main installation retains its original credentials after the manual repair. The fresh-installation test and both security labs use credentials without trailing newlines. The Helm lab uses its own credential files and Secret in wordpress-build. Values files contain the Secret name, not passwords.

Storage is local to the Minikube node. Deleting PVCs or the cluster can cause data loss.

## Verification limits

- No exploit was executed and remote code execution was not demonstrated.
- Backup restoration was not tested. In the missing-image case, rollback restored Kubernetes resources but Helm reported failure; a subsequent upgrade completed recovery.
- The reviewed post-update log in the published-image lab is a 60-line sample.
- The update does not guarantee the absence of other vulnerabilities.
- The additional PHP advisory of 23 October remains a follow-up item.
- The complete project has not yet been verified from a fresh Git checkout.
- Custom-image builds use pinned bases, but external package downloads prevent a claim of bit-for-bit reproducibility.
- The custom-image lab records a formatting-only LF normalization made after its deployment tests.

## Remaining work before final submission

- Final review and rehearsal of the L2 runbook and its two documented operational scenarios.
- Consolidate project-wide installation, verification and removal instructions; the custom-image lab procedure is already documented.
- Validation from a fresh Git checkout.
- Repository sharing and technical demonstration rehearsal.

## AI assistance

AI supported explanations, source analysis, Dockerfile adaptation, manifest and Helm-chart preparation, diagnostic commands and documentation. Commands were executed manually and conclusions were checked using actual output and official advisories.

See [AI usage and manual verification](docs/ai-usage.md) for the assistance received, checks performed and remaining limitations. Unexecuted activities are not presented as tested.

## Software origin

- Image packaging: https://github.com/docker-library/wordpress
- Adapted Kubernetes example: https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/

Changes concern configuration, deployment, verification and operational procedures. No new WordPress application was developed.
