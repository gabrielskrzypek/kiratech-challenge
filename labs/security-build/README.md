# Custom WordPress image patching with Helm

## Purpose and scenario

Simulate a situation where an updated WordPress image is unavailable,
but a patched PHP/Apache base image is available.

Inspect the upstream WordPress Dockerfile, change its base image,
build custom images and deploy the correction through Helm values.

The absence of an updated WordPress image is a simulated constraint:
an updated published WordPress image was available and was tested
in the separate ../security lab.

Implementation and builds: 2026-10-28.
Upgrade and final verification: 2026-10-29.

## Security scope

The PHP advisories identify PHP 8.3.36 as a patched release for:

- CVE-2026-109618: RCE via OOM corruption.
- CVE-2026-109619: RCE via stale global state.

The baseline uses PHP 8.3.35; the replacement uses PHP 8.3.36.
The web interface confirmed Apache integration through apache2handler.

Validation consists of checking the deployed versions against the vendor
advisories and checking application functionality and persistence.
No exploit or penetration test was executed.

Sources:
- https://www.php.net/archive/2026.php
- https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w
- https://github.com/php/php-src/security/advisories/GHSA-6wmf-4rv5-p3rp

The separate PHP advisory of 2026-10-23 concerning session upload progress
and CVE-2026-115560 has not been assessed in this lab. These tests do not
establish that the complete application stack is free of vulnerabilities.

## Upstream origin and modifications

Packaging repository: https://github.com/docker-library/wordpress

Copied files:
- latest/php8.3/apache/Dockerfile, retained as Dockerfile.upstream.
- docker-entrypoint.sh.
- wp-config-docker.php.
- LICENSE.

The reviewed upstream commit is recorded in:
../../docs/evidence/security-build/upstream-commit.txt

The upstream Dockerfile uses FROM php:8.3-apache.
Our two variants replace that mutable base reference with explicit versions
and digests:

| Variant | Base |
| --- | --- |
| affected | php:8.3.35-apache@sha256:c59c808172ee3672cd334f8f2a5d7b1480a9d7273a368f412b8ee9b4ef418184 |
| patched | php:8.3.36-apache@sha256:11093ce0630a495ce9436647d2939b5ca44b411d2a04917afe8b2d051ae2d2ed |

Both bases reported Debian GNU/Linux 13 (trixie).
Both custom images contain WordPress 7.1.3.
The only difference between our two Dockerfiles is FROM.

Changing the base also incorporates any differences in its Apache and
system components. This is not a PHP-only binary comparison.

After the successful deployment tests, wp-config-docker.php was normalized
from CRLF to LF for Git whitespace checks. The tested images were not rebuilt
after this formatting-only change.

Base digests and WordPress source checksums are fixed, but apt and PECL
downloads remain external dependencies. Bit-for-bit reproducible builds
have not been demonstrated.

## Chart design

Chart: ../../charts/kiratech-wordpress

The chart was derived from the working k8s/stack.yaml resources:
- Two Deployments, using one replica and the Recreate strategy.
- Two ClusterIP Services.
- Two PersistentVolumeClaims.
- One ConfigMap.

The namespace and credential Secret are created separately.

The recorded chart 0.1.0 used the original probes and volume mounts.
Chart 0.2.0 later added optional Ingress and five-second WordPress HTTP
probe timeouts; see [the Ingress lab](../ingress/README.md). Mounts remain:
- MySQL data: /var/lib/mysql.
- WordPress content: /var/www/html/wp-content.

The WordPress core is not stored in the content PVC, so replacing the image
allows the image's core files to be initialized again.

values.yaml provides images, pull policies, database settings,
storage sizes, resource requests/limits and an existing Secret name.
Resource names and selectors also identify the Helm release.

The lab override files select:
- values-affected.yaml: kiratech-wordpress:7.1.3-php8.3.35-lab.
- values-patched.yaml: kiratech-wordpress:7.1.3-php8.3.36-lab.

Both use imagePullPolicy: Never and disable WordPress automatic updates
to keep the comparison controlled. The rendered manifests differ only
in the WordPress image.

## Prerequisites

Run commands from the repository root, using Bash in Ubuntu WSL2.
Docker Desktop must be running with Ubuntu WSL integration enabled.

