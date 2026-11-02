# Ingress HTTP 503 with a Ready WordPress Pod — incorrect Service selector

[Incident catalogue](README.md) · [L2 runbook](../runbook.md)

Execution date: 2026-10-30. Report consolidated: 2026-11-02.
Context: kiratech. Application: ingress-lab in wordpress-ingress.
Controller: traefik in ingress-system.
Runbook: [Case 5](../runbook.md#case-5--ready-application-ingress-http-503).
Reproduction and commands: [Ingress lab](../../labs/ingress/README.md#reproduced-incident-healthy-pod-http-503).

## Symptoms and impact

A deliberately injected selector error made the application return HTTP 503
through wordpress.lab.test:8086 while its WordPress Pod remained Running and
Ready. Access used a local port-forward to Traefik, so requests exercised
the Ingress rule and controller rather than forwarding directly to WordPress.
The fault affected this isolated lab's HTTP access.

## Investigation and root cause

| Observation | Interpretation | Evidence |
| --- | --- | --- |
| HTTP 200 before the change, 503 afterwards | The configured access path regressed | [Before](../evidence/ingress-selector/http-before.txt), [failed](../evidence/ingress-selector/http-failed.txt) |
| WordPress remained Ready with tier=frontend | Pod readiness alone did not validate routing | [Pod labels/state](../evidence/ingress-selector/pods-failed.txt) |
| Service selector used tier=frontend-typo | The selector matched no application Pods | [Failed selector](../evidence/ingress-selector/selector-failed.txt) |
| EndpointSlice had endpoints: null | No backend addresses were available | [Failed endpoints](../evidence/ingress-selector/endpoints-failed.yaml) |
| HTTP inside the WordPress Pod returned 200 | Application HTTP still worked locally | [Direct Pod check](../evidence/ingress-selector/direct-pod-http.txt) |

The selector mismatch removed the eligible backends. The lab configured
Traefik allowEmptyServices=true, retaining the route and returning 503 when
no endpoints were available. A controller log sample was also
[captured](../evidence/ingress-selector/traefik-failed.log).

Direct access inside the Pod established local application response, not
controller-to-Pod network reachability. The selector, endpoint and recovery
observations together support the diagnosed cause.

## Correction performed

Restored the live Service selector from frontend-typo to frontend, the value
already declared in the Helm chart. The chart itself had not been changed.
Allowed endpoint discovery to converge before checking the application again.
No Pod restart or database/credential repair was needed.

## Verification and evidence

- [Endpoint discovery](../evidence/ingress-selector/endpoints-recovered.yaml)
  again contained a Ready application address and port 80.
- [Ingress HTTP](../evidence/ingress-selector/http-recovered.txt) returned 200.
- [Content check](../evidence/ingress-selector/content-recovered.txt) found the
  expected article title.
- [Before](../evidence/ingress-selector/pods-before.txt) and
  [after](../evidence/ingress-selector/pods-recovered.txt) resource listings
  showed unchanged Pod identities and restart counts during the experiment.
- The smoke script was created after the fault experiment and
  [passed on the recovered application](../evidence/ingress-selector/smoke-recovered.txt).

## Prevention, recovery and escalation

Compare Service selectors with workload labels and inspect backend endpoints
when HTTP fails despite Ready Pods. Check the external application path and
expected content, not just readiness. These checks complement the reusable
[smoke script](../../labs/ingress/smoke-test.sh).

If restoring the selector does not recover access, collect Ingress backend
names/ports, endpoint readiness and controller logs; investigate controller
connectivity before changing credentials or restarting the application.
Escalate a healthy backend that remains unreachable with the collected evidence.

## Limits and related setup issues

No TLS, public exposure or controller failure recovery was tested. The smoke
script was not run during the injected 503. Probe timeout adjustment and
pending-install recovery were separate setup issues, recorded in the
[lab guide](../../labs/ingress/README.md#other-issues-encountered-during-setup).
