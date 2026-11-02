# MySQL initialization — failure and corrected comparison

[All evidence](../README.md)

Report: [MySQL incident](../../incidents/mysql-initialization.md)

Recorded 2026-10-27. Failed reproduction in wordpress-check; corrected comparison in wordpress-check-clean.

Read the following stages in order. Filenames retain their original capture names.

| Stage | Files | What to inspect |
| --- | --- | --- |
| 1. Failure | [mysql-init-failed.log](mysql-init-failed.log) | Initialization error before automatic application database/user setup completed. |
| 2. Corrected initialization | [mysql-init-clean.log](mysql-init-clean.log) | Initialization with no trailing LF in credential copies and fresh storage. |
| 3. Resource check | [mysql-clean-pods.txt](mysql-clean-pods.txt) | Ready MySQL Pod with zero restarts at capture. |

## Interpretation and limits

The comparison supports the credential-format diagnosis; it does not document the internal password-parsing mechanism. Continue with the [clean WordPress installation](../clean-install/README.md).
