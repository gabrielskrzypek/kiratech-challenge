# Krateo integration proposal

## Starting from the Helm lab

In this project, installing WordPress means preparing a namespace and Secret,
loading the image into Minikube, selecting values and running Helm. The chart
already groups WordPress, MySQL, Services and persistent storage into one
installation.

I would use [this chart](../charts/kiratech-wordpress/) as the starting point
for a reusable WordPress service in Krateo. Someone requesting another instance
could supply a few parameters instead of repeating the deployment commands.
This is a conceptual proposal; Krateo was not installed or tested in this project.

## What the request would contain

For a first version, I would expose the settings already useful in the lab:

| Parameter | Use in this project |
| --- | --- |
| Instance name | Identify the installation and its resources, as the Helm release name does now |
| Namespace | Choose where to install the instance |
| WordPress image | Select the build through `wordpress.image` |
| Existing Secret | Supply the credential reference through `existingSecret` |
| Storage sizes | Set `wordpress.storage` and `mysql.storage` |
| CPU and memory | Adjust the existing WordPress and MySQL resource values |
| Optional hostname | Configure `ingress.enabled`, `ingress.className` and `ingress.host` when a controller is available |

Instance name and namespace need an explicit mapping in the integration;
they are not ordinary values in the current chart. Passwords would stay out
of the request: the referenced Secret must be provided in the target namespace.

## What would need to change

The chart is not ready for Krateo registration yet. The next steps would be:

1. Add `values.schema.json` to describe and validate its inputs, then publish
   a versioned chart.
2. Publish the custom image to a registry reachable by the cluster. The lab's
   `Never` pull policy depends on manual image loading and would need to change.
3. Register the chart using a `CompositionDefinition`: the Krateo resource
   that defines the reusable service. A `Composition` would then represent one
   requested WordPress instance. Krateo's controller would manage its Helm release.
4. Define how namespaces, credentials and permissions are prepared, then test
   installation, updates and removal with disposable data.

A portal form could make the request easier to fill in, but it would also
need configuration. Image building would remain a separate step.

## Benefit and limits for this project

The practical benefit would be creating several instances from the same chart
with consistent defaults, while allowing a different image or storage size.
For one local installation, Helm already does the job; Krateo becomes more
useful when the same service is requested repeatedly.

It would not remove the operational problems demonstrated here. An incorrect
Service selector can still leave the application unreachable, and changing
a Secret still does not rotate an initialized MySQL account's password.
Deletion also needs an explicit data policy: uninstalling this chart removes
its PVCs and can delete the stored content. These points would need checking
before offering the service to others.

## Official references

Reviewed on 2026-11-02:

- [Architecture and concepts](https://docs.krateo.io/key-concepts/kco/architecture/)
- [Deploying a CompositionDefinition](https://docs.krateo.io/how-to-guides/kco-operations/deploy-composition-definition/)
