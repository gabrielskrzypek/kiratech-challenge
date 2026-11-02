# Clean WordPress installation

[All evidence](../README.md)

Report: [Clean-install report](../../verification/clean-install-test.md)

Recorded 2026-10-27 in wordpress-check-clean.

Read the following stages in order. Filenames retain their original capture names.

| Stage | Files | What to inspect |
| --- | --- | --- |
| 1. Installation resources | [clean-install-resources.txt](clean-install-resources.txt) | Available Deployments, Ready Pods, Services and new Bound PVCs. |

## Interpretation and limits

MySQL initialization evidence is shared with the [credential case](../mysql-initialization/README.md), not duplicated. The report records SELECT 1 and manual web installation/Dashboard checks; this resource listing alone does not prove those application checks.
