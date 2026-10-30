# L2 support runbook — WordPress and MySQL

Context: kiratech
Last updated: 2026-10-30

## Scope and installations

Run commands from the repository root in Ubuntu WSL.
Confirm the affected namespace before acting.

| Installation | Namespace | WordPress Deployment | MySQL Deployment | Helm release |
| --- | --- | --- | --- | --- |
| Original manifest | wordpress | wordpress | wordpress-mysql | None |
| Published-image security lab | wordpress-security | wordpress | wordpress-mysql | None |
| Custom-image lab | wordpress-build | patch-lab-wordpress | patch-lab-mysql | patch-lab |
| Missing-image incident | wordpress-troubleshooting | image-lab-wordpress | image-lab-mysql | image-lab |
| Ingress routing lab | wordpress-ingress | ingress-lab-wordpress | ingress-lab-mysql | ingress-lab |

The Ingress controller is the separate traefik release in ingress-system.

The MySQL initialization incident was also reproduced in wordpress-check
and corrected using fresh storage in wordpress-check-clean.

This runbook consolidates verified incident procedures and diagnostic
commands. Detailed records distinguish actual observations from hypotheses.
Some collection commands below are reusable guidance rather than additional
tests claimed as executed.

## Choose a troubleshooting case

Security troubleshooting includes identifying an affected runtime, choosing
and applying a correction, and verifying the resulting application.
An application can serve HTTP successfully while requiring a security fix.
The two security cases below document remediation, not demonstrated exploitation.

