# Kiratech — Cloud Native Support Engineer Junior Challenge

**English** | [Italiano](README.it.md)

WordPress and MySQL deployed on local Kubernetes, with persistent storage, health checks, custom container images, a Helm chart and documented troubleshooting.

**Status as of 30 October 2026:** lab implementation and documentation completed and published, including Ingress. Linked reports distinguish executed checks from limitations; demonstration preparation is separate.

## Architecture

WordPress is an existing open source CMS. Its container includes Apache and PHP and connects to MySQL through an internal Service.

- Two Deployments, each with one replica and the Recreate strategy.
- Configuration through a ConfigMap and credentials through a Secret.
- Two PVCs: MySQL data at /var/lib/mysql and WordPress content at /var/www/html/wp-content.
- Direct local port-forward access, plus an optional Traefik Ingress lab.
- Startup, readiness and liveness probes.
- CPU and memory requests and limits.

The Helm chart derives from the working Kubernetes manifest. It uses release-specific names and exposes images, pull policies, database settings, storage sizes, resource limits and the existing Secret name through values. Lab override files select the baseline or corrected image.

The cluster has a single node. This is a lab without high availability; replacing Pods causes a brief interruption.

## Environment

Windows, Ubuntu on WSL2, Docker Desktop and Minikube.
Profile: kiratech. Kubernetes: v1.36.1. Helm: v4.3.1.

Verified configuration: [docs/local-setup.md](docs/local-setup.md).

## Project progression and results

| Stage | Work and result | Detailed record |
| --- | --- | --- |
| 1. Initial deployment and credentials | WordPress/MySQL manifests; diagnose HTTP 500 and MySQL authentication, reproduce the credential-newline failure and verify corrected fresh installation | [MySQL case](docs/incidents/mysql-initialization.md) |
| 2. Persistence | Replace WordPress and MySQL Pods separately; retain article, image and volume bindings | [Verification](docs/persistence-test.md) |
| 3. Published-image patch | Diagnose the PHP version and replace the image: PHP 8.3.35 → 8.3.36; WordPress also changes 7.1.2 → 7.1.3 | [Security lab](labs/security/README.md) |
| 4. Custom build and Helm patch | Inspect the Dockerfile, update the PHP/Apache base and build; WordPress remains 7.1.3. Chart templates and values drive installation/upgrade, preserving content and upload hashes | [Build and Helm](labs/security-build/README.md) |
| 5. Missing image | Incorrect tag with Never policy causes ErrImageNeverPull; diagnose and recover, including the discrepancy between rollback status and available resources | [Image incident](docs/incidents/image-not-available.md) |
| 6. Clean checkout | Install, verify the application and remove it using new credentials/PVCs and existing cluster/images | [Report](docs/fresh-checkout-test.md) |
| 7. Ingress and HTTP 503 | Traefik and hostname access; incorrect Service selector with Ready Pods, endpoint diagnosis and recovery without restarts | [Ingress lab](labs/ingress/README.md) |

Both patching paths are security troubleshooting and are included in the
runbook alongside the MySQL, missing-image and Ingress cases.

## Documentation entry points

| Goal | Start here |
| --- | --- |
| Understand components and traffic | [Architecture and diagrams](docs/architecture.md) |
| Install the project | [Installation guide](docs/delivery-workflow.md) |
| Diagnose and correct a problem | [L2 runbook: five cases](docs/runbook.md) |
| Reproduce labs and inspect evidence | [Complete documentation map](docs/README.md) |
| Review proposals and method | [Krateo](docs/krateo-proposal.md), [proposed pipeline](docs/delivery-workflow.md#proposed-cicd-workflow), [AI usage](docs/ai-usage.md) |

The original manifest is in [k8s/](k8s/stack.yaml); reusable packaging is in
[charts/](charts/kiratech-wordpress/). Labs are in labs/, procedures and
reports in docs/, and recorded outputs in docs/evidence/.

## Installation from scratch

Start with [installation and delivery workflow](docs/delivery-workflow.md).
It links the complete lab procedure and distinguishes the manual workflow
from the proposed CI/CD pipeline.

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

These commands resume existing installations. The [custom-image lab guide](labs/security-build/README.md) contains build, fresh-installation, backup, upgrade, verification and removal instructions. Installation and removal from a clean checkout were verified using existing images (see [test report](docs/fresh-checkout-test.md)); do not rerun credential initialization against an existing database.

## Optional Ingress lab

The [Ingress lab guide](labs/ingress/README.md) covers Traefik installation,
hostname-based access and an additional routing incident.

- WordPress remained Ready while an incorrect Service selector caused HTTP 503.
- EndpointSlice inspection and direct application access isolated the fault.
- Correcting the selector restored HTTP 200 without restarting the Pods.
- A reusable smoke script checks HTTP status and expected application content.

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
- Clean-checkout installation and removal were verified using existing images and the existing cluster. A full rebuild and replay of all labs were not performed.
- Custom-image builds use pinned bases, but external package downloads prevent a claim of bit-for-bit reproducibility.
- The custom-image lab records a formatting-only LF normalization made after its deployment tests.

## Demonstration preparation

- Rehearse the L2 runbook and the documented operational scenarios.
- Prepare the technical demonstration using the published repository.

## AI assistance

AI supported explanations, source analysis, Dockerfile adaptation, manifest and Helm-chart preparation, diagnostic commands and documentation. Commands were executed manually and conclusions were checked using actual output and official advisories.

See [AI usage and manual verification](docs/ai-usage.md) for the assistance received, checks performed and remaining limitations. Unexecuted activities are not presented as tested.

## Software origin

- Image packaging: https://github.com/docker-library/wordpress
- Adapted Kubernetes example: https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/

Changes concern configuration, deployment, verification and operational procedures. No new WordPress application was developed.
