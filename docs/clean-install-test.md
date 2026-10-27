# Clean installation verification

Date: 2026-10-27
Context: kiratech
Namespace: wordpress-check-clean

## Setup
- Used the MySQL and WordPress resources from k8s/stack.yaml,
  with their namespace changed for this isolated test.
- Used newly provisioned PVCs for MySQL and WordPress content.
- Created the Secret from credential files without trailing LF.
- MySQL automatically created the database, application user and grants.
- No manual database repair was performed in this namespace.

## Verification
- MySQL application-user query SELECT 1 returned 1.
- WordPress Deployment rollout completed.
- Opened WordPress through localhost:8081.
- Completed the web installation in English.
- Successfully logged into the Dashboard.

Result: PASS for this fresh installation.

## Evidence
- evidence/mysql-init-clean.log
- evidence/mysql-clean-pods.txt
- evidence/clean-install-resources.txt

## Remaining work
Turn the verified procedure into complete installation instructions
or scripts, then validate those instructions from a fresh checkout.
