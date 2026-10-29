# Incident: unavailable local image after a Helm upgrade

Date: 2026-10-29
Context: kiratech
Namespace: wordpress-troubleshooting
Helm release: image-lab
Chart: charts/kiratech-wordpress
Helm version: 4.3.1

## Scope

Controlled deployment failure caused by an incorrect WordPress image tag.
The test used a separate namespace and did not modify the other installations.

The baseline used the custom image:
kiratech-wordpress:7.1.3-php8.3.36-lab

This lab verified component startup and HTTP access to the WordPress installer.
The WordPress web installation was not completed in this namespace.

## Initial state

Helm revision 1 was deployed successfully.
Both Deployments had one available replica, both Pods were Ready,
and both PVCs were Bound.

Baseline evidence:
[resources-before.txt](../evidence/image-missing/resources-before.txt)

## Controlled change

The override file
[values-image-missing.yaml](../../labs/troubleshooting/values-image-missing.yaml)
introduced this configuration:

```yaml
wordpress:
  image: kiratech-wordpress:7.1.3-php8.3.36-typo-lab
  imagePullPolicy: Never
```

The additional "typo" made the reference different from the loaded image.
With Never, the kubelet cannot download a missing image.

The chart uses Recreate, so replacing the working Pod with an unstartable
Pod made WordPress unavailable in this namespace.

## Reproduction procedure

Run commands from the repository root.
Prerequisites:
- The kiratech cluster is running.
- The correct custom image has been built and loaded into minikube.
- The credential files from the custom-image lab exist without trailing LF.
- Use a fresh namespace and release for the initialization commands below.
  They were already executed during the recorded test.

See the [custom-image lab](../../labs/security-build/README.md)
for image construction, loading and credential generation.

```bash
kubectl --context=kiratech create namespace wordpress-troubleshooting

kubectl --context=kiratech -n wordpress-troubleshooting create secret generic mysql-credentials --from-file=password=.local/build-mysql-password --from-file=root-password=.local/build-mysql-root-password

helm install image-lab charts/kiratech-wordpress --kube-context kiratech -n wordpress-troubleshooting --values labs/security-build/values-patched.yaml --wait --timeout 5m

kubectl --context=kiratech -n wordpress-troubleshooting get deployments,pods,pvc
```

After confirming the baseline, introduce the faulty override:

```bash
helm upgrade image-lab charts/kiratech-wordpress --kube-context kiratech -n wordpress-troubleshooting --values labs/security-build/values-patched.yaml --values labs/troubleshooting/values-image-missing.yaml --wait --timeout 60s
```

The second values file overrides the image while preserving the remaining
lab configuration from the first file.

## Observed symptoms

- Helm revision 2 failed with exit code 1 after its 60-second wait.
- WordPress availability was 0/1.
- The WordPress container showed ErrImageNeverPull and zero restarts.
- MySQL remained Running and Ready.

The Helm timeout described the unsuccessful wait; it did not identify
the underlying cause.

Evidence:
- [upgrade-failed.txt](../evidence/image-missing/upgrade-failed.txt)
- [upgrade-exit-code.txt](../evidence/image-missing/upgrade-exit-code.txt)
- [pods-failed.txt](../evidence/image-missing/pods-failed.txt)

## Diagnostic commands and hypothesis

Initial hypothesis: the configured image reference is absent from the node,
and the pull policy prevents fetching it.

```bash
kubectl --context=kiratech -n wordpress-troubleshooting describe pod -l app.kubernetes.io/instance=image-lab,tier=frontend

kubectl --context=kiratech -n wordpress-troubleshooting get deployment image-lab-wordpress -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}{.spec.template.spec.containers[0].imagePullPolicy}{"\n"}'

helm history image-lab --kube-context kiratech -n wordpress-troubleshooting
```

Findings:
- PodScheduled was True: the Pod had been assigned to the node.
- The container was Waiting, with no Container ID or Image ID.
- The Deployment referenced the tag containing "typo".
- The pull policy was Never.
- Kubelet events explicitly reported that this image was not present
  with pull policy Never.

Diagnosis: incorrect image reference under a local-only image policy.
The container had not started; application logs and database authentication
were not the appropriate first diagnostic targets for this failure.

Evidence:
- [pod-description-failed.txt](../evidence/image-missing/pod-description-failed.txt)
- [image-policy-failed.txt](../evidence/image-missing/image-policy-failed.txt)
- [helm-history-failed.txt](../evidence/image-missing/helm-history-failed.txt)

