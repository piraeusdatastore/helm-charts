
APP_VERSION := $(shell yq e '.appVersion' ./Chart.yaml)

.PHONY: crds

crds:
	curl -fsSL https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(APP_VERSION)/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml -o crds/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
	curl -fsSL https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(APP_VERSION)/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml -o crds/snapshot.storage.k8s.io_volumesnapshots.yaml
	curl -fsSL https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(APP_VERSION)/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml -o crds/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
	curl -fsSL https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(APP_VERSION)/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshotclasses.yaml -o crds/groupsnapshot.storage.k8s.io_volumegroupsnapshotclasses.yaml
	curl -fsSL https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(APP_VERSION)/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshotcontents.yaml -o crds/groupsnapshot.storage.k8s.io_volumegroupsnapshotcontents.yaml
	curl -fsSL https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(APP_VERSION)/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshots.yaml -o crds/groupsnapshot.storage.k8s.io_volumegroupsnapshots.yaml
