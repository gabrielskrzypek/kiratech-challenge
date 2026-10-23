# Local Kubernetes setup

## Environment

- Windows host with 16 GB RAM and Intel Core i7-9750H.
- Ubuntu 26.04 LTS on WSL2.
- Docker Desktop 4.89.0 with Ubuntu WSL integration enabled.
- Docker Engine 29.7.2.
- kubectl v1.36.1.
- minikube v1.39.0.

Docker Desktop must be running, and Docker must be accessible
from the Ubuntu terminal before starting minikube.

Verify Docker access:

```bash
docker version
docker run --rm hello-world
```

For initial environment troubleshooting, see `work-log.md`.

## Install minikube

Download the pinned Linux amd64 release:

```bash
curl --fail --location --output /tmp/minikube-v1.39.0-linux-amd64 https://github.com/kubernetes/minikube/releases/download/v1.39.0/minikube-linux-amd64
```

Install and verify:

```bash
sudo install -m 0755 /tmp/minikube-v1.39.0-linux-amd64 /usr/local/bin/minikube
minikube version
```

## Create the cluster

```bash
minikube start --profile kiratech --driver=docker --kubernetes-version=v1.36.1 --cpus=2 --memory=4096
```

Configuration:
- Profile: kiratech.
- Driver: Docker.
- Kubernetes: v1.36.1.
- Nodes: one control-plane node, also used for application workloads.
- CPUs: 2.
- Memory: 4096 MB.
- Container runtime inside the node: containerd.

## Verify the cluster

```bash
minikube status --profile kiratech
kubectl --context=kiratech get nodes
kubectl --context=kiratech get pods --all-namespaces
kubectl --context=kiratech get storageclass
```

Observed on 2026-10-23:
- Host, kubelet and API server: Running.
- kubeconfig: Configured.
- Node kiratech: Ready, Kubernetes v1.36.1.
- Eight system Pods: Running, 1/1 Ready, zero restarts.
- Default StorageClass: standard.
- Storage provisioner: k8s.io/minikube-hostpath.
- Reclaim policy: Delete.
- Volume binding mode: Immediate.
- Volume expansion: disabled.

These observations verify the initial cluster state.
Application deployment and data persistence have not yet been tested.

## Storage limitations

Storage is local to the minikube node and is intended for this lab.
Deleting a PersistentVolumeClaim can delete its associated data
because the StorageClass uses the Delete reclaim policy.
Deleting the cluster must not be treated as a data-preserving operation.
