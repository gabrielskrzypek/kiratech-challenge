# Affected PHP base — custom image rebuild and Helm remediation

Build/installation date: 2026-10-28. Upgrade verification: 2026-10-29.
Report consolidated: 2026-11-02. Context: kiratech.
Namespace: wordpress-build. Release: patch-lab.
Runbook: [Case 3](../runbook.md#case-3--affected-php-runtime-rebuild-the-image-and-upgrade-with-helm).
Reproduction and commands: [custom-image lab](../../labs/security-build/README.md).

## Finding and scenario

The baseline custom WordPress image used PHP 8.3.35. This extends the
[published-image case](php-security-image-update.md): the runtime finding
is the same, but this lab simulates an unavailable corrected WordPress
image while a corrected PHP/Apache base is available.

That availability constraint was simulated. A corrected published WordPress
image existed and had already been tested. No exploitation was demonstrated.

## Investigation and diagnosis

- Inspected the upstream WordPress packaging Dockerfile and recorded its revision.
- Identified FROM php:8.3-apache as the source of the PHP/Apache base dependency.
- Prepared affected and patched variants pinned to PHP/Apache 8.3.35 and
  8.3.36 by version and digest; their only Dockerfile difference was FROM.
- Kept WordPress at 7.1.3 in both images and checked the built versions.
- Validated both Helm values configurations and compared rendered manifests;
  the recorded comparison changed only the selected WordPress image.

This corrected a base dependency and rebuilt the image. It did not implement
a manual patch to PHP source code. Other base components could also change.

## Correction performed

Built and loaded both local images, then installed patch-lab with the affected
values and created an article with an uploaded image. The Never pull policy
required the selected image to be present in the Minikube node image store.

Before upgrading, exported the database, archived wp-content and recorded
resource identities and upload hashes. The dump footer and gzip checks passed.
Upgraded through values-patched.yaml; Helm revision 2 became deployed.

## Verification and evidence

| Check | Recorded result | Evidence |
| --- | --- | --- |
| Source provenance | Upstream revision recorded | [Upstream commit](../evidence/security-build/upstream-commit.txt) |
| Helm operation | Revision 1 installed; revision 2 deployed after upgrade | [Helm history](../evidence/security-build/helm-history.txt) |
| Selected image | Custom PHP 8.3.36 image | [Image after](../evidence/security-build/image-after.txt) |
| Versions | WordPress remained 7.1.3; PHP changed 8.3.35 -> 8.3.36 | [Post-update output](../evidence/security-build/versions-after.txt), [before/after observations](../../labs/security-build/README.md#observed-results) |
| Resources | WordPress replaced; MySQL Pod and PVC bindings retained | [Before](../evidence/security-build/resources-before.txt), [after](../evidence/security-build/resources-after.txt) |
| Uploaded files | No hash differences | [Before](../evidence/security-build/uploads-before.sha256), [after](../evidence/security-build/uploads-after.sha256) |

Manual browser checks confirmed PHP 8.3.36 with apache2handler and the retained
article/image. The recorded upgrade used chart 0.1.0; later chart changes do
not constitute a rerun of these historical checks.

## Recovery and escalation

No rollback or backup restoration was executed here. On failure, inspect
Helm history and live resources, image availability, probes, Secret references
and database access. A rollback to revision 1 would restore the affected
runtime, not database contents; it is not a completed security correction.
Escalate dependency incompatibility, suspected compromise, data corruption
or an uncertain recovery path.

## Prevention and limits

Record base versions/digests, inspect the built runtime and validate chart
values before deployment. Keep database/content backups outside Git.

Base pinning does not make external apt/PECL downloads bit-for-bit reproducible.
The recorded images were not rebuilt after a formatting-only CRLF-to-LF change
to wp-config-docker.php. No exploit or whole-stack security guarantee is claimed.
The separate advisory follow-up remains in the
[security scope](../../labs/security-build/README.md#security-scope).
