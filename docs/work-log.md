# Work log

[Documentation home](README.md) · [Project overview](../README.md)

Chronological record of implementation, troubleshooting and verification.
Updated on 2026-11-02 to consolidate the missing sessions from the existing
reports, evidence and Git history. No deployment tests were rerun for this update.

Session dates identify when work was performed; commit dates can be later.
The original notes are retained below. Their next steps and pending items
refer to their dated state; subsequent entries record the follow-up.
See the [documentation map](README.md) for procedures and detailed reports.

## 2026-10-23 — Local environment checks

### Verified environment
- Host: Windows, Intel Core i7-9750H, 16 GB RAM.
- WSL version: 2.7.12.0.
- Linux distribution: Ubuntu 26.04 LTS on WSL2.
- Docker Desktop: 4.89.0.
- Docker Engine: 29.7.2, linux/amd64.
- Git: 2.53.0.
- kubectl client: v1.36.1.
- Bundled Kustomize: v5.8.1.
- minikube: command not available.

### Troubleshooting performed
1. Docker was initially unreachable from PowerShell.
   After starting Docker Desktop, docker version returned Client and Server.
2. Docker was initially unavailable from Ubuntu.
   Docker Desktop WSL integration was enabled.
3. Ubuntu then reported permission denied for /var/run/docker.sock.
   The socket belonged to root:docker.
   The user was registered in the docker group, but the active shell
   did not include that group.
   Running newgrp docker activated the group in the shell.
   docker version then returned Client and Server successfully.

### Execution test
- Command: docker run --rm hello-world
- Observed result: Hello from Docker!
- Container execution from Ubuntu: verified.

### Next steps
- Prepare the local Kubernetes cluster.
- Record installation commands and selected versions.

### Same-day cluster setup follow-up
- Installed minikube and created the kiratech cluster with Kubernetes 1.36.1.
- Verified the node, system Pods and default local StorageClass.
- Recorded the initial cluster configuration and storage limitations.

Record: [local setup](local-setup.md). Git record: c24e729 (2026-10-23).

## 2026-10-26 — First application deployment
- Deployed WordPress and MySQL using k8s/stack.yaml.
- WordPress image contains PHP 8.3.36; image digest is pinned.
- Credentials are stored locally in .local/ and supplied through a Secret.
- WordPress initially returned HTTP 500 and failed its startup probe.
- PHP connection test returned MySQL error 1045.
- Administrator query confirmed that the wordpress database user was absent.
- Created the database if missing, the wordpress user and database permissions.
- WordPress rollout then completed successfully.
- Completed web installation and logged into the dashboard.
- Published "Kiratech persistence test" with text and an uploaded image.
- Verified that both are visible on the public post.
- Pending: investigate why initial MySQL setup did not create the user.
- Pending: verify persistence after Pod replacement and clean installation.


## 2026-10-27 — MySQL reproduction, persistence and published-image patch

### MySQL initialization and clean installation
- Reproduced initialization failure with fresh storage in wordpress-check.
- Found trailing LF characters in both credential files. A comparison in
  wordpress-check-clean removed only the trailing LF from credential copies
  and used fresh PVCs with otherwise unchanged workload configuration.
- MySQL created the database, application user and grants automatically;
  the application-user SELECT 1 check succeeded.
- Completed WordPress installation and Dashboard login in the clean namespace.
- This closed the clean-installation follow-up from 26 October. The exact
  internal password-parsing mechanism was not investigated.

Records: [MySQL incident](incidents/mysql-initialization.md),
[clean installation](verification/clean-install-test.md),
[failed initialization log](evidence/mysql-initialization/mysql-init-failed.log) and
[clean initialization log](evidence/mysql-initialization/mysql-init-clean.log).

### Persistence
- Replaced the WordPress Pod and then the MySQL Pod in the original namespace.
- Verified that the published article and uploaded image remained visible.
- Confirmed both PVCs stayed Bound to the same volumes.
- This completed the Pod-replacement persistence check pending on 26 October.

Record: [persistence verification](verification/persistence-test.md).

### Security troubleshooting through published-image replacement
- Created the isolated wordpress-security lab with the affected baseline.
- Checked PHP 8.3.35 in CLI and the web runtime, including apache2handler,
  against the vendor advisories documented in the security report.
- Captured private SQL/content backups and baseline image, runtime, storage
  and upload-hash evidence before applying the corrected manifest.
- Replaced the published WordPress image: PHP 8.3.35 -> 8.3.36,
  WordPress 7.1.2 -> 7.1.3 and Apache 2.4.68 -> 2.4.69.
- Verified rollout, CLI/web versions, retained PVC bindings, matching upload
  hashes and visible article/image. Reviewed a 60-line post-update log sample.
- This was security diagnosis and remediation; no exploit was executed.

