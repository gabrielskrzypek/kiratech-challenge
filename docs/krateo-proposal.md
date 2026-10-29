# Krateo integration proposal

## Scope

Conceptual proposal for reusing this project's Helm chart through Krateo.
Krateo has not been installed or tested in this project.

## Reusable service

Offer a WordPress lab consisting of:
- WordPress with Apache and PHP.
- MySQL with an application database and user.
- Internal Services, configuration and references to an existing Secret.
- Separate persistent storage for MySQL and WordPress content.
- Resource requests, limits and health probes.

The implementation starting point is charts/kiratech-wordpress.
The custom image build remains a separate preparation step.

## Proposed inputs

| Input | Purpose | Relationship to the current implementation |
| --- | --- | --- |
| Instance name | Identify the installation | Resource names currently use the Helm release name |
| Namespace | Select the installation namespace | Templates already use the release namespace |
| Environment | Select an approved lab or development profile | Proposed profile selection; not implemented |
| Source repository and revision | Identify the reviewed source | Build provenance; not a current chart value |
| Chart source and version | Select the deployment package | Chart must be packaged and published |
| WordPress image | Select an approved application build | Existing wordpress.image value |
| Existing Secret name | Reference database credentials | Existing existingSecret value |
| Storage sizes | Request persistent capacity | Existing storage values |
| Resource requests and limits | Control workload allocation | Existing resource values |

Passwords would not be entered into a Git-tracked values file.
The referenced Secret must exist in the target namespace.

Instance name and namespace require an explicit mapping in the Krateo
integration. They must not be assumed to be ordinary chart values.

## High-level workflow

1. Review and build the application image from a recorded source revision.
2. Publish the approved image to a registry accessible by the cluster.
3. Add values.schema.json to define and validate the chart's accepted inputs.
4. Package and publish a versioned Helm chart.
5. Register the chart through a Krateo CompositionDefinition.
6. Request an installation by creating a Composition with approved inputs.
7. Let Krateo's Composition Dynamic Controller manage the Helm release.
8. Verify Kubernetes resources, application access and persistent content.

A portal could expose these inputs through a form, but configuring that
interface would be additional integration work.

## Illustrative request

This is a design example, not an executable Krateo manifest:

```yaml
instanceName: wordpress-demo
namespace: wordpress-demo
environment: lab
source:
  repository: "<project repository URL>"
  revision: "<reviewed Git commit>"
chart:
  name: kiratech-wordpress
  version: "0.1.0"
application:
  image: "<approved registry image pinned by digest>"
  existingSecret: mysql-credentials
  wordpressStorage: 2Gi
  mysqlStorage: 2Gi
```

## Expected benefits

- Reuse the deployment already verified in this project.
- Offer consistent defaults and validated configuration.
- Reduce manual YAML editing for each installation.
- Associate installations with reviewed chart and image versions.

These are expected benefits, not results measured in this project.

## Limitations and safeguards

- The current chart has no values.schema.json or tested Krateo registration.
- Local lab images with imagePullPolicy Never require prior node loading;
  a shared platform would normally use a registry and an appropriate policy.
- Namespace provisioning, permissions and Secret delivery need explicit design.
- Image building, scanning and approval are separate pipeline responsibilities.
- Recreate deployments can interrupt service during updates.
- Local minikube storage does not provide high availability or backups.
- Deletion must account for PVCs and their Delete reclaim policy.
- Platform automation does not replace application checks or L2 diagnosis.

## Official references

Documentation reviewed on 2026-10-29:
- https://docs.krateo.io/key-concepts/kco/architecture/
- https://docs.krateo.io/how-to-guides/kco-operations/deploy-composition-definition/
