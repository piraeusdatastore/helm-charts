{{/*
Expand the name of the chart.
*/}}
{{- define "linstor-affinity-controller.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "linstor-affinity-controller.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "linstor-affinity-controller.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "linstor-affinity-controller.labels" -}}
helm.sh/chart: {{ include "linstor-affinity-controller.chart" . }}
{{ include "linstor-affinity-controller.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "linstor-affinity-controller.selectorLabels" -}}
app.kubernetes.io/name: {{ include "linstor-affinity-controller.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "linstor-affinity-controller.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "linstor-affinity-controller.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Find the linstor client secret containing TLS certificates
*/}}
{{- define "linstor-affinity-controller.linstorClientSecretName" -}}
{{- if .Values.linstor.clientSecret }}
{{- .Values.linstor.clientSecret }}
{{- else if .Capabilities.APIVersions.Has "piraeus.linbit.com/v1/LinstorController" }}
{{- $crs := (lookup "piraeus.linbit.com/v1" "LinstorController" .Release.Namespace "").items }}
{{- if $crs }}
{{- if eq (len $crs) 1 }}
{{- $item := index $crs 0 }}
{{- $item.spec.linstorHttpsClientSecret }}
{{- end }}
{{- end }}
{{- else if .Capabilities.APIVersions.Has "linstor.linbit.com/v1/LinstorController" }}
{{- $crs := (lookup "linstor.linbit.com/v1" "LinstorController" .Release.Namespace "").items }}
{{- if $crs }}
{{- if eq (len $crs) 1 }}
{{- $item := index $crs 0 }}
{{- $item.spec.linstorHttpsClientSecret }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Find the linstor URL by operator resources
*/}}
{{- define "linstor-affinity-controller.linstorEndpointFromCRD" -}}
{{- if .Capabilities.APIVersions.Has "piraeus.linbit.com/v1/LinstorController" }}
{{- $crs := (lookup "piraeus.linbit.com/v1" "LinstorController" .Release.Namespace "").items }}
{{- if $crs }}
{{- if eq (len $crs) 1 }}
{{- $item := index $crs 0 }}
{{- if include "linstor-affinity-controller.linstorClientSecretName" . }}
{{- printf "https://%s.%s.svc:3371" $item.metadata.name $item.metadata.namespace }}
{{- else }}
{{- printf "http://%s.%s.svc:3370" $item.metadata.name $item.metadata.namespace }}
{{- end }}
{{- end }}
{{- end }}
{{- else if .Capabilities.APIVersions.Has "linstor.linbit.com/v1/LinstorController" }}
{{- $crs := (lookup "linstor.linbit.com/v1" "LinstorController" .Release.Namespace "").items }}
{{- if $crs }}
{{- if eq (len $crs) 1 }}
{{- $item := index $crs 0 }}
{{- if include "linstor-affinity-controller.linstorClientSecretName" . }}
{{- printf "https://%s.%s.svc:3371" $item.metadata.name $item.metadata.namespace }}
{{- else }}
{{- printf "http://%s.%s.svc:3370" $item.metadata.name $item.metadata.namespace }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Find the linstor URL either by override or cluster resources
*/}}
{{- define "linstor-affinity-controller.linstorEndpoint" -}}
{{- if .Values.linstor.endpoint }}
{{- .Values.linstor.endpoint }}
{{- else }}
{{- $piraeus := include "linstor-affinity-controller.linstorEndpointFromCRD" . }}
{{- if $piraeus }}
{{- $piraeus }}
{{- else }}
{{- fail "Please specify linstor.endpoint, no default URL could be determined" }}
{{- end }}
{{- end }}
{{- end }}
