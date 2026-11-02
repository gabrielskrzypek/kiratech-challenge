# Clean-checkout installation and removal

[All evidence](../README.md)

Report: [Clean-checkout report](../../verification/fresh-checkout-test.md)

Recorded 2026-10-29 in wordpress-validation, release validation. Existing images and cluster were reused.

Read the following stages in order. Filenames retain their original capture names.

| Stage | Files | What to inspect |
| --- | --- | --- |
| 1. Source | [source-commit.txt](source-commit.txt) | Commit used for the separate local clone. |
| 2. Installation | [helm-install.txt](helm-install.txt), [resources-installed.txt](resources-installed.txt), [mysql-initialization.log](mysql-initialization.log) | Helm installation, new resources and database initialization. |
| 3. Application verification | [mysql-connection.txt](mysql-connection.txt), [versions.txt](versions.txt), [http-verified.txt](http-verified.txt), [browser-check.txt](browser-check.txt), [resources-verified.txt](resources-verified.txt) | Database query, runtime versions, HTTP and explicitly manual browser observations. |
| 4. Record storage and uninstall | [volumes-before-removal.txt](volumes-before-removal.txt), [uninstall.txt](uninstall.txt) | Volume identities captured before removing the release. |
| 5. Removal checks | [resources-after-removal.txt](resources-after-removal.txt), [volumes-removed.txt](volumes-removed.txt), [namespace-removed.txt](namespace-removed.txt) | Resource absence, recorded wait output and namespace deletion. |

## Interpretation and limits

volumes-removed.txt is intentionally empty: the recorded wait commands produced no output. Its contents alone do not prove success; read the report for execution context. This was not a new-machine build or a full replay of every lab.