| Case | Trigger | Procedure |
| --- | --- | --- |
| 1 | HTTP 500 / database authentication or initialization failure | [MySQL diagnosis](#case-1--mysql-initialization-and-authentication-failure) |
| 2 | Affected PHP runtime; corrected published WordPress image available | [Published-image remediation](#case-2--affected-php-runtime-replace-the-published-image) |
| 3 | Affected PHP runtime; simulate no corrected WordPress image, but a corrected base is available | [Custom build and Helm remediation](#case-3--affected-php-runtime-rebuild-the-image-and-upgrade-with-helm) |
| 4 | ErrImageNeverPull after an image reference change | [Missing-image recovery](#case-4--incorrect-image-reference-after-helm-upgrade) |
| 5 | Ingress HTTP 503 while WordPress remains Ready | [Service selector diagnosis](#case-5--ready-application-ingress-http-503) |

Cases 2 and 3 are two remediation paths for the same assessed PHP issue.
Full lab guides retain setup and reproduction commands; this runbook provides
operational diagnosis, correction, validation and escalation.

## Initial checks

Select the affected installation. Example for the missing-image lab:

```bash
lab_ns=wordpress-troubleshooting
wp_deploy=image-lab-wordpress
db_deploy=image-lab-mysql

minikube status --profile kiratech
kubectl --context=kiratech get nodes
kubectl --context=kiratech -n "$lab_ns" get deployments,pods,services,pvc
kubectl --context=kiratech -n "$lab_ns" get events --sort-by=.metadata.creationTimestamp
kubectl --context=kiratech -n "$lab_ns" describe deployment "$wp_deploy"
```

Record the symptom, start time, last change, affected resources and impact.

| Symptom | First checks |
| --- | --- |
| Pending | Scheduling conditions and events; image or volume problems |
| ErrImageNeverPull | Exact image reference, Never policy and node image availability |
| Running but not Ready | Startup/readiness probes, application logs and dependencies |
| HTTP 500 | Application/runtime logs and dependency tests; the code alone does not identify the cause |
| Affected runtime reported | Running image, CLI/web versions, SAPI and vendor advisory applicability |
| Ingress HTTP 503 with Ready Pods | Ingress backend, Service selector, EndpointSlices and controller logs |

For a container that has started:

```bash
kubectl --context=kiratech -n "$lab_ns" logs deployment/"$wp_deploy" --tail=100
kubectl --context=kiratech -n "$lab_ns" logs deployment/"$db_deploy" --tail=100
```

Use --previous when investigating a restarted container. It requires a
previous container instance; do not treat its absence as a new application fault.

A TCP readiness check proves a listening port, not successful authentication.
A failed startup probe can restart a container before readiness/liveness
checks take over.

## Case 1 — MySQL initialization and authentication failure

Report: [mysql-initialization.md](incidents/mysql-initialization.md)

Recorded symptoms:
- WordPress returned HTTP 500 and failed its startup probe.
- Database tests returned MySQL error 1045.
- The application user was absent.
- In the reproduction, initial MySQL setup failed and the container restarted.
- MySQL subsequently accepted TCP connections despite incomplete setup.

For the original installation, select:

```bash
lab_ns=wordpress
wp_deploy=wordpress
db_deploy=wordpress-mysql
```

### Diagnose

1. Check Pods, restarts, events, current logs and previous MySQL logs.
2. Test application authentication without printing the password:

```bash
kubectl --context=kiratech -n "$lab_ns" exec deployment/"$wp_deploy" -- php -r 'mysqli_report(MYSQLI_REPORT_OFF); $db = @new mysqli(getenv("WORDPRESS_DB_HOST"), getenv("WORDPRESS_DB_USER"), getenv("WORDPRESS_DB_PASSWORD"), getenv("WORDPRESS_DB_NAME")); if ($db->connect_errno) { fwrite(STDERR, "MySQL error ".$db->connect_errno.": ".$db->connect_error.PHP_EOL); exit(1); } echo "Database connection OK".PHP_EOL;'
```

3. If administrator access is available, inspect accounts:

```bash
kubectl --context=kiratech -n "$lab_ns" exec deployment/"$db_deploy" -- sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -u root -e "SELECT User, Host, plugin FROM mysql.user;"'
```

4. For the original credential files, inspect formatting without exposing values:

```bash
python3 - <<'PY'
from pathlib import Path
for name in ("mysql-password", "mysql-root-password"):
    data = (Path(".local") / name).read_bytes()
    print(name, "bytes=", len(data),
          "ends_with_LF=", data.endswith(b"\n"),
          "contains_CR=", b"\r" in data)
PY
```

Error 1045 identifies an authentication/access problem; it does not by itself
prove an incorrect password. Check account existence, host matching,
configuration references and credential formatting.

### Correct and validate

The controlled comparison used fresh PVCs and otherwise identical
configuration. Removing the final LF from the credential copies allowed
automatic database/user/grant creation and a successful application-user
SELECT 1 query.

For a new installation, generate credentials without trailing line endings
and initialize fresh storage. See the incident report and
[clean installation test](clean-install-test.md).

For a database with existing data:
- Preserve its current credential files and storage.
- Establish whether the failure is missing accounts, grants or a password mismatch.
- Back up data before potentially destructive recovery.
- Apply account repair or coordinated password changes with appropriate
  administrator review, then validate WordPress connectivity.

The original installation was repaired by creating the missing application
database, user and grants. Its original credentials were retained.
Changing a Secret alone does not update passwords stored in MySQL.

Validate database access, WordPress availability and the intended content.
Do not delete PVCs to resolve an authentication error.

Escalate unavailable administrator access, uncertain account repair,
persistent initialization failures or suspected data damage.

## Case 2 — Affected PHP runtime: replace the published image

Full procedure: [published-image security lab](../labs/security/README.md).
Scope: wordpress-security; Deployment wordpress. This uses kubectl manifests.

### Diagnose and choose the correction

1. Record the deployed image and inspect the runtime inside the running Pod:

```bash
kubectl --context=kiratech -n wordpress-security get deployment wordpress -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
kubectl --context=kiratech -n wordpress-security exec deployment/wordpress -- php -r 'require "/var/www/html/wp-includes/version.php"; echo "WordPress: ".$wp_version.PHP_EOL."PHP CLI: ".PHP_VERSION.PHP_EOL;'
```

2. Check Tools > Site Health > Info > Server in WordPress as well. The recorded
   CLI and web runtime were PHP 8.3.35; the web SAPI was apache2handler.
3. Compare those versions and runtime conditions with the vendor advisories
   linked in the lab guide. The lab assessed the fixes provided by PHP 8.3.36.
   A running Pod or HTTP 200 does not resolve a version-based security finding.
4. Inspect the affected/patched manifest diff. Only the container image
   reference changes, but the replacement image also updates WordPress and
   Apache. Updating WordPress in its Dashboard would not replace PHP.

### Prepare and apply

Before updating, preserve a private database dump and wp-content archive;
record versions, Pod identities, PVC bindings and upload SHA-256 hashes.
Use the lab guide's backup preparation and keep backups outside Git.
The recorded dump footer and gzip integrity check passed; restoration was not tested.

Apply to the existing lab after this preparation:

```bash
kubectl --context=kiratech -n wordpress-security apply -f labs/security/stack-patched.yaml
kubectl --context=kiratech -n wordpress-security rollout status deployment/wordpress --timeout=300s
```

This replaces the WordPress Pod using Recreate and can interrupt service.

### Validate and close

- Repeat CLI and web-runtime checks: recorded PHP 8.3.35 -> 8.3.36.
- Record the deployed digest; WordPress also changed 7.1.2 -> 7.1.3.
- Confirm WordPress readiness, database access and the original post/image.
- Compare upload hashes and PVC volume bindings; both were preserved.
- Inspect logs. The recorded post-update review covered a 60-line sample.

Evidence: [versions before](evidence/security-versions-before.txt),
[versions after](evidence/security-versions-after.txt),
[image before](evidence/security-image-before.txt),
[image after](evidence/security-image-after.txt),
[upload hashes before](evidence/security-uploads-before.txt) and
[after](evidence/security-uploads-after.txt).

### Recovery and escalation

If rollout or application checks fail, collect events, logs and probe results;
check image availability and database connectivity before further changes.
Prefer recovering the corrected deployment. Reverting to the affected image
reintroduces the finding and is not a completed security remediation.
Image rollback does not restore database contents; assess data compatibility.
Rollback and backup restoration were not executed in this security lab.

Escalate unclear advisory applicability, suspected compromise, uncertain data
integrity or the absence of a compatible correction. No exploit was executed;
this evidence does not establish that the complete stack has no vulnerabilities.
The separate advisory follow-up remains documented in the lab guide.

## Case 3 — Affected PHP runtime: rebuild the image and upgrade with Helm

Full procedure: [custom-image security lab](../labs/security-build/README.md).
Scope: wordpress-build; release patch-lab; Deployment patch-lab-wordpress.

This extends Case 2 by simulating that a corrected WordPress image is
unavailable while a corrected PHP/Apache base is available. A published
WordPress correction actually existed; its absence was a lab constraint.

### Diagnose and build the correction

1. Record the running image and PHP CLI/web versions as in Case 2, using
   namespace wordpress-build and Deployment patch-lab-wordpress.
2. Inspect the upstream Dockerfile and identify that PHP comes from its FROM
   base. Compare Dockerfile.affected with Dockerfile.patched:

```bash
diff -u labs/security-build/Dockerfile.affected labs/security-build/Dockerfile.patched
```

A diff exit code of 1 is expected when showing the intended change.
The sole Dockerfile difference is the pinned PHP/Apache base, 8.3.35 -> 8.3.36.
Both custom images contain WordPress 7.1.3. This is a base-image correction
and rebuild, not a manually written PHP source patch; other base components
may change too.

3. Follow the lab guide to build both image variants, inspect their versions
   and load them into Minikube. With imagePullPolicy Never, the corrected
   image must already exist on the node.
4. Compare rendered manifests using the affected and patched values.
   The recorded comparison changed only the WordPress image reference.
5. Back up the existing database and wp-content, and record upload hashes,
   Pod identities and PVC bindings using the lab guide before upgrading.

### Apply and validate

```bash
helm upgrade patch-lab charts/kiratech-wordpress --kube-context kiratech -n wordpress-build --values labs/security-build/values-patched.yaml --wait --timeout 5m
kubectl --context=kiratech -n wordpress-build exec deployment/patch-lab-wordpress -- php -r 'require "/var/www/html/wp-includes/version.php"; echo "WordPress: ".$wp_version.PHP_EOL."PHP CLI: ".PHP_VERSION.PHP_EOL;'
kubectl --context=kiratech -n wordpress-build get pods,pvc
helm history patch-lab --kube-context kiratech -n wordpress-build
```

The recorded upgrade produced revision 2, deployed: WordPress remained
7.1.3 and PHP changed to 8.3.36. Verify PHP in the web interface too, not just
CLI. Reopen the article and compare uploaded-file hashes with the baseline.
The MySQL Pod and PVC bindings were retained, and the post/image survived.

Evidence: [custom-image lab evidence](evidence/security-build/).
These results refer to the recorded chart 0.1.0 execution; later chart changes
are described in the Ingress lab. Do not reinterpret old output as a new test.

### Recovery and escalation

Collect Helm status/history and live resource evidence if the upgrade fails.
Check image loading, image reference, probes and database access. A Helm
revision alone does not prove application or security recovery.

Rollback and restoration were not tested here. Revision 1 selects the
affected runtime; rolling back to it would reintroduce the finding and would
not restore data. Escalate suspected compromise, incompatible dependencies,
failed integrity checks or uncertain recovery. The same advisory and
security-verification limits as Case 2 apply.

## Case 4 — Incorrect image reference after Helm upgrade

Report: [image-not-available.md](incidents/image-not-available.md)

Recorded cause:
kiratech-wordpress:7.1.3-php8.3.36-typo-lab was absent from the node,
and imagePullPolicy: Never prevented fetching it.

### Diagnose

```bash
kubectl --context=kiratech -n wordpress-troubleshooting get pods

kubectl --context=kiratech -n wordpress-troubleshooting describe pod -l app.kubernetes.io/instance=image-lab,tier=frontend

kubectl --context=kiratech -n wordpress-troubleshooting get deployment image-lab-wordpress -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}{.spec.template.spec.containers[0].imagePullPolicy}{"\n"}'

minikube image ls --profile kiratech
helm history image-lab --kube-context kiratech -n wordpress-troubleshooting
```

Confirm the image reference, policy and kubelet event.
An unstarted container has no application execution to diagnose.
Increasing the Helm timeout does not supply the missing image.

### Recover and validate

Confirm that the intended image exists on the node. In the recorded lab,
the correct values select the already loaded PHP 8.3.36 image:

```bash
helm upgrade image-lab charts/kiratech-wordpress --kube-context kiratech -n wordpress-troubleshooting --values labs/security-build/values-patched.yaml --wait --timeout 5m

kubectl --context=kiratech -n wordpress-troubleshooting get deployments,pods,pvc
helm history image-lab --kube-context kiratech -n wordpress-troubleshooting
```

A rollback to a verified working revision is another recovery option.
Inspect that revision's image and data compatibility before choosing it.

Actual test history:
1. Revision 1 installed successfully.
2. Revision 2 failed after introducing the incorrect image tag.
3. Rollback created failed revision 3 with Progress deadline exceeded;
   subsequent inspection showed the correct image and Ready resources.
4. An explicit upgrade with correct values completed as deployed revision 4.

The cause of the rollback wait error remains unconfirmed.
Inspect live resources after an operation error before retrying.
A Helm rollback restores configuration, not database contents.

Final validation returned WordPress 7.1.3, PHP 8.3.36 and HTTP 200 at
the installer through Service port-forward on port 8084. MySQL and PVC
bindings were retained. Full CMS installation was outside this incident test.

Escalate unavailable authorized images, runtime/policy problems, repeated
recovery errors or unresolved differences between Helm and live state.

## Case 5 — Ready application, Ingress HTTP 503

Scope: ingress-lab release in wordpress-ingress, Traefik in ingress-system.

1. Confirm the HTTP failure through the configured hostname.
2. Inspect Pod readiness and labels.
3. Compare the application Service selector with those labels.
4. Inspect EndpointSlice addresses and readiness.
5. Test HTTP inside the application Pod using the expected Host header.
6. Inspect the Ingress backend reference and controller logs.
7. If the selector is wrong, restore the value declared in the chart.
8. Wait for endpoint discovery, then verify HTTP and application content.

In the reproduced case, frontend-typo matched no Pods. The application
remained Ready and answered HTTP 200 directly; Ingress returned 503.
Restoring frontend recovered access without restarting Pods.

Commands, evidence and escalation guidance are in the
[Ingress lab guide](../labs/ingress/README.md).

## Escalation package and closure

Provide:
- Impact, timeline, context, namespace and release.
- Last known working state and recent changes.
- Exact image references, pull policies and tool versions.
- Pod status/events, relevant logs and Deployment conditions.
- Helm history, attempted commands and outcomes.
- Hypotheses, supporting evidence and remaining uncertainty.

Review collected output before sharing. Exclude passwords, Secret data,
database dumps and private user content.

Close an incident only after verifying the intended configuration,
resource readiness and relevant application access. Record limitations.

Evidence:
- [MySQL failed initialization](evidence/mysql-init-failed.log)
- [MySQL clean initialization](evidence/mysql-init-clean.log)
- [Published-image remediation](../labs/security/README.md#verified-results)
- [Custom-image remediation evidence](evidence/security-build/)
- [Missing-image incident evidence](evidence/image-missing/)
- [Ingress routing evidence](evidence/ingress-selector/)

Local storage and single replicas do not provide high availability.
PVC persistence is not a backup; backup restoration remains untested.
