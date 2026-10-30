# WordPress Ingress and routing troubleshooting lab

## Scope and verified result

This lab adds optional Kubernetes Ingress support to the project's Helm
chart and uses Traefik as the Ingress controller.

Verified on 2026-10-30:
- WordPress installation and access through the configured hostname.
- HTTP 503 caused by an incorrect Service selector.
- Direct application access remained HTTP 200 during the fault.
- Recovery by correcting the selector, without restarting the application.
- HTTP 200 and expected page content after recovery.

This is a local HTTP lab, not an Internet-facing production deployment.

## Components and configuration

| Component | Configuration |
| --- | --- |
| Kubernetes context | kiratech |
| Controller release / namespace | traefik / ingress-system |
| Traefik chart / application version | 42.1.3 / v3.7.16 |
| Application release / namespace | ingress-lab / wordpress-ingress |
| IngressClass | traefik |
| Hostname | wordpress.lab.test |
| Local access | http://wordpress.lab.test:8086/ |
| WordPress image | kiratech-wordpress:7.1.3-php8.3.36-lab |
| Credential Secret | mysql-credentials, created separately |

Ingress is disabled by default in the application chart.
The lab values enable it and select the custom application image.

Traefik reads the Ingress rule and discovers the backend endpoints.
Its default backend load balancing uses Pod addresses; requests do not
necessarily traverse the application's Service ClusterIP.

The local port-forward targets Traefik, rather than WordPress directly.
This exercises the controller and its host-based routing.

## Prerequisites

Run commands from the repository root.

Required: the running kiratech cluster, Helm, kubectl, Python 3, Bash and
curl. Build and load the patched custom image using
[the custom image lab](../security-build/README.md).

The following installation commands assume that the lab releases,
application namespace and credential files do not already exist.

## Controller installation

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update traefik

helm install traefik traefik/traefik \
  --version 42.1.3 \
  --kube-context kiratech \
  --namespace ingress-system --create-namespace \
  --values labs/ingress/traefik-values.yaml \
  --skip-crds --wait --timeout 5m

kubectl --context=kiratech get ingressclass
kubectl --context=kiratech -n ingress-system get pods,services
```

The values disable the CRD and Gateway providers and the dashboard route.
The controller Service is ClusterIP. Access logs are enabled, with header
and query-parameter values dropped.

For this chart version, use `service.spec.type`, `log` and `accessLog`.
The earlier `service.type` setting was accepted but did not change the
rendered Service; checking the live Service exposed the mismatch.

## Application installation

Generate private credentials without a trailing newline:

```bash
umask 077
mkdir -p .local

python3 - <<'PY'
from pathlib import Path
import secrets

paths = [
    Path(".local/ingress-mysql-password"),
    Path(".local/ingress-mysql-root-password"),
]
assert not any(path.exists() for path in paths), "Credential files already exist"

for path in paths:
    with path.open("x") as output:
        output.write(secrets.token_hex(24))
PY

kubectl --context=kiratech create namespace wordpress-ingress

kubectl --context=kiratech -n wordpress-ingress \
  create secret generic mysql-credentials \
  --from-file=password=.local/ingress-mysql-password \
  --from-file=root-password=.local/ingress-mysql-root-password

helm lint charts/kiratech-wordpress \
  --values labs/ingress/values.yaml

helm install ingress-lab charts/kiratech-wordpress \
  --kube-context kiratech \
  --namespace wordpress-ingress \
  --values labs/ingress/values.yaml \
  --wait --timeout 5m
```

Keep the following command running in a separate terminal:

```bash
kubectl --context=kiratech -n ingress-system \
  port-forward service/traefik 8086:80
```

For browser access on Windows, edit the following file as administrator:

```text
C:\Windows\System32\drivers\etc\hosts
```

Add:

```text
127.0.0.1 wordpress.lab.test
```

Open http://wordpress.lab.test:8086/ and install WordPress in English.
Use private administrator credentials. Publish a post titled
`Ingress routing verification`, then verify it on the public site.

## Smoke check

```bash
./labs/ingress/smoke-test.sh
```

The script requires HTTP 200 and the expected article title.
Connection failures, unexpected status codes and missing content return
a nonzero exit code. The successful path was executed and recorded.

Optional environment variables: INGRESS_HOST, INGRESS_PORT,
INGRESS_ADDRESS and EXPECTED_TEXT.

The script uses curl --resolve, so it does not require the hosts-file
entry used by the browser. Keep the Traefik port-forward running.

## Reproduced incident: healthy Pod, HTTP 503

### Hypothesis and diagnosis

A Service selects Pods using labels. Changing its selector from
`tier: frontend` to `tier: frontend-typo` removes all matching backends.

| Observation | Interpretation |
| --- | --- |
| WordPress remained Running and Ready | Readiness alone did not verify the complete access path |
| Service selector contained frontend-typo | The Service configuration did not match the Pod labels |
| EndpointSlice had endpoints: null | No backend addresses were available |
| Ingress request returned 503 | The route had no available backend |
| Direct request inside the WordPress container returned 200 | The application still served HTTP |

Traefik's allowEmptyServices setting is explicitly enabled for this lab.
It keeps the route when no endpoints are available and returns HTTP 503.

### Reproduction

Run only against this isolated lab:

```bash
kubectl --context=kiratech -n wordpress-ingress \
  patch service ingress-lab-wordpress --type=merge \
  -p '{"spec":{"selector":{"tier":"frontend-typo"}}}'