Record: [published-image security lab](../labs/security/README.md).
Evidence includes [versions before](evidence/security-image/security-versions-before.txt)
and [after](evidence/security-image/security-versions-after.txt).
Also added the Italian and English project overviews.
Git records: 501f15b, ddf0c9d, 02d45e2, 3ac3566 and 14165f5.

## 2026-10-28 — Dockerfile investigation, custom builds and Helm installation

- Simulated the absence of a corrected WordPress image while a corrected
  PHP/Apache base was available. An updated published WordPress image
  actually existed and had already been tested in the previous lab.
- Inspected upstream WordPress packaging and retained its source revision
  and license. Prepared Dockerfile variants differing only in FROM:
  pinned PHP/Apache 8.3.35 and 8.3.36 bases, both with WordPress 7.1.3.
- Built both custom images and checked their bundled versions. This changed
  the base dependency and rebuilt the image; no PHP source patch was written.
- Installed Helm and adapted stack.yaml into reusable chart templates and
  values, including release-specific resource names and selectors.
- Linted both configurations and compared rendered manifests; only the
  selected WordPress image differed between the two lab configurations.
- Loaded the images into Minikube and checked node image availability.
- Installed release patch-lab in wordpress-build with the affected values.
  Helm revision 1 was installed on 28 October; created the test article/image
  before the subsequent upgrade.

Record: [custom-image build and Helm lab](../labs/security-build/README.md).
The [Helm history](evidence/security-build/helm-history.txt) records the
installation date. Implementation was committed on 29 October as 5b790e8;
that later commit date does not change the build/installation session date.

## 2026-10-29 — Helm patch, missing-image incident and clean-checkout validation

### Security troubleshooting through a custom-image Helm upgrade
- Resumed the cluster and confirmed WordPress 7.1.3 / PHP 8.3.35.
- Exported the database, archived wp-content, checked the dump footer/archive
  integrity and recorded upload hashes and resource identities.
- Upgraded patch-lab using values-patched.yaml; Helm revision 2 was deployed.
- Confirmed WordPress remained 7.1.3 and PHP became 8.3.36 in CLI and the web.
- Confirmed the MySQL Pod and PVC bindings were retained, upload hashes
  matched and the article/image survived.
- Normalized wp-config-docker.php line endings after the deployment tests;
  the tested images were not rebuilt after that formatting-only change.

Record: [custom-image lab](../labs/security-build/README.md).
Evidence: [build and upgrade outputs](evidence/security-build/).

### Missing-image troubleshooting
- Installed a healthy image-lab release in wordpress-troubleshooting.
- Injected a nonexistent image tag with imagePullPolicy Never.
- Observed ErrImageNeverPull, an unstarted WordPress container and a Helm
  upgrade timeout; used Pod events, image policy and node image inventory
  to diagnose the missing image reference.
- Attempted rollback. Helm reported Progress deadline exceeded, while
  subsequent inspection showed the intended image and Ready resources.
- Applied the correct values through a new upgrade; revision 4 was deployed.
  Verified WordPress/PHP versions, retained PVCs and installer HTTP 200.
- The cause of the rollback wait discrepancy remains unconfirmed. A full
  WordPress installation was not part of this incident's recovery test.

Record: [missing-image incident](incidents/image-not-available.md).
Evidence: [diagnosis and recovery](evidence/image-missing/).

### Installation/removal replay and documentation
- Cloned source commit 387eb17 into a separate local checkout without .local.
- Created new credentials, namespace and PVCs; reused the existing cluster
  and previously built/loaded images.
- Installed the chart, verified database access and versions, completed
  WordPress setup and published an article with an uploaded image.
- Verified HTTP 200 and browser content; uninstalled the validation release
  and removed its volumes and separately created namespace.
- Added the runbook, architecture, conceptual Krateo integration proposal,
  AI usage record and installation entry point with a proposed CI/CD workflow.
- Published the repository to GitHub after configuring SSH authentication.
  The local clean-checkout test itself did not test remote cloning.

Records: [checkout validation](verification/fresh-checkout-test.md),
[architecture](architecture.md), [Krateo proposal](krateo-proposal.md),
[AI usage](ai-usage.md) and [delivery workflow](delivery-workflow.md).
Git records include 5b790e8, c35fec7, 8209949, 010879d and b5b99a1.

## 2026-10-30 — Ingress, routing diagnosis and documentation consolidation

### Controller and application setup
- Added optional Ingress support to the chart and installed Traefik.
- Corrected chart value paths after schema/live-resource checks:
  log/accessLog and service.spec.type for the selected Traefik chart version.
- Investigated WordPress probe failures: database connectivity succeeded,
  while an installer response took 1.015 seconds against a one-second probe
  timeout. Set startup/readiness timeouts to five seconds and verified readiness.
- Recovered an interrupted Helm installation left in pending-install:
  reapplied revision 1 through rollback, then upgraded with readiness waiting.
