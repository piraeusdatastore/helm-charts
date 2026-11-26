# Contributing to Piraeus Charts

The [Piraeus contributing guide](https://github.com/piraeusdatastore/piraeus/blob/master/CONTRIBUTING.md) describes how to report issues, write commits and changelog entries, and open pull requests.
The sections that follow describe what is specific to this repository.

## Target branch

Open pull requests against the `main` branch.

## Chart versions

Each chart in `charts/` has its own version in the `version` field of its `Chart.yaml` file.
On every push to `main`, the release workflow publishes each chart version that is not published yet.
If you change a chart, increase its `version` in the same commit.
Otherwise, the release workflow does not publish the change.

Renovate updates the `appVersion` field when a new image is released, and increases the chart version.

## Chart values

The chart README files list the chart values.
If you add or change a value, update the `README.md` file of the chart.

## Checks

Install [Helm](https://helm.sh/).
Lint a chart and render its templates before you open a pull request:

```
$ helm lint charts/<chart>
$ helm template test charts/<chart>
```

The `linstor-scheduler` chart has unit tests in its `tests/` directory.
Run them with the [helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin:

```
$ helm unittest charts/linstor-scheduler
```

CI does not run these checks.

## Generated files

`charts/snapshot-controller/templates/crds.yaml` is generated from the CRDs of the matching [external-snapshotter](https://github.com/kubernetes-csi/external-snapshotter) release.
Do not edit it by hand.
To regenerate it after a change to `appVersion`, install `curl` and [`yq`](https://github.com/mikefarah/yq), and run:

```
$ make -C charts/snapshot-controller crds
```

## Commit messages

Start the subject line with the name of the chart, for example `linstor-cluster: add Gateway API HTTPRoute`.