Tested tools:
- Docker Engine 29.7.2.
- minikube 1.39.0.
- Kubernetes and kubectl 1.36.1.
- Helm 4.3.1.
- Python 3.

See ../../docs/local-setup.md for the cluster setup.

The following installation instructions require a fresh namespace and new
credential files. Do not rerun the initialization steps against existing data
or regenerate credentials for an initialized database.

The individual build, installation and upgrade steps were executed.
Installation and removal were subsequently verified from a clean checkout using existing images and the existing cluster; see ../../docs/fresh-checkout-test.md. A complete replay including image rebuilding and upgrade was not performed.

## Build and load images

```bash
docker build --progress=plain --file labs/security-build/Dockerfile.affected --tag kiratech-wordpress:7.1.3-php8.3.35-lab labs/security-build
docker build --progress=plain --file labs/security-build/Dockerfile.patched --tag kiratech-wordpress:7.1.3-php8.3.36-lab labs/security-build

for php_version in 8.3.35 8.3.36; do
  docker run --rm --network=none --pull=never "kiratech-wordpress:7.1.3-php${php_version}-lab" php -r 'require "/usr/src/wordpress/wp-includes/version.php"; echo "WordPress: ".$wp_version.PHP_EOL."PHP: ".PHP_VERSION.PHP_EOL;'
done

minikube start --profile kiratech
minikube image load --profile kiratech kiratech-wordpress:7.1.3-php8.3.35-lab
minikube image load --profile kiratech kiratech-wordpress:7.1.3-php8.3.36-lab
minikube image ls --profile kiratech
```

Image loading can complete without a success message.
Check the node image list before assuming a failure or repeating a load.

## Prepare credentials and install

Stop if any command fails.

```bash
kubectl --context=kiratech create namespace wordpress-build

umask 077
python3 - <<'PY'
from pathlib import Path
import secrets

folder = Path(".local")
folder.mkdir(exist_ok=True)
files = [
    folder / "build-mysql-password",
    folder / "build-mysql-root-password",
]
assert not any(path.exists() for path in files), \
    "Credential files already exist; stopping without overwriting"

for path in files:
    with path.open("x") as output:
        output.write(secrets.token_hex(24))
PY

kubectl --context=kiratech -n wordpress-build create secret generic mysql-credentials --from-file=password=.local/build-mysql-password --from-file=root-password=.local/build-mysql-root-password

helm lint charts/kiratech-wordpress --values labs/security-build/values-affected.yaml
helm lint charts/kiratech-wordpress --values labs/security-build/values-patched.yaml

helm install patch-lab charts/kiratech-wordpress --kube-context kiratech -n wordpress-build --values labs/security-build/values-affected.yaml --wait --timeout 5m

kubectl --context=kiratech -n wordpress-build get deployments,pods,services,pvc
kubectl --context=kiratech -n wordpress-build port-forward service/patch-lab-wordpress 8083:80
```

Open http://localhost:8083 and complete installation in English or Italian.
Keep the administrator credentials private.

Publish "Custom image patch test" with text and an uploaded image.
Check that both appear on the public page.
In Tools > Site Health > Info > Server, check PHP 8.3.35.
Stop port-forward with Ctrl+C before continuing.

The Secret supplies the application password to both containers.
Only MySQL receives the root password. Credentials and backups stay in
the ignored .local directory.

## Back up and record the baseline

```bash
(
set -euo pipefail
umask 077
mkdir -p .local/helm-patch-backup

kubectl --context=kiratech -n wordpress-build exec deployment/patch-lab-mysql -- sh -c 'MYSQL_PWD="$MYSQL_PASSWORD" mysqldump --single-transaction --no-tablespaces --set-gtid-purged=OFF -u "$MYSQL_USER" "$MYSQL_DATABASE"' > .local/helm-patch-backup/wordpress.sql

kubectl --context=kiratech -n wordpress-build exec deployment/patch-lab-wordpress -- tar -czf - -C /var/www/html wp-content > .local/helm-patch-backup/wp-content.tar.gz

kubectl --context=kiratech -n wordpress-build exec deployment/patch-lab-wordpress -- sh -c 'find /var/www/html/wp-content/uploads -type f -exec sha256sum {} \; | sort' > .local/helm-patch-backup/uploads-before.sha256

kubectl --context=kiratech -n wordpress-build get pods,pvc > .local/helm-patch-backup/resources-before.txt

test -s .local/helm-patch-backup/wordpress.sql
gzip -t .local/helm-patch-backup/wp-content.tar.gz
tail -n 3 .local/helm-patch-backup/wordpress.sql
)
```

