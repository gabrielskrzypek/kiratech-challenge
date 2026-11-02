# Ingress routing incident — before, failed and recovered

[All evidence](../README.md)

Report: [Service-selector incident](../../incidents/ingress-service-selector.md)

Recorded 2026-10-30 in wordpress-ingress, through Traefik.

Read the following stages in order. Filenames retain their original capture names.

| Stage | Files | What to inspect |
| --- | --- | --- |
| 1. Healthy baseline | [http-before.txt](http-before.txt), [pods-before.txt](pods-before.txt), [endpoints-before.yaml](endpoints-before.yaml) | Working HTTP route, Pod labels/state and available endpoints. |
| 2. Routing failure | [http-failed.txt](http-failed.txt), [pods-failed.txt](pods-failed.txt), [selector-failed.txt](selector-failed.txt), [endpoints-failed.yaml](endpoints-failed.yaml) | 503 despite Ready Pods; incorrect selector and empty endpoints. |
| 3. Isolate the fault | [direct-pod-http.txt](direct-pod-http.txt), [traefik-failed.log](traefik-failed.log) | Local application HTTP 200 and controller access-log sample containing 503 responses. |
| 4. Recovery | [endpoints-recovered.yaml](endpoints-recovered.yaml), [http-recovered.txt](http-recovered.txt), [content-recovered.txt](content-recovered.txt), [pods-recovered.txt](pods-recovered.txt) | Ready backend and HTTP/content restored; compare Pod identities/restarts with stage 1. |
| 5. Subsequent smoke check | [smoke-recovered.txt](smoke-recovered.txt) | Successful smoke-script execution after recovery. |

## Interpretation and limits

Direct HTTP inside the Pod does not test controller-to-Pod connectivity. The smoke script was created after the fault experiment and was not run during the 503. A Ready Pod alone did not establish a working Ingress path.
