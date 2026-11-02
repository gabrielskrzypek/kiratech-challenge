# Demo resource-change verification

[Verification reports](../README.md#verification-reports) · [Evidence index](../evidence/README.md)

Date: 2026-11-02
Context: kiratech
Namespace: wordpress-build
Helm release: patch-lab

## Scope

Verified the small configuration change used in step 7 of the
[demonstration guide](../demo.md#7-small-reversible-configuration-change).
The existing release and persistent data were retained.
This was a technical check, not a rehearsal of the complete presentation.

The change concerned WordPress's CPU request, which is used for scheduling.
It did not change the CPU limit or measure application performance.

## Procedure

- Checked the deployed release, completed rollout, CPU request 100m and
  image kiratech-wordpress:7.1.3-php8.3.36-lab before changing configuration.
- Captured the active Helm values, upload hashes, PVC identities and bindings.
- Used the current chart and captured values to upgrade the CPU request to 150m.
- Waited for availability and checked the request value.
- Upgraded again to restore the CPU request to 100m and checked the value.
- Confirmed the image reference was unchanged.
- Compared uploaded-file hashes and PVC identities/bindings with the baseline.
- Requested the application inside the WordPress container using the expected
  Host header; checked HTTP 200 and the title "Custom image patch test".

## Observed results

| Check | Result |
| --- | --- |
| CPU request change | Helm revision 3 deployed; 150m check passed |
| CPU request restoration | Helm revision 4 deployed; 100m check passed |
| Image reference | Corrected custom PHP 8.3.36 tag retained |
| Upload hashes | No differences |
| PVC identities and volume bindings | No differences; both claims Bound |
| Application response | Direct HTTP 200 and expected article title |
| Final workloads | Both Deployments available; WordPress Pod Ready with zero restarts |

Result: PASS for the resource change, restoration and checks above.

## Evidence and boundaries

See the [session capture and reading guide](../evidence/demo-change/README.md).
The local detailed captures are under .local/demo-validation-20261102-172358.
Captured Helm values and page contents are not published here.

Restoration refers to the CPU request. The current chart was used and Helm
advanced to revision 4; the historical chart version was not rolled back.
No complete manifest-difference comparison was performed in this test.

The HTTP request bypassed Service and Ingress routing. Browser rendering,
external access, a performance/load test and the full presentation sequence
were not repeated as part of this check.
