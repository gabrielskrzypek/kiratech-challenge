# Ingress setup — errors, recovery and final validation

[All evidence](../README.md)

Report: [Ingress lab guide](../../../labs/ingress/README.md)

Recorded 2026-10-30. Application: ingress-lab / wordpress-ingress. Controller: traefik / ingress-system.

Read the following stages in order. Filenames retain their original capture names.

| Stage | Files | What to inspect |
| --- | --- | --- |
| 1. Interrupted installation | [helm-install.txt](helm-install.txt), [helm-history-before-recovery.txt](helm-history-before-recovery.txt) | The install file records a duplicate-name error, not a successful installation; history records pending-install. |
| 2. Probe adjustment | [deployment-before-probe-fix.yaml](deployment-before-probe-fix.yaml), [probe-fix-rollout.txt](probe-fix-rollout.txt), [resources-after-probe-fix.txt](resources-after-probe-fix.txt) | Configuration before the fix and observed availability after adjustment. |
| 3. Helm recovery | [helm-recovery-rollback.txt](helm-recovery-rollback.txt), [helm-recovery-upgrade.txt](helm-recovery-upgrade.txt), [helm-history-recovered.txt](helm-history-recovered.txt), [resources-recovered.txt](resources-recovered.txt) | Rollback operation followed by a successful upgrade and resource checks. |
| 4. Initial HTTP access | [http-before-install.txt](http-before-install.txt) | HTTP 200 at the WordPress installer before web setup. |
| 5. Final chart checks | [lint-default.txt](lint-default.txt), [lint-ingress.txt](lint-ingress.txt), [helm-final-upgrade.txt](helm-final-upgrade.txt), [helm-history-final.txt](helm-history-final.txt) | Both configurations linted; revision 4 deployed with chart 0.2.0. |
| 6. Final application/controller checks | [resources-final.txt](resources-final.txt), [controller-final.txt](controller-final.txt), [smoke-final.txt](smoke-final.txt) | Available resources and successful HTTP/content smoke test. |

## Interpretation and limits

This folder covers setup and final state. The deliberately injected 503 and its recovery are in [ingress-selector](../ingress-selector/README.md). Read stages as a diagnostic sequence; filenames and embedded timestamps retain the original captures.
