# Documentation map

Start with the project overview in [English](../README.md) or
[Italian](../README.it.md). This map groups documents by purpose; evidence
and source paths are retained so existing references remain valid.

## Reading order

1. [Architecture](architecture.md): components, persistence and the separate
   direct-access / Ingress diagrams.
2. [Installation entry point](delivery-workflow.md): prerequisites and the
   route to a new installation, distinct from resuming existing labs.
3. [L2 runbook](runbook.md): all five troubleshooting and remediation cases,
   including both security-update paths.
4. The relevant detailed report or lab below for reproduction and evidence.
5. [Krateo proposal](krateo-proposal.md) and [AI usage](ai-usage.md) for the
   proposal and verification boundaries.

## Implementation and installation

| Resource | Role |
| --- | --- |
| [Local setup](local-setup.md) | Initial cluster setup and dated environment observations |
| [Original stack](../k8s/stack.yaml) | Original WordPress/MySQL deployment with fixed resource names |
| [Helm chart](../charts/kiratech-wordpress/) | Reusable templates and defaults; optional Ingress in 0.2.0 |
| [Delivery workflow](delivery-workflow.md) | Installation entry point and separately labelled CI/CD proposal |
| [Custom-image guide](../labs/security-build/README.md) | Build/load, credentials, Helm install, backup, upgrade and removal |
| [Ingress guide](../labs/ingress/README.md) | Controller installation, hostname access, routing fault and recovery |

## Troubleshooting and security remediation

The runbook numbers follow the order in which the cases were developed.
The two security cases share a finding but demonstrate different correction paths.

| Runbook case | Investigation and correction | Detailed record | Evidence |
| --- | --- | --- | --- |
| 1. MySQL initialization | HTTP 500 / error 1045; reproduce initialization failure with trailing-LF credentials and compare a corrected fresh installation | [MySQL incident](incidents/mysql-initialization.md) | [Failed initialization](evidence/mysql-init-failed.log), [clean initialization](evidence/mysql-init-clean.log) |
| 2. Published-image patch | Identify affected PHP; replace the published WordPress image and verify runtime, content and storage | [Published-image lab](../labs/security/README.md) | [Versions before](evidence/security-versions-before.txt), [after](evidence/security-versions-after.txt); other security-* files in evidence/ |
| 3. Custom-image patch with Helm | Inspect FROM, change the pinned PHP/Apache base, rebuild and deploy through Helm values | [Custom-image lab](../labs/security-build/README.md) | [Build/upgrade evidence](evidence/security-build/) |
| 4. Missing image | ErrImageNeverPull caused by a nonexistent local image tag with Never policy; recover the intended image and Helm state | [Missing-image incident](incidents/image-not-available.md) | [Image incident evidence](evidence/image-missing/) |
| 5. Ingress routing | Ready application but HTTP 503; identify a mismatched Service selector and empty endpoints, then restore routing | [Ingress incident](../labs/ingress/README.md#reproduced-incident-healthy-pod-http-503) | [Routing evidence](evidence/ingress-selector/) |

The Ingress guide also records actual setup problems: chart value paths,
probe timeouts and an interrupted Helm installation. These are supporting
observations, not additional independently validated vulnerability cases.

## Verification reports

| Report | What was verified |
| --- | --- |
| [Clean installation](clean-install-test.md) | Fresh credentials/storage, automatic MySQL setup and WordPress installation |
| [Persistence](persistence-test.md) | Article and image survival after separate WordPress/MySQL Pod replacement |
| [Clean checkout](fresh-checkout-test.md) | New local clone, credentials/PVCs, install, application checks and removal; existing cluster/images reused |
| [Ingress smoke script](../labs/ingress/smoke-test.sh) | HTTP 200 and expected page text; successful execution recorded after recovery |

## Design, provenance and limitations

- [Architecture](architecture.md): component responsibilities and access paths.
- [Krateo proposal](krateo-proposal.md): conceptual integration, not deployed.
- [Delivery workflow](delivery-workflow.md#proposed-cicd-workflow): proposed pipeline, not implemented.
- [AI usage](ai-usage.md): assistance, candidate verification and corrections.
- [Sources](sources.md): upstream origin and subject-specific references.
- [Early work log](work-log.md): dated initial notes, not the current status.
- [Evidence directory](evidence/): recorded outputs; do not overwrite them to match later documentation.

The security labs demonstrate version/configuration assessment and remediation,
not exploitation. Backup restoration, high availability and a complete new-machine
rebuild were not verified. Each report preserves its specific limitations.
