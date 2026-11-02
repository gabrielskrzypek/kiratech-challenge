# Project documentation

[Project overview: English](../README.md) · [Italiano](../README.it.md)

## Start here

For a first review, read the architecture, then one incident and its evidence.
For a live walkthrough, use the demonstration guide.

| I want to… | Open | What it contains |
| --- | --- | --- |
| Understand the application | [Architecture](architecture.md) | Components, deployment names, storage and traffic diagrams |
| Install a fresh instance | [Installation entry point](delivery-workflow.md) | Clone, tool checks and the route through cluster setup and the lab procedure |
| Investigate a problem | [L2 runbook](runbook.md) | Initial checks, five cases, correction and escalation |
| Review the troubleshooting work | [Incident catalogue](incidents/README.md) | Symptoms, causes, corrections and evidence for each case |
| Present the project | [Demonstration guide](demo.md) | Walkthrough commands, expected results and a reversible change |
| Inspect original outputs | [Evidence index](evidence/README.md) | Captures grouped by scenario, each with a reading order |

## Installation and lab procedures

These documents explain **how to perform the work**. Start with the installation
entry point above; it connects the setup and build instructions in order.

| Procedure | Use it for |
| --- | --- |
| [Local setup](local-setup.md) | Prepare Minikube and check the cluster and storage |
| [Custom-image and Helm lab](../labs/security-build/README.md) | Build/load images; prepare credentials; install, back up, upgrade, verify and remove |
| [Published-image lab](../labs/security/README.md) | Reproduce correction by replacing the published WordPress image |
| [Ingress lab](../labs/ingress/README.md) | Set up Traefik, hostname access, selector fault and recovery |

The implementation files are the [original manifest](../k8s/stack.yaml) and
[Helm chart](../charts/kiratech-wordpress/). Lab override files live beside
their procedures under [labs/](../labs/).

## Troubleshooting and security remediation

The [incident catalogue](incidents/README.md) groups all five cases by symptom
and correction, with links to the reports and evidence. The [runbook](runbook.md)
provides the diagnostic commands and recovery guidance.

## Verification reports

These reports describe **what was actually checked**, with the scope and result
of each functional test.

| Report | Verified scope |
| --- | --- |
| [Clean installation](clean-install-test.md) | Fresh credentials/PVCs, automatic MySQL initialization and WordPress setup |
| [Persistence](persistence-test.md) | Article and image retained after separate WordPress/MySQL Pod replacement |
| [Clean checkout](fresh-checkout-test.md) | Install, application checks and removal using a fresh clone and existing cluster/images |
| [Demo resource change](demo-change-test.md) | CPU request 100m → 150m → 100m, retained image/uploads/volumes and direct HTTP/content checks |

Read each report before its raw captures. The [evidence index](evidence/README.md)
links the scenario folders and explains how to follow them.

## Project record and proposals

| Document | Purpose |
| --- | --- |
| [Work log](work-log.md) | Chronology and links to the work performed |
| [Sources](sources.md) | Upstream packaging, advisories and official references |
| [AI assistance](ai-usage.md) | Assistance received, verification and corrections |
| [Krateo proposal](krateo-proposal.md) | Conceptual platform integration; not deployed |
| [CI/CD proposal](delivery-workflow.md#proposed-cicd-workflow) | Proposed delivery pipeline; not implemented |

Each lab/report states its limits. A documented procedure is not, by itself,
evidence that every step was executed. The demonstration guide includes new
steps that have not been run as a complete sequence.
