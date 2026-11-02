# Evidence — reading guide

Recorded outputs are grouped by test or incident. Start with the relevant
report, then open its evidence folder below; each folder has an ordered file
index explaining the baseline, failure/change and verification captures.

## Troubleshooting and security remediation

| Runbook case | Report | Evidence |
| --- | --- | --- |
| 1. MySQL initialization | [Credential diagnosis](../incidents/mysql-initialization.md) | [Failure and corrected comparison](mysql-initialization/README.md) |
| 2. Published-image security patch | [Image replacement](../incidents/php-security-image-update.md) | [Before and after](security-image/README.md) |
| 3. Custom-image patch with Helm | [Base update and rebuild](../incidents/php-security-custom-build.md) | [Provenance, upgrade and retained data](security-build/README.md) |
| 4. Missing image | [ErrImageNeverPull](../incidents/image-not-available.md) | [Failure, rollback attempt and recovery](image-missing/README.md) |
| 5. Ingress routing | [Incorrect Service selector](../incidents/ingress-service-selector.md) | [HTTP 200 -> 503 -> 200](ingress-selector/README.md) |

The two security cases are distinct remediation paths for the same assessed
PHP issue, not two independently demonstrated exploits.

## Installation and verification

| Test | Report / procedure | Evidence |
| --- | --- | --- |
| Clean WordPress installation | [Report](../clean-install-test.md) | [Clean resources](clean-install/README.md), with shared MySQL evidence linked there |
| Pod-replacement persistence | [Report](../persistence-test.md) | [Before, after WordPress, after MySQL](persistence/README.md) |
| Clean-checkout installation/removal | [Report](../fresh-checkout-test.md) | [Source through cleanup](fresh-checkout/README.md) |
| Ingress setup and final checks | [Lab guide](../../labs/ingress/README.md) | [Probe/Helm recovery and final verification](ingress/README.md) |

## How to interpret these files

- Captures are historical observations, not the cluster's current state.
- Compare before/after Pod identities, volume bindings and file hashes as
  directed by each index; HTTP 200 alone does not prove preserved content.
- Browser observations are identified as manual in the associated reports.
- Error outputs are retained as part of the investigation. In particular,
  ingress/helm-install.txt contains an installation error, and the missing-image
  rollback result must be read together with the subsequent resource checks.
- fresh-checkout/volumes-removed.txt is an empty capture. See its folder index
  for context rather than interpreting empty output as independent proof.
- Passwords, SQL dumps and private content backups are excluded from Git.
- No capture was regenerated or rewritten during the 2026-11-02 reorganization.
  The existing flat files were moved into folders with their original names
  and byte contents; these reading guides are new documentation.

Return to the [documentation map](../README.md) or [L2 runbook](../runbook.md).
