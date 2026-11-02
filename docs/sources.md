# Sources

[Documentation home](README.md) · [Project overview](../README.md)

## Application source and operational guidance

- WordPress application source mirror: https://github.com/WordPress/WordPress
- Helm installation and binary verification: https://helm.sh/docs/intro/install/
- ConfigMap update behavior: https://kubernetes.io/docs/tutorials/configuration/updating-configuration-via-a-configmap/

These references were checked for the documentation review on 2026-11-02.
The application mirror is distinct from the image-packaging source below.

## WordPress Docker image packaging

- Repository: https://github.com/docker-library/wordpress
- Reviewed commit: 2d7faab7fb71508e6854cdbed948c195957f279e
- Purpose: inspect Dockerfiles and container startup configuration.
- Selected published WordPress image digests: see the
  [security lab manifests](../labs/security/README.md#images-and-observed-versions)
  and [before](evidence/security-image/security-image-before.txt) / [after](evidence/security-image/security-image-after.txt) evidence.
- Selected PHP base digests and build changes: see the
  [custom-image lab](../labs/security-build/README.md#upstream-origin-and-modifications).

## Source references by subject

- PHP advisory assessment: [published-image lab sources](../labs/security/README.md#official-sources).
- Original Kubernetes example: https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/
- Ingress and Traefik: [Ingress lab references](../labs/ingress/README.md#references).
- Krateo concept: [proposal references](krateo-proposal.md#official-references).

These links identify the sources used by each report; they do not imply a
new advisory review or new execution of the recorded tests.
