
APP_VERSION := $(shell yq e '.appVersion' ./Chart.yaml)

.PHONY: crds

crds:
	( \
		echo "# DO NOT EDIT; Automatically created by make crds" ;\
		curl -fsSL https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(APP_VERSION)/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml ;\
		curl -fsSL https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(APP_VERSION)/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml ;\
		curl -fsSL https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(APP_VERSION)/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml ;\
		curl -fsSL https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(APP_VERSION)/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshotclasses.yaml ;\
		curl -fsSL https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(APP_VERSION)/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshotcontents.yaml ;\
		curl -fsSL https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$(APP_VERSION)/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshots.yaml \
	) | yq 'select(.spec.conversion).spec.conversion.webhook.clientConfig.service |= {"namespace": "{{ .Namespace }}", "name": "{{ .ServiceName }}", "path": .path}' \
	  | yq 'select(.spec.conversion).spec.conversion.webhook.clientConfig.caBundle = "{{ .CaBundle }}"' \
	  | yq 'select(.spec.conversion).metadata.annotations["cert-manager.io/inject-ca-from"] = "{{ .Namespace }}/{{ .CertificateName }}"' \
	  > crds.yaml
