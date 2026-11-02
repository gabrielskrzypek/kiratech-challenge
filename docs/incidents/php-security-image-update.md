# Affected PHP runtime — remediation using a published WordPress image

Execution date: 2026-10-27. Report consolidated: 2026-11-02.
Context: kiratech. Namespace: wordpress-security. Deployment: wordpress.
Runbook: [Case 2](../runbook.md#case-2--affected-php-runtime-replace-the-published-image).
Reproduction and commands: [published-image lab](../../labs/security/README.md).

## Finding and impact

The lab's WordPress container ran PHP 8.3.35. The security assessment in
the lab guide identified this runtime as affected by the reviewed PHP
advisories and selected PHP 8.3.36 as the corrected version for those findings.
WordPress remained usable; the trigger was a security finding, not an outage.
No compromise or successful exploitation was demonstrated.

## Investigation and diagnosis

- Recorded the deployed image reference, pinned by digest.
- Checked PHP inside the container and separately in WordPress Site Health.
  Both reported 8.3.35; the web runtime used apache2handler.
- Compared runtime/version information with the vendor advisories linked in
  the [security diagnosis](../../labs/security/README.md#security-diagnosis).
- Identified PHP as a container dependency: a WordPress Dashboard update
  would not replace that runtime.
- Compared the affected and patched manifests. Only their WordPress image
  reference differed, although the replacement packaged changes to several components.

## Correction performed

Captured a private SQL dump and wp-content archive, then checked the dump
completion footer and gzip integrity. Recorded resource identities, PVC
bindings and uploaded-file SHA-256 hashes before replacement.

Applied stack-patched.yaml and waited for the WordPress rollout. The
single-replica Recreate strategy replaced the application Pod; this was
not a zero-downtime procedure. MySQL and persistent volumes were retained.

## Verification and evidence

| Check | Recorded result | Evidence |
| --- | --- | --- |
| Image reference | Corrected published image selected | [Before](../evidence/security-image/security-image-before.txt), [after](../evidence/security-image/security-image-after.txt) |
| CLI versions | PHP 8.3.35 -> 8.3.36; WordPress 7.1.2 -> 7.1.3 | [Before](../evidence/security-image/security-versions-before.txt), [after](../evidence/security-image/security-versions-after.txt) |
| Resources | WordPress Pod replaced; MySQL unchanged; PVC bindings retained | [Before](../evidence/security-image/security-resources-before.txt), [after](../evidence/security-image/security-resources-after.txt) |
| Uploaded files | SHA-256 hashes matched | [Before](../evidence/security-image/security-uploads-before.txt), [after](../evidence/security-image/security-uploads-after.txt) |
| Log sample | Reviewed 60-line sample showed HTTP 200 and no visible PHP errors | [Post-update log](../evidence/security-image/security-wordpress-after.log) |

Manual browser checks confirmed PHP 8.3.36, Apache 2.4.69 and the original
article/image. These observations are recorded in the lab guide; they are
not additional automated test output.

## Recovery and escalation

Rollback and backup restoration were not tested in this lab. If the corrected
image fails, collect rollout conditions, events and logs; investigate image
availability, probes and database access before selecting recovery actions.
Reverting to the affected image would reintroduce the security finding and
would not restore database contents. Escalate uncertain advisory applicability,
suspected compromise, incompatible updates or uncertain data integrity.

## Prevention and limits

Track runtime dependencies as well as the WordPress application version;
review image references and verify the actual CLI/web runtime after updates.
These are operational recommendations, not an implemented scanning pipeline.

The result is verified version-based remediation and preserved application
functionality, not proof that the complete stack is vulnerability-free.
No exploit was run. The separate advisory follow-up and other limitations
remain in the [lab report](../../labs/security/README.md#limits).
The [custom-build case](php-security-custom-build.md) addresses the same
assessed PHP issue using a different delivery path.
