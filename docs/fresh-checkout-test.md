# Installation and removal from a clean checkout

Date: 2026-10-29
Source commit: 387eb17
Context: kiratech
Namespace: wordpress-validation
Helm release: validation

## Scope

Validated installation and removal from a clean local Git clone.
The existing Kubernetes cluster and previously built, loaded images
were reused. This was not a full rebuild or a new-machine setup.

## Preparation

- Cloned the project into ~/projects/kiratech-validation.
- Confirmed a clean working tree and the expected source commit.
- Confirmed that the original .local directory was not copied.
- Created a new namespace and newly generated database credentials.
- Generated credential files without trailing LF.
- Created the credential Secret separately from the Helm chart.

The lab guide's namespace and release names were changed to avoid
conflicts with existing installations. Chart templates were not changed.

## Installation and verification

- Used charts/kiratech-wordpress with
  labs/security-build/values-patched.yaml.
- Helm lint passed.
- Helm install completed: revision 1, status deployed.
- Both Deployments became available.
- Both Pods were Ready with zero restarts at verification.
- Both newly provisioned PVCs were Bound.
- The MySQL application-account query completed successfully.
- Recorded the running WordPress and PHP versions.
- Accessed WordPress through localhost:8085.
- Completed the web installation and logged into the Dashboard.
- Published "Fresh checkout verification" with text and an image.
- Manually confirmed that the public article displayed both.
- Confirmed PHP 8.3.36 in WordPress Site Health.
- The HTTP check returned 200.

## Removal

- Copied the test evidence into the main project.
- Recorded both persistent volume names before removal.
- Helm uninstall completed successfully.
- No Deployments, Pods, Services or PVCs remained in the test namespace.
- Wait-for-deletion checks for both recorded volumes completed
  without errors and produced no terminal output.
- Deleted the separately created namespace, including its Secret.

Result: PASS for the installation, functional checks and removal
described above.

## Evidence

See evidence/fresh-checkout/ for the source commit, Helm output,
resource listings, database check, versions, initialization logs,
manual browser observations, HTTP result and removal output.

## Limitations

- The clone source was the local repository; remote access was not tested.
- Existing container images were reused rather than rebuilt.
- This replay installed the corrected image directly.
- Image building, upgrade and persistence were tested separately;
  they were not repeated as part of this checkout test.
- Backup restoration and installation on a new cluster were not tested.
- A full replay of every documented lab remains outside this result.
