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