Observed: the SQL dump contained its completion footer and the gzip integrity
check passed. Backup restoration and application-consistent recovery across
both stores were not tested.

## Upgrade and verify

```bash
helm upgrade patch-lab charts/kiratech-wordpress --kube-context kiratech -n wordpress-build --values labs/security-build/values-patched.yaml --wait --timeout 5m

kubectl --context=kiratech -n wordpress-build exec deployment/patch-lab-wordpress -- php -r 'require "/var/www/html/wp-includes/version.php"; echo "WordPress: ".$wp_version.PHP_EOL."PHP: ".PHP_VERSION.PHP_EOL;'

kubectl --context=kiratech -n wordpress-build get pods,pvc | tee .local/helm-patch-backup/resources-after.txt

(
set -euo pipefail
kubectl --context=kiratech -n wordpress-build exec deployment/patch-lab-wordpress -- sh -c 'find /var/www/html/wp-content/uploads -type f -exec sha256sum {} \; | sort' > .local/helm-patch-backup/uploads-after.sha256
diff -u .local/helm-patch-backup/uploads-before.sha256 .local/helm-patch-backup/uploads-after.sha256
)

helm history patch-lab --kube-context kiratech -n wordpress-build
kubectl --context=kiratech -n wordpress-build port-forward service/patch-lab-wordpress 8083:80
```

Reopen the public article and verify its text and image.
In WordPress Site Health, check PHP 8.3.36 and apache2handler.

Recreate replaces the WordPress Pod with a brief service interruption.
This lab does not provide high availability.

## Observed results

| Check | Observed result |
| --- | --- |
| Helm validation | Both override configurations passed helm lint |
| Rendered manifest comparison | Only the WordPress image changed |
| Helm upgrade | Revision 2, deployed, Upgrade complete |
| WordPress | 7.1.3 before and after |
| PHP CLI | 8.3.35 before, 8.3.36 after |
| PHP web runtime after upgrade | 8.3.36, apache2handler |
| WordPress Pod | Replaced; new Pod Ready with zero restarts at verification |
| MySQL Pod | Same Pod before and after upgrade |
| Storage | Both PVCs remained Bound to the same volumes |
| Upload hashes | No differences |
| Browser content | Text and uploaded image remained visible |

Evidence: ../../docs/evidence/security-build/

Browser checks were manual. CLI version checks do not substitute for the
separate web runtime check.

## Recovery and escalation

Rollback and restoration were not executed in this lab.

If an upgrade fails, first collect Helm status/history, Pod status,
describe output, events and container logs before changing resources.
Check image availability, probes, Secret references and database access.

A rollback to revision 1 would restore the affected image and would not
restore database or volume contents. It is not an acceptable lasting
security correction. Recovery decisions must consider the vulnerability,
data compatibility, service impact and available verified backups.

Escalate suspected compromise, data corruption or an uncertain recovery
procedure with evidence and the exact image versions. Do not assume that
updating the image removes an existing compromise.

## Removal and data loss

The following command is destructive for this chart's persistent data.
The PVCs are managed by Helm, and the local StorageClass uses Delete.
Export and verify any data that must be kept before uninstalling.

Chart removal was subsequently verified in a separate clean-checkout installation; see ../../docs/fresh-checkout-test.md. The original patch-lab installation was retained.

```bash
helm uninstall patch-lab --kube-context kiratech -n wordpress-build
```

The separately created namespace and credential Secret are outside the chart.
To pause the lab while keeping its resources, use:

```bash
minikube stop --profile kiratech
```

## AI assistance and verification

AI assisted with Dockerfile adaptation, chart generation, command proposals,
explanations and documentation drafting.

Commands were executed by the candidate. Results were checked using actual
terminal output and browser observations. Vendor advisories provide the
version-based security assessment. No generated exploit or test results are
presented as executed.

Passwords, SQL dumps and content backups were not included in the shared
evidence or committed to Git.
