# MySQL initialization failure caused by trailing newlines in credentials

## Symptoms
- WordPress failed its startup probe and returned HTTP 500.
- The PHP database connection test returned MySQL error 1045.
- The application database user was absent.
- MySQL became Ready because its TCP probe only checked the listening port.

## Investigation
The original installation was repaired manually by creating the application
database, user and grants. This restored WordPress but did not establish
that a fresh installation would work.

A separate namespace, wordpress-check, was used with a fresh PVC and the
same MySQL configuration and credential files.

The failure was reproduced:
- MySQL container terminated with reason Error and exit code 1.
- Initialization failed while attempting to create the wordpress database.
- The initialization script reported access denied for root@localhost.
- After restarting, MySQL accepted TCP connections, but the application
  authentication test still failed.

## Cause and controlled comparison
Both credential files contained 48 hexadecimal characters followed by LF:
49 bytes in total. They had been generated using openssl rand -hex 24.
Creating the Secret with --from-file preserved that trailing character.

A second fresh installation in wordpress-check-clean used copies of the
credentials with only the final LF removed. The image and workload
configuration were otherwise unchanged.

Observed results:
- Database, application user and grants were created automatically.
- The initialization process completed.
- The application user successfully executed SELECT 1.
- The Pod was Running and Ready with zero restarts at verification.

This comparison supports trailing newlines in the credentials as the cause
of the reproduced initialization failure. The exact internal password
parsing mechanism was not investigated.

## Prevention
Generate credential files without trailing line endings.
For example, during initial setup only:

    python3 -c 'import secrets; from pathlib import Path; Path(".local/mysql-password").write_text(secrets.token_hex(24))'

Generate a separate root password using the same approach.
Do not overwrite credentials belonging to an existing database.

## Recovery boundaries
Changing a Kubernetes Secret does not update existing MySQL account passwords.
Existing installations require a coordinated password change and validation.
Before rebuilding a database containing valuable data, create and verify a backup.

## Evidence
- ../evidence/mysql-init-failed.log
- ../evidence/mysql-init-clean.log
- ../evidence/mysql-clean-pods.txt

## Completed follow-up checks
- Fresh WordPress installation with corrected credentials: see ../clean-install-test.md.
- Application data persistence across Pod replacement: see ../persistence-test.md.
