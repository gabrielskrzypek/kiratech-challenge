# Missing-image incident — failure, rollback attempt and recovery

[All evidence](../README.md)

Report: [Missing-image incident](../../incidents/image-not-available.md)

Recorded 2026-10-29 in wordpress-troubleshooting, release image-lab.

Read the following stages in order. Filenames retain their original capture names.

| Stage | Files | What to inspect |
| --- | --- | --- |
| 1. Healthy baseline | [resources-before.txt](resources-before.txt) | Initial available resources and PVC bindings. |
| 2. Failed upgrade | [upgrade-failed.txt](upgrade-failed.txt), [upgrade-exit-code.txt](upgrade-exit-code.txt), [pods-failed.txt](pods-failed.txt) | Helm timeout/nonzero exit and ErrImageNeverPull. |
| 3. Diagnose | [pod-description-failed.txt](pod-description-failed.txt), [image-policy-failed.txt](image-policy-failed.txt), [helm-history-failed.txt](helm-history-failed.txt) | Missing tag, Never policy, events and failed revision. |
| 4. Rollback attempt | [rollback.txt](rollback.txt), [rollback-failed-history.txt](rollback-failed-history.txt), [rollback-failed-deployment.txt](rollback-failed-deployment.txt), [rollback-failed-resources.txt](rollback-failed-resources.txt) | Helm reported failure while subsequent resource inspection showed recovery. |
| 5. Reconcile Helm state | [reconcile-upgrade.txt](reconcile-upgrade.txt), [helm-history-recovered.txt](helm-history-recovered.txt), [resources-recovered.txt](resources-recovered.txt) | Correct-values upgrade and final deployed revision/resources. |
| 6. Application check | [versions-recovered.txt](versions-recovered.txt), [http-recovered.txt](http-recovered.txt) | Recovered runtime versions and installer HTTP 200. |

## Interpretation and limits

The rollback-failed filenames describe the operation outcome; the resource snapshots must still be read for actual health. The rollback wait discrepancy was not fully explained. Installer HTTP 200 is not a completed CMS installation.
