# AI assistance and manual verification

## Scope

AI was used as a learning and implementation assistant during this challenge.
It helped explain unfamiliar concepts, propose commands, draft configuration
and organise documentation.

The candidate executed the commands and reviewed their outputs.
This work should not be presented as implementation completed without assistance.

## Tasks supported by AI

- Explaining the WordPress, PHP, Apache and MySQL components.
- Reading the upstream Dockerfile, entrypoint and configuration.
- Drafting Kubernetes manifests and the parameterised Helm chart.
- Preparing custom-image build and upgrade procedures.
- Suggesting diagnostic commands and interpreting their results.
- Drafting incident reports, the runbook and architecture documentation.
- Preparing the conceptual Krateo proposal using official documentation.

## Troubleshooting example: MySQL initialization

### Observations

WordPress could not connect using its database account.
A PHP connection test returned MySQL error 1045.
An administrator query showed that the application account was absent.

### AI contribution

AI helped propose a diagnostic sequence:
inspect initialization logs, reproduce the installation with fresh storage,
check credential-file formatting and compare against corrected files.

### Manual verification

- Reproduced the failure in an isolated namespace with a new PVC.
- Captured previous-container logs showing initialization failing.
- Checked file lengths and newline flags without printing passwords.
- Created separate credential files without the trailing LF.
- Repeated initialization in another namespace with new storage.
- Confirmed automatic database and user creation.
- Successfully executed SELECT 1 using the application account.
- Completed a fresh WordPress web installation.

The controlled comparison supports the trailing LF as the failure trigger.
The exact internal password-handling mechanism was not investigated.

The original installation's credentials were retained because its database
had already been repaired using those credentials.

## Other checks performed

- Ran Helm lint for both custom-image configurations.
- Rendered both configurations and compared the generated manifests.
- Confirmed that the rendered difference was the WordPress image reference.
- Checked WordPress and PHP versions inside the built and running containers.
- Checked the PHP version used by Apache through WordPress Site Health.
- Compared uploaded-file hashes before and after the Helm upgrade.
- Confirmed that the published text and image remained visible.
- Captured Kubernetes events identifying the unavailable image and Never policy.
- Compared Helm history with actual Kubernetes state during recovery.

These checks support the documented results; they do not prove that every
configuration choice or security property is correct.

## Limits and corrections

- AI suggestions were treated as hypotheses until checked against evidence.
- The missing-image rollback reported failure even though Kubernetes recovered.
  The precise reason for that discrepancy remains unconfirmed.
- Updating the image and checking versions did not demonstrate exploitation
  or prove that all vulnerabilities were eliminated.
- Backup files were created and checked, but restoration was not tested.
- The Krateo integration remains conceptual and was not executed.
- Installation and removal from a clean checkout were verified using existing images and the existing cluster; a full rebuild and replay of all labs were not performed.
- Formatting problems in copied files were corrected and checked with Git.

## Handling sensitive information

Credential values and SQL backups were kept outside version control.
Diagnostic evidence used in documentation excludes password values.
Further AI-assisted review must use redacted output rather than credentials,
tokens, database dumps or other sensitive content.

## Candidate responsibility

The candidate must be able to explain the deployed components, diagnostic
decisions and limitations. AI-generated commands require review of their
target context, namespace and effect before execution, especially when
changing credentials, deleting resources or handling persistent data.
