# Technical demonstration guide

Updated: 2026-11-02. Suggested presentation: 15–20 minutes after preparation.
Run commands from the repository root in Ubuntu WSL.

The complete presentation sequence has not been rehearsed. The resource
change and restoration in step 7 were verified on 2026-11-02; see the
[verification report](demo-change-test.md) and its session capture.

## Prepare the scope

Use the retained `patch-lab` release in `wordpress-build` for the main walkthrough.
Use `ingress-lab` in `wordpress-ingress` only for the optional Ingress view.
Start Docker Desktop. Never show Secret contents, credential files or SQL dumps.
Have the [documentation map](README.md) and [evidence index](evidence/README.md) ready.

If an installation must be shown live, prepare a separate disposable namespace,
release and credential-file paths using the [installation guide](delivery-workflow.md).
Use the corrected-image values for ordinary installation; affected values are
only for deliberate security-lab reproduction. Building/loading images and web
setup belong in preparation unless the reviewer wants to watch those steps.

## 1. Repository and application choice

Show the public repository and its [clone/tool checks](delivery-workflow.md#obtain-the-project-and-check-tools).
If already cloned, inspect the existing copy:

```bash
git status --short --branch
git log -1 --oneline
ls k8s charts labs docs
```

Explain: WordPress provides a web tier, database and uploaded files for
observable support checks. The image-runtime security finding motivated the
patching investigation. WordPress source and Docker image packaging are separate;
this project adapts packaging, deployment and operations.

## 2. Cluster preparation

```bash
minikube start --profile kiratech
minikube status --profile kiratech
kubectl --context=kiratech get nodes
kubectl --context=kiratech get storageclass
```

Expected: node Ready, working context and the default StorageClass.
This resumes the existing cluster. A new cluster requires the
[local setup](local-setup.md), image loading and fresh installation.

## 3. Installation and Helm inputs

Open Chart.yaml, values.yaml and the custom lab's two override files.
Show the rendered corrected configuration without changing the cluster:

```bash
helm lint charts/kiratech-wordpress --values labs/security-build/values-patched.yaml
helm template patch-lab charts/kiratech-wordpress --namespace wordpress-build --values labs/security-build/values-patched.yaml
helm status patch-lab --kube-context kiratech -n wordpress-build
```

Explain: templates describe resources; values supply configuration; the release
identifies an installation. Namespace and Secret are prepared separately.
Use [build, credentials and installation instructions](../labs/security-build/README.md)
for a live fresh installation. Existing retained resources must not be reinitialized.
The [clean-checkout report](fresh-checkout-test.md) records a separate successful
install and removal using existing images and cluster, not a new-machine rebuild.

## 4. Pods, Services and storage

```bash
kubectl --context=kiratech -n wordpress-build get deployments,pods,services,pvc
helm history patch-lab --kube-context kiratech -n wordpress-build
```

Expected: both Deployments available, Pods Ready, PVCs Bound.
Explain Service selectors, separate content/database storage and Recreate's
service interruption. Use the [architecture diagrams](architecture.md).

## 5. Application access

In a separate terminal, keep this command running:

```bash
kubectl --context=kiratech -n wordpress-build port-forward service/patch-lab-wordpress 8083:80
```

Open http://localhost:8083/ and the existing article with text and uploaded image.
Administration is at http://localhost:8083/wp-admin/. In Site Health, show the
PHP web-runtime version. In the main terminal:

```bash
curl --noproxy '*' --fail --silent --show-error --location --max-time 20 --output /dev/null --write-out 'HTTP %{http_code}\n' http://localhost:8083/
kubectl --context=kiratech -n wordpress-build exec deployment/patch-lab-wordpress -- php -r 'require "/var/www/html/wp-includes/version.php"; echo "WordPress: ".$wp_version.PHP_EOL."PHP: ".PHP_VERSION.PHP_EOL;'
```

Expected for the corrected custom image: WordPress 7.1.3 and PHP 8.3.36.
HTTP success alone does not verify the article, login or security assessment.

## 6. Logs, events and probes

```bash
kubectl --context=kiratech -n wordpress-build logs deployment/patch-lab-wordpress --tail=30
kubectl --context=kiratech -n wordpress-build get events --sort-by=.metadata.creationTimestamp
kubectl --context=kiratech -n wordpress-build describe deployment patch-lab-wordpress
```

Explain startup versus readiness versus liveness. Probe success is narrower
than a full application check; MySQL TCP readiness does not prove authentication.
Events may expire, so an empty current listing does not erase a recorded incident.

## 7. Small reversible configuration change

Use a CPU request change, keeping the corrected image. This avoids changing
initialized database settings. First confirm the existing WordPress request
is `100m` and available node capacity is sufficient:

```bash
kubectl --context=kiratech -n wordpress-build get deployment patch-lab-wordpress -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}{"\n"}'
kubectl --context=kiratech describe node kiratech
```

If the baseline differs, stop and choose a matching restoration value before
proceeding. Check the lab's backup procedure before modifying retained data-bearing
workloads. This change replaces the WordPress Pod and Recreate interrupts
access. The [verified run](demo-change-test.md) changed 100m to 150m and back
to 100m, using a captured copy of the active Helm values. Preserve those values
for both upgrades rather than replacing existing overrides with lab defaults.
Run the following commands in the same terminal. The values capture stays in
ignored local storage and must not be displayed or committed.

```bash
umask 077
mkdir -p .local
demo_values=$(mktemp .local/demo-values.XXXXXX.yaml)
helm get values patch-lab --kube-context kiratech -n wordpress-build --all --output yaml > "$demo_values"
```

Stop if the export fails or the file is empty. Inspect the proposed manifests
privately before applying; the current chart may differ from the installed
chart, so restoring the CPU request does not roll back every chart change.

```bash
test -s "$demo_values" && helm template patch-lab charts/kiratech-wordpress --namespace wordpress-build --values "$demo_values" --set wordpress.resources.requests.cpu=150m > .local/demo-proposed.yaml
```

After checking the rendered configuration, apply the change:

```bash
helm upgrade patch-lab charts/kiratech-wordpress --kube-context kiratech -n wordpress-build --values "$demo_values" --set wordpress.resources.requests.cpu=150m --wait --timeout 5m
kubectl --context=kiratech -n wordpress-build get deployment patch-lab-wordpress -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}{"\n"}'
```

Expected: request `150m`, Deployment available, content retained. Restore `100m`:

```bash
helm upgrade patch-lab charts/kiratech-wordpress --kube-context kiratech -n wordpress-build --values "$demo_values" --set wordpress.resources.requests.cpu=100m --wait --timeout 5m
kubectl --context=kiratech -n wordpress-build get deployments,pods,pvc
```

Reopen port-forward after replacement and check the article again.
If either upgrade fails, collect status, history, events and Pod diagnostics;
do not repeat upgrades blindly. ConfigMap-only changes behave differently:
see the [explicit restart procedure](runbook.md#configuration-updates-and-running-pods).

## 8. Troubleshooting and security remediation

Describe one controlled operational incident using its actual captures:

| Observation | Interpretation and correction | Record |
| --- | --- | --- |
| ErrImageNeverPull | Nonexistent local tag with Never policy; correct image reference and reconcile Helm state | [Missing image](incidents/image-not-available.md) |
| Ready Pod, external HTTP 503, direct Pod HTTP 200, empty endpoints | Service selector matches no Pods; restore frontend and verify endpoints/content | [Ingress selector](incidents/ingress-service-selector.md) |

Show before/failure/recovery evidence, then the corresponding runbook steps.
A live fault is optional and should use the isolated lab guide; do not inject
it into the retained main installation just to present the report.

Also distinguish the two security corrections: replace an available published
image, or inspect FROM and rebuild with a corrected base. Use the
[published-image report](incidents/php-security-image-update.md) and
[custom-build report](incidents/php-security-custom-build.md). These are two
remediation paths for the same assessed PHP issue. No exploit or proof of
absence of all vulnerabilities was performed.

If the Ingress lab is running, its existing port-forward to Traefik and
[smoke script](../labs/ingress/smoke-test.sh) demonstrate host-based routing:

```bash
./labs/ingress/smoke-test.sh
```

Follow the [Ingress access setup](../labs/ingress/README.md) first; it uses
wordpress.lab.test:8086 and a controller port-forward, not public exposure.

## 9. Removal and reinstall boundaries

Show the [verified uninstall evidence](evidence/fresh-checkout/README.md).
Explain that uninstalling this chart removes its PVCs and can delete their
underlying data. A Helm rollback does not restore database or volume contents.

If a separate disposable `demo` release was actually created in
`wordpress-demo` for the presentation, and its data can be discarded:

```bash
helm uninstall demo --kube-context kiratech -n wordpress-demo --wait --timeout 5m
kubectl --context=kiratech -n wordpress-demo get deployments,pods,services,pvc
```

These names are an example, not an installation created by this guide.
Namespace and Secret remain outside chart ownership. Remove them only after
confirming the namespace is dedicated to this disposable instance. Retain
patch-lab and the other evidence-producing installations. For reinstall,
follow fresh credentials/storage preparation rather than assuming existing
MySQL initialization variables will reset an old volume.

## 10. Krateo concept

Open the [Krateo proposal](krateo-proposal.md). Explain proposed inputs,
versioned chart/image selection, Secret delivery and controller-managed
installation. Krateo was not installed; the request is illustrative YAML.

## 11. AI use and verification

Use the [AI record](ai-usage.md): show one suggestion, the observed output
and the resulting correction. Traefik chart-value mistakes are a concrete
example. Explain the verification steps and remaining limits: no backup
restore, full fresh-machine rebuild, exploit, TLS/public Ingress or
implemented CI/CD/Krateo integration.