- Completed WordPress setup through wordpress.lab.test:8086 using a local
  port-forward to Traefik and published the routing-verification article.

### Ready Pod with Ingress HTTP 503
- Changed the WordPress Service selector to frontend-typo in the isolated lab.
- Observed HTTP 503 and empty EndpointSlice backends while WordPress stayed Ready.
- A request inside the application Pod returned HTTP 200, supporting a routing
  diagnosis rather than an application HTTP failure.
- Restored the selector to frontend. Endpoints, HTTP 200 and expected content
  returned without changing Pod identities or restart counts.
- Added a reusable smoke script and verified it on the recovered application.
  The script was created after the fault experiment, not tested during HTTP 503.

### Final configuration and documentation
- Bumped the chart to 0.2.0. Both default and Ingress values passed lint;
  the final ingress-lab upgrade was revision 4, deployed.
- Recorded final resources and a successful HTTP/content smoke check.
- Updated architecture, README files, runbook and AI usage; committed and
  published the Ingress work as c13216e.
- Reviewed documentation organization and added the documentation map.
  Included both security-remediation paths in the five-case runbook,
  clarified diagram scope and corrected stale completion statements.
- Published the documentation review as e7efc75. The work-log gap was
  identified afterwards and is addressed by the consolidation below.

Records: [Ingress guide](../labs/ingress/README.md),
[controller/install evidence](evidence/ingress/),
[routing incident evidence](evidence/ingress-selector/),
[documentation map](README.md) and [runbook](runbook.md).

## 2026-11-02 — Work-log consolidation

- Cross-checked the existing reports, Helm histories and Git log to add the
  missing 27–30 October sessions and the same-day cluster setup follow-up.
- Retained the original session notes and connected their pending items
  to the subsequent verification results.
- Updated the documentation-map description to reflect the complete chronology.
- Consolidated the existing published-image, custom-build and Ingress cases into
  dedicated [incident reports](incidents/), and linked them from the runbook,
  lab guides and indexes. This reorganized existing results, without new tests.
- Grouped evidence captures by scenario and added ordered reading guides;
  updated references while preserving every original capture byte-for-byte.
- Expanded the architecture document with the installation map, resource
  ownership, image delivery flow and complete Ingress request path, checked
  against chart 0.2.0 and the existing lab records.
- This was a documentation correction; no cluster operations, new exploitation
  tests or additional deployment verification were performed.

## 2026-11-02 — Delivery documentation follow-up

- Added the WordPress choice rationale, including the reported image-runtime
  security issue, to both language overviews.
- Distinguished the WordPress application source mirror from its Docker
  image-packaging repository.
- Added repository cloning and tool preflight commands to the installation
  entry point, with the official Helm installation/verification reference.
- Added an eleven-step demonstration guide covering installation, access,
  diagnostics, a reversible resource change, recovery and removal boundaries,
  Krateo and AI verification.
- Documented the chart's startup-only ConfigMap environment behavior and
  explicit restart procedure, including initialized-database constraints.
- Updated overview dates and the conceptual Krateo example to chart 0.2.0.
- Checked relative Markdown paths/anchors, Bash-block syntax and Git whitespace;
  the patch was also checked and applied to a clean copy of its base revision.
- These changes are documentation only. The new demonstration sequence,
  resource-change example and ConfigMap procedure have not been executed
  against the cluster; existing evidence remains unchanged.

## 2026-11-02 — Demo resource-change verification

- Verified the custom-image release with CPU request 100m before the change.
- Captured active Helm values and used them with the current chart for both upgrades.
- Changed the WordPress CPU request to 150m: Helm revision 3 deployed.
- Restored the request to 100m: revision 4 deployed.
- Confirmed the corrected image reference, unchanged upload hashes and
  unchanged PVC identities/volume bindings.
- Checked direct application HTTP 200 and the expected article title.
- Final Deployments were available and the WordPress Pod was Ready with zero restarts.
- Added the [test report](verification/demo-change-test.md) and the submitted
  [session capture](evidence/demo-change/README.md), then updated the demo guide.
- This verifies the resource-change step; the full presentation sequence
  has not been rehearsed. CPU restoration did not roll back the chart version.

## Verification boundaries retained

- Security work assessed versions/configuration and verified remediation;
  no exploit was executed, and absence of all vulnerabilities was not established.
  The separate PHP advisory follow-up remains recorded in the security lab guides.
- Backup restoration, high availability and a complete new-machine rebuild
  were not tested. Clean-checkout validation reused the cluster and images.
- Krateo and CI/CD remain proposals, not deployed integrations.
- The Ingress lab did not test TLS, public exposure or its removal procedure.
- Detailed reports preserve the evidence and unresolved questions. This log
  summarizes those results and does not turn suggested procedures into executed tests.
