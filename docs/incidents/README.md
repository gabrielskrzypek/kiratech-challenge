# Troubleshooting and security remediation

[Documentation home](../README.md) · [L2 runbook](../runbook.md) · [Evidence index](../evidence/README.md)

Use the runbook for operational commands. Use the reports below to follow
what happened, the investigation and the recorded recovery. Numbering matches
the runbook and the order in which the cases were developed.

## Choose a case

| Case and report | Symptom and diagnosis | Correction and evidence |
| --- | --- | --- |
| 1. [MySQL initialization](mysql-initialization.md) | WordPress HTTP 500; MySQL error 1045 means authentication failed. The application user was absent. A fresh-storage comparison reproduced initialization failure with trailing-LF credentials. | Corrected credential files and fresh initialization; [initialization evidence](../evidence/mysql-initialization/README.md) and [clean-install report](../clean-install-test.md) |
| 2. [Published-image security update](php-security-image-update.md) | A runtime version check identified PHP 8.3.35 as affected by the assessed advisories, even though the application could serve requests. | Replace the published image and verify runtime/content; [before and after](../evidence/security-image/README.md) |
| 3. [Custom build and Helm update](php-security-custom-build.md) | Same assessed PHP issue; simulate the absence of a corrected WordPress image and trace the runtime to the Dockerfile base. | Update the pinned PHP/Apache base, rebuild and deploy through Helm values; [build/upgrade evidence](../evidence/security-build/README.md) |
| 4. [Unavailable image](image-not-available.md) | ErrImageNeverPull means the requested image is absent from the node while downloads are disabled. Here, the tag was incorrect. | Restore the intended image and reconcile Helm state; [failure and recovery](../evidence/image-missing/README.md) |
| 5. [Ingress Service selector](ingress-service-selector.md) | HTTP 503 through Ingress with a Ready application and direct HTTP 200. The Service selector matched no Pods, leaving no backend endpoints. | Restore the selector and verify endpoints, HTTP and content; [routing evidence](../evidence/ingress-selector/README.md) |

## Follow the supporting material

For each case, read the report first, then its evidence index. Full reproduction
procedures remain in the linked lab guides rather than being repeated here.

| Reproduce | Procedure |
| --- | --- |
| Published-image correction | [Security lab](../../labs/security/README.md) |
| Build and Helm correction | [Custom-image lab](../../labs/security-build/README.md) |
| Missing-image fault | [Incident reproduction steps](image-not-available.md) and [fault values](../../labs/troubleshooting/values-image-missing.yaml) |
| Ingress routing fault | [Ingress lab](../../labs/ingress/README.md) |

Cases 2 and 3 are two remediation paths for the same assessed issue, not two
distinct vulnerabilities. They document version assessment and correction;
no exploitation was demonstrated. Each report preserves its specific limits
and unresolved questions, including the missing-image rollback discrepancy.
