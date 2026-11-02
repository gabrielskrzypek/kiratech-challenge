# Demo resource-change verification

Date: 2026-11-02 · Context: kiratech · Namespace: wordpress-build · Release: patch-lab.

Read the [test report](../../verification/demo-change-test.md), then [session.txt](session.txt).
The session is the final command block and its terminal output, extracted
without editing from the submitted transcript.

Follow these stages in the capture:

1. Baseline checks: deployed Helm release, Ready WordPress, CPU request 100m
   and the corrected custom image.
2. Helm revision 3: CPU request changed to 150m and checked.
3. Helm revision 4: CPU request restored to 100m and checked.
4. Upload-hash and PVC/volume-identity comparisons: both returned no differences.
5. Direct HTTP 200 with the expected article title, final Ready resources and PASS.

Individual snapshots, rendered page and captured Helm values remain in the
local .local/demo-validation-20261102-172358 directory. They are not included
in this evidence folder. The capture includes the commands and their aggregate
success result; it does not expose credential values or Helm values contents.

Return to the [evidence index](../README.md).
