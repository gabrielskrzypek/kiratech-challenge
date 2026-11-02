# Installation entry point and delivery workflow

[Documentation home](README.md) · [Project overview](../README.md)

## Start here

This project requires Bash, Git, Python 3, Docker, kubectl, minikube and Helm.
The recorded environment uses Helm 4.3.1 and Kubernetes 1.36.1.

### Obtain the project and check tools

In Ubuntu WSL, start Docker Desktop first. For a new checkout:

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/gabrielskrzypek/kiratech-challenge.git
cd kiratech-challenge
```

If this directory already exists, enter it and inspect `git status` instead
of cloning over it. Run all subsequent project commands from this root.

```bash
(
set -euo pipefail
for tool in bash git python3 docker kubectl minikube helm curl tar gzip sha256sum; do
  command -v "$tool" >/dev/null || { printf 'Missing tool: %s\n' "$tool" >&2; exit 1; }
done
git --version
python3 --version
docker version
kubectl version --client
minikube version
helm version --short
)
```

Stop and install any missing tool before proceeding. `docker version` must
reach the server as well as report the client version. The command checks
availability; it does not certify compatibility with every tool version.

For Helm, follow the official [installation and binary-verification guide](https://helm.sh/docs/intro/install/)
and select the recorded version **v4.3.1** for the closest replay. The
[local setup](local-setup.md) records the other tested versions and Minikube
installation. A different environment has not been validated by this project.

### Install and verify

1. Prepare the local cluster following [local setup](local-setup.md).
2. Follow the [custom-image lab guide](../labs/security-build/README.md)
   from its prerequisites through image building and loading.
3. Create a fresh namespace and new credential files as instructed.
4. Install the Helm release and complete WordPress web installation.
5. Follow the verification, backup and upgrade instructions.
6. Follow the removal section when the test data is no longer needed.

The guide uses namespace wordpress-build and release patch-lab.
If they already exist, use distinct names consistently, as demonstrated
in the [clean-checkout test](verification/fresh-checkout-test.md).

For an installation using the corrected image directly, select
values-patched.yaml instead of values-affected.yaml at installation.
The affected configuration is retained for deliberate lab reproduction.

For an existing installation, follow the [cluster-resume checks](demo.md#2-cluster-preparation)
and [application-access steps](demo.md#5-application-access) in the demonstration guide.
Do not regenerate database credentials against initialized storage.

## Workflow actually executed

The candidate manually:
- Reviewed upstream packaging and recorded its revision.
- Adapted Dockerfiles and built the two custom images.
- Checked versions and loaded images into minikube.
- Validated and rendered the Helm chart.
- Installed, exercised and upgraded the application.
- Recorded diagnostic, persistence and cleanup evidence.
- Committed configuration and documentation to Git.

No automated CI/CD pipeline or GitOps controller was implemented.

## Proposed CI/CD workflow

A future pipeline could perform:
1. Helm lint and manifest rendering for each supported configuration.
2. Docker image build from the reviewed source.
3. Version checks and image vulnerability scanning.
4. Publication to an authorized registry, recording the resulting digest.
5. Deployment to a disposable test namespace with separately supplied Secrets.
6. Database, HTTP and application checks, followed by test-resource cleanup.
7. Review of results before promoting the image and deployment configuration.

This is a proposal, not an executed pipeline.
A scan result would require assessment; a successful build alone would
not establish that the image is secure.

The local lab uses imagePullPolicy Never and preloaded images.
Registry-based delivery would require appropriate image references,
pull policies and, where necessary, registry credentials.

Database backups, compatibility and persistent-data handling must be
considered before updates or rollback. Helm rollback does not restore data.
