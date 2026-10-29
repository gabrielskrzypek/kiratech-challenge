# L2 support runbook — WordPress and MySQL

Context: kiratech
Last updated: 2026-10-29

## Scope and installations

Run commands from the repository root in Ubuntu WSL.
Confirm the affected namespace before acting.

| Installation | Namespace | WordPress Deployment | MySQL Deployment | Helm release |
| --- | --- | --- | --- | --- |
| Original manifest | wordpress | wordpress | wordpress-mysql | None |
| Custom-image lab | wordpress-build | patch-lab-wordpress | patch-lab-mysql | patch-lab |
| Missing-image incident | wordpress-troubleshooting | image-lab-wordpress | image-lab-mysql | image-lab |

The MySQL initialization incident was also reproduced in wordpress-check
and corrected using fresh storage in wordpress-check-clean.

This runbook consolidates verified incident procedures and diagnostic
commands. Detailed records distinguish actual observations from hypotheses.
Some collection commands below are reusable guidance rather than additional
tests claimed as executed.

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

## Case 2 — Incorrect image reference after Helm upgrade

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
- [Missing-image incident evidence](evidence/image-missing/)

Local storage and single replicas do not provide high availability.
PVC persistence is not a backup; backup restoration remains untested.
