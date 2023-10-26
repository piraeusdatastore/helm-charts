# snapshot-controller

Deploys the [snapshot-controller](https://github.com/kubernetes-csi/external-snapshotter) and the
[snapshot-validation-webhook](https://github.com/kubernetes-csi/external-snapshotter/#validating-webhook) in a cluster.
The controller is required for CSI snapshotting to work and is not specific to any CSI driver. The webhook is configured
to validate every `VolumeSnapshot` and `VolumeSnapshotContent` resource by sending it to the validation webhook.

While many Kubernetes distributions already package this controller, some do not. If your cluster does ***NOT***
have the following CRDs, you likely also do not have a snapshot controller deployed:

```
kubectl get crd volumesnapshotclasses.snapshot.storage.k8s.io
kubectl get crd volumesnapshots.snapshot.storage.k8s.io
kubectl get crd volumesnapshotcontents.snapshot.storage.k8s.io
```

## Usage

The *snapshot-controller* should be deployed together with the *snapshot-validation-webhook* which can be done by this
simple Helm commands. See [below](#configuration) for available configuration options.

```
helm repo add piraeus-charts https://piraeus.io/helm-charts/
helm install snapshot-controller piraeus-charts/snapshot-controller
```

## Upgrades

Upgrades can be done using the normal Helm upgrade mechanism

```
helm repo update
helm upgrade snapshot-controller piraeus-charts/snapshot-controller
```

To enjoy all the latest features of the snapshot controller, you may want to upgrade your CRDs as well:

```
kubectl replace -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v5.0.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
kubectl replace -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v5.0.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
kubectl replace -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v5.0.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
```

## Upgrade from older CRDs

In an effort to tighten validation, the CSI project started enforcing stricter requirements on `VolumeSnapshot` and
`VolumeSnapshotContent` resources when switching from `v1beta1` to `v1` CRDs. This validation webhook is part of 
enforcing these requirements. When upgrading you [have to ensure non of your resources violate the requirements for `v1`].

The upgrade procedure can be summarized by the following steps:

1. Remove the old snapshot controller, if any (since you are upgrading, you probably already have one deployed manually).
2. Install the snapshot controller and the validation webhook using one of the [`3.x.x` releases]:

   ```
   helm install piraeus-charts/snapshot-controller --set controller.image.tag=v3.0.3 --set webhook.image.tag=v3.0.3
   ```
3. Ensure that none of the resources are labelled as invalid:

   ```
   kubectl get volumesnapshots --selector=snapshot.storage.kubernetes.io/invalid-snapshot-resource="" --all-namespaces
   kubectl get volumesnapshotcontents --selector=snapshot.storage.kubernetes.io/invalid-snapshot-resource="" --all-namespaces
   ```

   If the above commands output any resource, they have to be removed

4. Upgrade the CRDs

   ```
   kubectl replace -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v5.0.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
   kubectl replace -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v5.0.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
   kubectl replace -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v5.0.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
   ```

5. Upgrade to the latest version:

   ```
   helm upgrade piraeus-charts/snapshot-controller --set controller.image.tag=v5.0.0 --set webhook.image.tag=v5.0.0
   ```

## Configuration

### Snapshot controller
The following options are available:

| Option                      | Usage                                                                                                                  | Default                                                                                            |
|-----------------------------|------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| `enabled`                   | Toggle to disable the deployment of the snapshot controller.                                                           | `true`                                                                                             |
| `args`                      | Arguments to pass to the snapshot controller. Note: Keys will be converted to kebab-case, i.e. `oneArg` -> `--one-arg` | `...`                                                                                              |
| `replicaCount`              | Number of replicas to deploy.                                                                                          | `1`                                                                                                |
| `image.repository`          | Repository to pull the image from.                                                                                     | `registry.k8s.io/sig-storage/snapshot-controller`                                                  |
| `image.pullPolicy`          | Pull policy to use. Possible values: `IfNotPresent`, `Always`, `Never`                                                 | `IfNotPresent`                                                                                     |
| `image.tag`                 | Override the tag to pull. If not given, defaults to charts `AppVersion`.                                               | `""`                                                                                               |
| `imagePullSecrets`          | Image pull secrets to add to the deployment.                                                                           | `[]`                                                                                               |
| `podAnnotations`            | Annotations to add to every pod in the deployment.                                                                     | `{}`                                                                                               |
| `podLabels`                 | Labels to add to every pod in the deployment.                                                                          | `{}`                                                                                               |
| `podSecurityContext`        | Security context to set on the webhook pod.                                                                            | `{}`                                                                                               |
| `priorityClassName`         | Priority Class to set on the deployment pods.                                                                          | `""`                                                                                               |
| `securityContext`           | Configure container security context. Defaults to dropping all capabilties and running as user 1000.                   | `{capabilities: {drop: [ALL]}, readOnlyRootFilesystem: true, runAsNonRoot: true, runAsUser: 1000}` |
| `resources`                 | Resources to request and limit on the pod.                                                                             | `{}`                                                                                               |
| `nodeSelector`              | Node selector to add to each webhook pod.                                                                              | `{}`                                                                                               |
| `tolerations`               | Tolerations to add to each webhook pod.                                                                                | `[]`                                                                                               |
| `topologySpreadConstraints` | Topology spread constraints to set on each pod.                                                                        | `[]`                                                                                               |
| `affinity`                  | Affinity to set on each webhook pod.                                                                                   | `{}`                                                                                               |
| `pdb`                       | PodDisruptionBudget to set on the webhook pod.                                                                         | `{}`                                                                                               |
| `rbac.create`               | Create the necessary roles and bindings for the snapshot controller.                                                   | `true`                                                                                             |
| `serviceAccount.create`     | Create the service account resource                                                                                    | `true`                                                                                             |
| `serviceAccount.name`       | Sets the name of the service account. If left empty, will use the release name as default                              | `""`                                                                                               |


### Snapshot Validation Webhook
Webhooks in Kubernetes are required to run on HTTPS. To that end, this charts needs to be configured with one of the
following options:

* An auto-generated certificate, valid for 10 years. This is the default. If you want to renew the certificate,
  set `webhook.tls.renew` to `true` and run an upgrade.

* A [cert-manager.io](https://cert-manager.io) issuer able to create a certificate for the webhook service.

  To use this method, create an override file like:
  ```yaml
  webhook:
    tls:
      certManagerIssuerRef:
        name: internal-issuer
        kind: ClusterIssuer
  ```

  To apply the override, use `--values <override-file>`.

* A pre-existing  [`kubernetes.io/tls`] secret and the certificate of the CA used to sign said tls secret.

  To use this method, set `--set webhook.tls.certificateSecret=<secretname>`.
  The secret must be in the same namespace as the deployment and be valid for `<release-name>.<namespace>.svc`.

There are additional options that allow customization outside of HTTPS concerns. This is the full list of options
available.

| Option                               | Usage                                                                                                                  | Default                                                                                            |
|--------------------------------------|------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| `enabled`                            | Toggle to disable the deployment of the snapshot validation webhook.                                                   | `true`                                                                                             |
| `args`                               | Arguments to pass to the snapshot controller. Note: Keys will be converted to kebab-case, i.e. `oneArg` -> `--one-arg` | `...`                                                                                              |
| `replicaCount`                       | Number of replicas to deploy.                                                                                          | `1`                                                                                                |
| `image.repository`                   | Repository to pull the image from.                                                                                     | `registry.k8s.io/sig-storage/snapshot-validation-webhook`                                          |
| `image.pullPolicy`                   | Pull policy to use. Possible values: `IfNotPresent`, `Always`, `Never`                                                 | `IfNotPresent`                                                                                     |
| `image.tag`                          | Override the tag to pull. If not given, defaults to charts `AppVersion`.                                               | `""`                                                                                               |
| `webhook.timeoutSeconds`             | Timeout to use when contacting webhook server.                                                                         | `2`                                                                                                |
| `webhook.failurePolicy`              | Policy to apply when webhook is unavailable. Possible values: `Fail`, `Ignore`.                                        | `Fail`                                                                                             |
| `tls.certificateSecret`              | Name of the static tls secret to use for serving the HTTPS endpoint.                                                   | `""`                                                                                               |
| `tls.autogenerate`                   | Automatically generate the TLS secret for serving the HTTPS endpoint.                                                  | `true`                                                                                             |
| `tls.renew`                          | Force renewal of certificate when auto-generating.                                                                     | `false`                                                                                            |
| `tls.certManagerIssuerRef`           | Issuer to use for provisioning the TLS certificate. If this is used, `tls.certificateSecret` can be left empty.        | `{}`                                                                                               |
| `imagePullSecrets`                   | Image pull secrets to add to the deployment.                                                                           | `[]`                                                                                               |
| `podAnnotations`                     | Annotations to add to every pod in the deployment.                                                                     | `{}`                                                                                               |
| `podLabels`                          | Labels to add to every pod in the deployment.                                                                          | `{}`                                                                                               |
| `networkPolicy.enabled`              | Should a network policy be created.                                                                                    | `false`                                                                                            |
| `networkPolicy.ingress`              | Additional ingress rules to be added to the network policy.                                                            | `{}`                                                                                               |
| `podDisruptionBudget.enabled`        | Should a pod disruption budget be created.                                                                             | `false`                                                                                            |
| `podDisruptionBudget.maxUnavailable` | The maximum number of pods that are allowed to be unavailable.                                                         | `""`                                                                                               |
| `podDisruptionBudget.minAvailable`   | The minimum number of pods that are required to be available.                                                          | `""`                                                                                               |
| `priorityClassName`                  | The name of the priority class to assign to the deployment.                                                            | `""`                                                                                               |
| `topologySpreadConstraints`          | A list of topology constraints to assign to the deployment.                                                            | `[]`                                                                                               |
| `podSecurityContext`                 | Security context to set on the webhook pod.                                                                            | `{}`                                                                                               |
| `securityContext`                    | Configure container security context. Defaults to dropping all capabilties and running as user 1000.                   | `{capabilities: {drop: [ALL]}, readOnlyRootFilesystem: true, runAsNonRoot: true, runAsUser: 1000}` |
| `resources`                          | Resources to request and limit on the pod.                                                                             | `{}`                                                                                               |
| `nodeSelector`                       | Node selector to add to each webhook pod.                                                                              | `{}`                                                                                               |
| `tolerations`                        | Tolerations to add to each webhook pod.                                                                                | `[]`                                                                                               |
| `affinity`                           | Affinity to set on each webhook pod.                                                                                   | `{}`                                                                                               |
| `serviceAccount.create`              | Create the service account resource                                                                                    | `true`                                                                                             |
| `serviceAccount.name`                | Sets the name of the service account. If left empty, will use the release name as default                              | `""`                                                                                               |


[`3.x.x` releases]: https://github.com/kubernetes-csi/external-snapshotter/releases
[have to ensure non of your resources violate the requirements for `v1`]: https://github.com/kubernetes-csi/external-snapshotter#validating-webhook
