# Work log

## 2026-10-23 — Local environment checks

### Verified environment
- Host: Windows, Intel Core i7-9750H, 16 GB RAM.
- WSL version: 2.7.12.0.
- Linux distribution: Ubuntu 26.04 LTS on WSL2.
- Docker Desktop: 4.89.0.
- Docker Engine: 29.7.2, linux/amd64.
- Git: 2.53.0.
- kubectl client: v1.36.1.
- Bundled Kustomize: v5.8.1.
- minikube: command not available.

### Troubleshooting performed
1. Docker was initially unreachable from PowerShell.
   After starting Docker Desktop, docker version returned Client and Server.
2. Docker was initially unavailable from Ubuntu.
   Docker Desktop WSL integration was enabled.
3. Ubuntu then reported permission denied for /var/run/docker.sock.
   The socket belonged to root:docker.
   The user was registered in the docker group, but the active shell
   did not include that group.
   Running newgrp docker activated the group in the shell.
   docker version then returned Client and Server successfully.

### Execution test
- Command: docker run --rm hello-world
- Observed result: Hello from Docker!
- Container execution from Ubuntu: verified.

### Next steps
- Prepare the local Kubernetes cluster.
- Record installation commands and selected versions.

## 2026-10-26 — First application deployment
- Deployed WordPress and MySQL using k8s/stack.yaml.
- WordPress image contains PHP 8.3.36; image digest is pinned.
- Credentials are stored locally in .local/ and supplied through a Secret.
- WordPress initially returned HTTP 500 and failed its startup probe.
- PHP connection test returned MySQL error 1045.
- Administrator query confirmed that the wordpress database user was absent.
- Created the database if missing, the wordpress user and database permissions.
- WordPress rollout then completed successfully.
- Completed web installation and logged into the dashboard.
- Published "Kiratech persistence test" with text and an uploaded image.
- Verified that both are visible on the public post.
- Pending: investigate why initial MySQL setup did not create the user.
- Pending: verify persistence after Pod replacement and clean installation.
