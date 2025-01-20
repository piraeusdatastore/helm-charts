# Piraeus High Availability Controller

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/piraeusdatastore/piraeus-ha-controller)](https://github.com/piraeusdatastore/piraeus-ha-controller/releases)
![tests](https://github.com/piraeusdatastore/piraeus-ha-controller/workflows/tests/badge.svg)

The Piraeus High Availability Controller will speed up the fail-over process for stateful workloads using [Piraeus] for
storage.

[Piraeus]: https://piraeus.io

## Get started

The Piraeus High Availability Controller is automatically deployed as part of [Piraeus Datastore](https://piraeus.io/docs/stable/).

### Alternative Deployment Methods

The Piraeus High Availability Controller can be deployed through a helm chart.

```
$ helm repo add piraeus-charts https://piraeus.io/helm-charts/
$ helm install --create-namespace --namespace piraeus-ha-controller piraeus-ha-controller piraeus-charts/piraeus-ha-controller
```

The high availability controller will automatically watch all pods and volumes and start the fail-over process
should it detect any issues.

When not using Piraeus Datastore through the Piraeus Operator, we recommend the following settings for your StorageClass:

```
parameters:
  property.linstor.csi.linbit.com/DrbdOptions/auto-quorum: suspend-io
  property.linstor.csi.linbit.com/DrbdOptions/Resource/on-no-data-accessible: suspend-io
  property.linstor.csi.linbit.com/DrbdOptions/Resource/on-suspended-primary-outdated: force-secondary
  property.linstor.csi.linbit.com/DrbdOptions/Net/rr-conflict: retry-connect
```

### Options

The Piraeus High Availability Controller itself can be configured using the following flags:

```
--drbd-status-interval duration    Time between DRBD status updates (default 5s)
--fail-over-timeout duration       Timeout before starting fail-over process (default 5s)
--grace-period-seconds int         Default grace period for deleting k8s objects, in seconds (default 10)
--node-name string                 The name of node this is running on. Defaults to the NODE_NAME environment variable.
--operations-timeout duration      Default timeout for operations (default 1m0s)
--reconcile-interval duration      Maximum interval between reconciliation attempts (default 5s)
--request-timeout string           The length of time to wait before giving up on a single server request. Non-zero values should contain a corresponding time unit (e.g. 1s, 2m, 3h). A value of zero means don't timeout requests. (default "0")
--resync-interval duration         How often the internal object cache should be resynchronized (default 5m0s)
--v int32                          Set log level (default 0)
--disable-node-taints boolean      When set to true; node taints will not be applied (default false)
```

To configure the Piraeus High Availability Controller with Piraeus Datastore, edit the
[`LinstorCluster.spec.highAvailabilityController`](https://piraeus.io/docs/stable/reference/linstorcluster/#spechighavailabilitycontroller):

```yaml
apiVersion: piraeus.io/v1
kind: LinstorCluster
metadata:
  name: linstorcluster
spec:
  highAvailabilityController:
    podTemplate:
      spec:
        containers:
        - name: ha-controller
          args:
          - /agent
          - --v=4
          - --fail-over-timeout=30s
```

If deployed using the helm chart set them through the matching `options` value.

## What resources are monitored?

The Piraeus High Availability Controller will monitor and manage any Pod that is attached to at least one DRBD resource.

When using volumes without quorum capabilities (less than 2 replicas + 1 tie-breaker or quorum manually disabled),
the fast fail-over capabilities of the HA Controller will not be available.

Other capabilities of the HA Controller will work with any DRBD resource and Pod.

If you want to mark a Pod as exempt from management by the HA Controller, add the following annotation to the Pod:

```
kubectl annotate pod <podname> drbd.linbit.com/ignore-fail-over=""
```

## What & Why?

Let's say you are using Piraeus to provision your Kubernetes PersistentVolumes. You replicate your volumes across
multiple nodes in your cluster, so that even if a node crashes, a simple re-creation of the Pod will still have access
to the same data.

### The Problem

We have deployed our application as a StatefulSet to ensure only one Pod can access the PersistentVolume at a time,
even in case of node failures.

```
$ kubectl get pod -o wide
NAME                                        READY   STATUS              RESTARTS   AGE     IP                NODE                    NOMINATED NODE   READINESS GATES
my-stateful-app-with-piraeus                1/1     Running             0          5m      172.31.0.1        node01.ha.cluster       <none>           <none>
```

Now we simulate our node crashing and wait for Kubernetes to recognize the node as unavailable

```
$ kubectl get nodes
NAME                    STATUS     ROLES     AGE    VERSION
master01.ha.cluster     Ready      master    12d    v1.19.4
master02.ha.cluster     Ready      master    12d    v1.19.4
master03.ha.cluster     Ready      master    12d    v1.19.4
node01.ha.cluster       Ready      compute   12d    v1.19.4
node02.ha.cluster       Ready      compute   12d    v1.19.4
node03.ha.cluster       NotReady   compute   12d    v1.19.4
```

We check our pod again:

```
$ kubectl get pod -o wide
NAME                                        READY   STATUS              RESTARTS   AGE     IP                NODE                    NOMINATED NODE   READINESS GATES
my-stateful-app-with-piraeus-0              1/1     Running             0          10m     172.31.0.1        node01.ha.cluster       <none>           <none>
```

Nothing happened! That's because Kubernetes, by default, adds a 5-minute grace period before pods are evicted from
unreachable nodes. So we wait.

```
$ kubectl get pod -o wide
NAME                                        READY   STATUS              RESTARTS   AGE     IP                NODE                    NOMINATED NODE   READINESS GATES
my-stateful-app-with-piraeus-0              1/1     Terminating         0          15m     172.31.0.1        node01.ha.cluster       <none>           <none>
```

Now our Pod is `Terminating`, but still nothing happens. You force delete the pod

```
$ kubectl delete pod my-stateful-app-with-piraeus-0 --force
warning: Immediate deletion does not wait for confirmation that the running resource has been terminated. The resource may continue to run on the cluster indefinitely.
pod "my-stateful-app-with-piraeus-0" force deleted
$ kubectl get pod -o wide
NAME                                        READY   STATUS              RESTARTS   AGE     IP                NODE                    NOMINATED NODE   READINESS GATES
my-stateful-app-with-piraeus-0              0/1     ContainerCreating   0          5s      172.31.0.1        node02.ha.cluster       <none>           <none>
```

Still, nothing happens, the new Pod is assigned to a different node, but it cannot start. Why? Because Kubernetes thinks the old volume might still be attached

```
$ kubectl describe pod my-stateful-app-with-piraeus-0
...
Events:                                                                                                                                                                                       
  Type     Reason                  Age               From                            Message                                                                                                  
  ----     ------                  ----              ----                            -------                                                                                                  
  Normal   Scheduled               <unknown>         default-scheduler               Successfully assigned default/my-stateful-app-with-piraeus-0 to node02.ha.cluster
  Warning  FailedAttachVolume      28s               attachdetach-controller         Multi-Attach error for volume "pvc-9d991a74-0713-448f-ac0c-0b20b842763e" Volume is already exclusively at
tached to one node and can't be attached to another
```

This eventually times out, and we eventually our Pod will be running on another node.

```
$ kubectl get pod -o wide
NAME                                        READY   STATUS              RESTARTS   AGE     IP                NODE                    NOMINATED NODE   READINESS GATES
my-stateful-app-with-piraeus-0              1/1     Running             0          5m      172.31.0.1        node02.ha.cluster       <none>           <none>
```

This process can take up to 15 minutes using the default settings of Kubernetes.

### The solution

The Piraeus High Availability Controller can speed up this fail-over process significantly. As before, we start out with a running pod:

```
$ kubectl get pod -o wide
NAME                                        READY   STATUS              RESTARTS   AGE     IP                NODE                    NOMINATED NODE   READINESS GATES
my-stateful-app-with-piraeus                1/1     Running             0          10s     172.31.0.1        node01.ha.cluster       <none>           <none>
```

Again, we simulate our node crashing and wait for Kubernetes to recognize the node as unavailable

```
$ kubectl get nodes
NAME                    STATUS     ROLES     AGE    VERSION
master01.ha.cluster     Ready      master    12d    v1.19.4
master02.ha.cluster     Ready      master    12d    v1.19.4
master03.ha.cluster     Ready      master    12d    v1.19.4
node01.ha.cluster       Ready      compute   12d    v1.19.4
node02.ha.cluster       Ready      compute   12d    v1.19.4
node03.ha.cluster       NotReady   compute   12d    v1.19.4
```

We check our pod again. After a short wait (by default after around 10 seconds after the node "crashed"):

```
$ kubectl get pod -o wide
NAME                                        READY   STATUS              RESTARTS   AGE     IP                NODE                    NOMINATED NODE   READINESS GATES
my-stateful-app-with-piraeus-0              0/1     ContainerCreating   0          3s      172.31.0.1        node02.ha.cluster       <none>           <none>
```

We see that the pod was rescheduled to another node. We can also take a look the cluster events:

```
$ kubectl get events --sort-by=.metadata.creationTimestamp -w
...
1s   Warning   NodeStorageQuorumLost    node/node01.ha.cluster                  Tainted node because some volumes have lost quorum
1s   Warning   VolumeWithoutQuorum      pod/suspend-example-57c5c67658-t94wz    Pod was evicted because attached volume lost quorum
1s   Warning   VolumeWithoutQuorum      volumeattachment/csi-fda9f57ce4csd...   Volume attachment was force-detached because node lost quorum
...
```

### How?

The Piraeus High Availability Controller monitors DRBD on every node by starting an agent on every node. When DRBD
reports a resource as promotable, there can't be any currently running Pods on other nodes using the volume. The
agents then check that assumption against the reported cluster state in Kubernetes.

If there are Pods on other nodes that should be attached to the resource, the controller can conclude that those pods
need to be removed. These Pods can't do any writes, so it is safe to delete them.