## Recovery attempt and additional observation

A rollback to the known working revision was attempted:

```bash
helm rollback image-lab 1 --kube-context kiratech -n wordpress-troubleshooting --wait --timeout 5m
```

Helm returned "Progress deadline exceeded" and recorded revision 3 as failed.
Subsequent inspection showed that Kubernetes had nevertheless restored
the correct image and recovered the Deployment:

- Image: kiratech-wordpress:7.1.3-php8.3.36-lab.
- Available=True and Progressing=True.
- WordPress Pod Running and Ready.
- MySQL Pod unchanged.
- Both PVCs still Bound to their original volumes.

The cause of the rollback wait error was not established. A transient
evaluation of an earlier Deployment condition is a hypothesis, not a
confirmed Helm defect.

Evidence:
- [rollback.txt](../evidence/image-missing/rollback.txt)
- [rollback-failed-resources.txt](../evidence/image-missing/rollback-failed-resources.txt)
- [rollback-failed-deployment.txt](../evidence/image-missing/rollback-failed-deployment.txt)
- [rollback-failed-history.txt](../evidence/image-missing/rollback-failed-history.txt)

## Final correction

To create a successful Helm revision using the intended configuration,
the correct values were applied explicitly:

```bash
helm upgrade image-lab charts/kiratech-wordpress --kube-context kiratech -n wordpress-troubleshooting --values labs/security-build/values-patched.yaml --wait --timeout 5m
```

Result: revision 4, deployed, Upgrade complete.
The recovered WordPress Pod was retained through this final upgrade.

Evidence:
- [reconcile-upgrade.txt](../evidence/image-missing/reconcile-upgrade.txt)
- [helm-history-recovered.txt](../evidence/image-missing/helm-history-recovered.txt)
- [resources-recovered.txt](../evidence/image-missing/resources-recovered.txt)

## Recovery verification

```bash
kubectl --context=kiratech -n wordpress-troubleshooting exec deployment/image-lab-wordpress -- php -r 'require "/var/www/html/wp-includes/version.php"; echo "WordPress: ".$wp_version.PHP_EOL."PHP: ".PHP_VERSION.PHP_EOL;'

kubectl --context=kiratech -n wordpress-troubleshooting port-forward service/image-lab-wordpress 8084:80
```

With port-forward running, from another terminal:

```bash
curl --silent --show-error --max-time 15 --output /dev/null --write-out 'HTTP %{http_code}\n' http://localhost:8084/wp-admin/install.php
```

Observed:
- Both Deployments available and Pods Ready.
- WordPress 7.1.3 and PHP 8.3.36.
- HTTP 200 through the Service port-forward.
- MySQL Pod and PVC bindings preserved.

Evidence:
- [versions-recovered.txt](../evidence/image-missing/versions-recovered.txt)
- [http-recovered.txt](../evidence/image-missing/http-recovered.txt)

The HTTP check verifies access to the installer. It does not establish
full CMS functionality or backup restoration.

## Prevention

- Check image references and pull policy before deployment.
- For this local lab, confirm loaded images with minikube image ls.
- helm lint validates the chart; it does not prove image availability.
- Compare rendered manifests and retain a known working configuration.
- After an operation error, inspect live resources as well as Helm history.
- Keep the faulty override only for deliberate incident reproduction.

## Escalation criteria

Escalate when:
- The intended image is unavailable from the authorized source.
- Recovery fails despite a verified image reference and configuration.
- Helm and live resource states remain inconsistent after inspection.
- Image policy, node runtime, registry access or platform permissions
  require changes outside the operator's scope.
- Data corruption or an uncertain recovery procedure is suspected.

Include context, namespace, release, image reference, pull policy,
tool versions, timestamps, Helm history, Pod events, Deployment conditions,
commands attempted and their outcomes. Exclude credentials and Secret data.

For a repeated rollback wait error, capture the resource conditions,
generation/observedGeneration and client output around the operation
before attributing it to a tool defect.

## AI assistance

AI helped propose the controlled failure, explain the difference between
Helm timeout and container startup failure, and interpret the events.
The candidate executed the commands and verified the outputs.
The rollback error was retained in the record rather than presented as
a successful Helm operation.

## References

- https://kubernetes.io/docs/concepts/containers/images/
- https://helm.sh/docs/helm/helm_rollback/
- https://helm.sh/docs/helm/helm_upgrade/
