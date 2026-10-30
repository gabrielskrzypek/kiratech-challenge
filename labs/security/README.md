# WordPress container security update lab

Verified on: 2026-10-27
Kubernetes context: kiratech
Namespace: wordpress-security

## Objective

Identify an affected PHP runtime inside a WordPress container, replace the
container image with a patched release, and verify application availability
and data preservation.

This is a local lab using fictitious content. The main application runs
separately in the wordpress namespace.

## Security diagnosis

The PHP project published CVE-2026-109618 and CVE-2026-109619 on 2026-10-21.
Both can allow unauthenticated remote code execution under relevant conditions.
PHP 8.3.36 contains the fixes for the PHP 8.3 branch.

The affected lab image contained PHP 8.3.35.
WordPress Site Health confirmed that the web runtime also used PHP 8.3.35
with the apache2handler SAPI, corresponding to Apache mod_php.

Updating WordPress through its Dashboard does not update the PHP runtime.
The remediation in this lab replaces the complete container image.

## Images and observed versions

| Component | Before | After |
| --- | --- | --- |
| WordPress | 7.1.2 | 7.1.3 |
| PHP CLI | 8.3.35 | 8.3.36 |
| PHP web | 8.3.35 | 8.3.36 |
| Apache | 2.4.68 | 2.4.69 |
| PHP web SAPI | apache2handler | apache2handler |

Both WordPress images are pinned by full digest in the manifests:
- stack-affected.yaml: affected baseline.
- stack-patched.yaml: corrected image.

The manifests differ only in the WordPress container image.
The image replacement updates WordPress, PHP, Apache and potentially other
packaged dependencies. This is not an experiment changing PHP alone.

Automatic WordPress updates are disabled in this lab to keep the comparison
controlled. This setting is not a general production recommendation.

## Reproduce the lab

Run commands from the repository root.
Use a fresh namespace and fresh PVCs when reproducing the initial installation.

Prerequisites: running cluster, kubectl, Python 3 and Docker access.

Create the namespace:

    kubectl --context=kiratech create namespace wordpress-security

Generate separate local passwords without trailing newlines.
The exclusive file mode prevents overwriting existing files:

    umask 077
    mkdir -p .local
    python3 - <<'PY'
    import secrets
    from pathlib import Path
    for name in ("security-mysql-password", "security-mysql-root-password"):
        with (Path(".local") / name).open("x") as handle:
            handle.write(secrets.token_hex(24))
    PY

Create the Secret:

    kubectl --context=kiratech --namespace=wordpress-security create secret generic mysql-credentials --from-file=password=.local/security-mysql-password --from-file=root-password=.local/security-mysql-root-password

Deploy the affected baseline:

    kubectl --context=kiratech --namespace=wordpress-security apply -f labs/security/stack-affected.yaml
    kubectl --context=kiratech --namespace=wordpress-security rollout status deployment/wordpress-mysql --timeout=300s
    kubectl --context=kiratech --namespace=wordpress-security rollout status deployment/wordpress --timeout=300s
    kubectl --context=kiratech --namespace=wordpress-security port-forward service/wordpress 8082:80

Open http://localhost:8082 and complete installation in English.
Publish "Kiratech security update test" with text and an uploaded image.
Inspect Tools > Site Health > Info > Server.

During the recorded execution, the Secret was instead created from the
previously validated mysql-password-clean and mysql-root-password-clean
local files. Those files contained no trailing LF.

## Preparation before updating

Stop editing content while taking the backup.

The recorded execution exported the database using mysqldump with
--single-transaction --no-tablespaces --set-gtid-purged=OFF,
and archived /var/www/html/wp-content using tar.

Backups are stored locally under .local/security-backup and are excluded
from Git. The SQL export ended with "Dump completed", and gzip -t reported
no errors for the content archive.

Record the deployed image, versions, Pods, PVCs and uploaded-file SHA-256
checksums before applying the corrected manifest.

## Apply the correction

Stop port-forward with Ctrl+C, then run:

    kubectl --context=kiratech --namespace=wordpress-security apply -f labs/security/stack-patched.yaml
    kubectl --context=kiratech --namespace=wordpress-security rollout status deployment/wordpress --timeout=300s

Reopen port-forward using the same port.

The Deployment uses one replica and the Recreate strategy.
A brief interruption is expected during replacement.

## Verified results

- WordPress rollout completed successfully.
- PHP CLI and web runtime both reported 8.3.36.
- The WordPress Pod was replaced and had zero restarts at verification.
- The MySQL Pod was unchanged.
- Both PVCs remained Bound to the same volumes.
- Uploaded-file SHA-256 checksums matched before and after the update.
- The public post title, text and image remained visible after refresh.
- The reviewed 60-line log sample contained HTTP 200 responses and no
  visible PHP errors.

Evidence files are under docs/evidence/security-* from the repository root.
Browser checks were manual.

## Recovery and escalation

If rollout fails or the application loses functionality:
1. Capture Pod status, describe output, events and current/previous logs.
2. Check image pull failures, probes, database connectivity and permissions.
3. Keep the lab inaccessible while investigating; port-forward can be stopped
   and the WordPress Deployment can be scaled to zero.
4. Prefer correcting the patched deployment.
5. If recovery requires an older image, assess database compatibility first.
   A container rollback does not roll back database schema or data changes.
6. A return to the affected image would reintroduce the security exposure
   and must not be treated as a completed security fix.

Escalate with versions, digests, symptoms and evidence if a compatible
patched deployment cannot be restored or data integrity is uncertain.
Do not delete PVCs as a troubleshooting shortcut.

## Limits

- No exploit was executed; successful RCE was not demonstrated.
- Version/configuration assessment and update verification were performed.
- Backup restoration and rollback were not tested.
- A later [clean-checkout test](../../docs/fresh-checkout-test.md) verified
  installation/removal with existing custom images and cluster. It did not
  replay this published-image update lab.
- This test does not establish that the image has no other vulnerabilities.
- The separate PHP advisory of 2026-10-23 concerning session upload progress
  was not assessed in this lab and remains a follow-up review item.

## AI assistance

AI assisted with source interpretation, manifest preparation, diagnostic
commands and documentation. Commands were executed manually and results
were checked against actual output and official advisories.
Unexecuted exploit and recovery procedures are not reported as tested.

## Official sources

- https://www.php.net/archive/2026.php
- https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w
- https://github.com/php/php-src/security/advisories/GHSA-6wmf-4rv5-p3rp
- https://wordpress.org/news/2026/10/critical-php-security-release/
- https://developer.wordpress.org/advanced-administration/upgrade/upgrading/
