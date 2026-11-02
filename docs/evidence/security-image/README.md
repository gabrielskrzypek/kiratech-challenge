# Published-image security remediation

[All evidence](../README.md)

Report: [Published-image incident](../../incidents/php-security-image-update.md)

Recorded 2026-10-27 in wordpress-security.

Read the following stages in order. Filenames retain their original capture names.

| Stage | Files | What to inspect |
| --- | --- | --- |
| 1. Image and runtime baseline | [security-image-before.txt](security-image-before.txt), [security-versions-before.txt](security-versions-before.txt) | Affected image reference and WordPress/PHP CLI versions. |
| 2. Storage and content baseline | [security-resources-before.txt](security-resources-before.txt), [security-uploads-before.txt](security-uploads-before.txt) | Pod/PVC identities and uploaded-file hashes. |
| 3. Corrected image and runtime | [security-image-after.txt](security-image-after.txt), [security-versions-after.txt](security-versions-after.txt) | Replacement reference and PHP 8.3.36; WordPress also changes version. |
| 4. Retention checks | [security-resources-after.txt](security-resources-after.txt), [security-uploads-after.txt](security-uploads-after.txt) | Compare bindings and hashes against stage 2. |
| 5. Post-update log sample | [security-wordpress-after.log](security-wordpress-after.log) | The reviewed 60-line application log sample. |

## Interpretation and limits

Web-runtime and article/image checks are manual observations in the report. These captures support version-based remediation and functional checks, not demonstrated exploitation or absence of all vulnerabilities. Private backups are excluded.
