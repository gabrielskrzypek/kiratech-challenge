# Custom-image build and Helm remediation

[All evidence](../README.md)

Report: [Custom-build incident](../../incidents/php-security-custom-build.md)

Build/install on 2026-10-28; upgrade verification on 2026-10-29 in wordpress-build, release patch-lab.

Read the following stages in order. Filenames retain their original capture names.

| Stage | Files | What to inspect |
| --- | --- | --- |
| 1. Provenance | [upstream-commit.txt](upstream-commit.txt), [implementation-commit.txt](implementation-commit.txt) | Source packaging revision and project implementation commit. |
| 2. Baseline | [resources-before.txt](resources-before.txt), [uploads-before.sha256](uploads-before.sha256) | Resources and uploaded-file hashes before the upgrade. |
| 3. Upgrade and runtime | [helm-history.txt](helm-history.txt), [image-after.txt](image-after.txt), [versions-after.txt](versions-after.txt) | Install/upgrade revisions, selected custom image and post-update versions. |
| 4. Retention checks | [resources-after.txt](resources-after.txt), [uploads-after.sha256](uploads-after.sha256) | Compare Pod/PVC identities and upload hashes with stage 2. |

## Interpretation and limits

The baseline version and manual web checks are recorded in the lab report; this folder has no separate versions-before.txt capture. Do not infer that an absent file was generated. Chart history refers to the recorded 0.1.0 execution.