```

Allow the endpoint and controller configuration to converge, then inspect:

```bash
kubectl --context=kiratech -n wordpress-ingress get pods --show-labels

kubectl --context=kiratech -n wordpress-ingress \
  get service ingress-lab-wordpress -o yaml

kubectl --context=kiratech -n wordpress-ingress \
  get endpointslices \
  -l kubernetes.io/service-name=ingress-lab-wordpress -o yaml

curl --noproxy '*' \
  --resolve wordpress.lab.test:8086:127.0.0.1 \
  --silent --show-error --max-time 15 \
  --output /dev/null --write-out 'HTTP %{http_code}\n' \
  http://wordpress.lab.test:8086/

kubectl --context=kiratech -n wordpress-ingress \
  exec deployment/ingress-lab-wordpress -- \
  curl --silent --show-error --max-time 15 \
  --header 'Host: wordpress.lab.test:8086' \
  --output /dev/null --write-out 'Direct Pod HTTP %{http_code}\n' \
  http://127.0.0.1/
```

### Recovery and verification

```bash
kubectl --context=kiratech -n wordpress-ingress \
  patch service ingress-lab-wordpress --type=merge \
  -p '{"spec":{"selector":{"tier":"frontend"}}}'
```

After endpoint discovery converges, run the smoke check.
The observed recovery restored a Ready endpoint, HTTP 200 and the
expected article content. Pod names and restart counts were unchanged.

The chart's Service selector was never modified. Recovery restored the
live selector to the value already declared in Git.

If recovery fails, inspect Ingress backend names and ports, endpoint
readiness and controller logs before changing application credentials
or restarting Pods. Escalate with these outputs if a healthy backend
remains unreachable from the controller.

## Other issues encountered during setup

WordPress's installer redirected the HTTP probe to install.php.
A measured successful response took 1.015 seconds, while the probes
used the default one-second timeout. Events reported timeouts and
the application database connection succeeded.

Increasing startup and readiness timeouts to five seconds restored
availability. Both settings were subsequently saved in the chart.
The reason for the installer's response time was not investigated.

Interrupting the initial Helm install left revision 1 pending-install.
A duplicate install was rejected. Recovery reapplied revision 1 using
helm rollback without readiness waiting, then upgraded using the
corrected chart with --wait. Revision 3 became deployed.

The rollback alone was not treated as proof of application health.
The subsequent upgrade and HTTP checks verified recovery.
PVCs were preserved. The old pending revision remains in the history.

## Evidence

- ../../docs/evidence/ingress/: installation errors, probe adjustment,
  Helm recovery and initial HTTP access.
- ../../docs/evidence/ingress-selector/: healthy, failed and recovered
  endpoint states, Pod labels, HTTP results and controller log capture.
- The historical helm-install.txt records the duplicate-install error,
  not a successful initial installation.

## Removal

The following commands delete this lab's application and persistent
data. Do not run them against an installation whose data must be kept.

```bash
helm uninstall ingress-lab --kube-context kiratech \
  -n wordpress-ingress --wait --timeout 5m

kubectl --context=kiratech delete namespace wordpress-ingress
```

Stop the local port-forward with Ctrl+C. Remove the local hosts-file
entry if it is no longer needed.

Only if no other application uses this controller:

```bash
helm uninstall traefik --kube-context kiratech \
  -n ingress-system --wait --timeout 5m
```

Removal of this new Ingress lab has not been tested.
Installation/removal was verified separately in the fresh-checkout test.

## Limitations

- No TLS, public DNS or external load-balancer access was tested.
- Direct HTTP inside the Pod confirms application response, not
  controller-to-Pod network reachability.
- The selector error was deliberately injected.
- The smoke script was run successfully after recovery; it was created
  after the HTTP 503 experiment.
- Backup restoration, high availability and controller failure recovery
  are outside this lab.

## References

- https://kubernetes.io/docs/concepts/services-networking/ingress/
- https://kubernetes.io/docs/concepts/services-networking/service/
- https://doc.traefik.io/traefik/reference/install-configuration/providers/kubernetes/kubernetes-ingress/
- https://helm.sh/docs/helm/helm_rollback/
