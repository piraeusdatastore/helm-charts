{{/*
Expand the name of the chart.
*/}}
{{- define "linstor-cluster.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "linstor-cluster.fullname" -}}
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

{{- define "linstor-cluster.linstorPassphraseSecret" -}}
{{- if .Values.linstorCluster.linstorPassphraseSecret }}
    {{- .Values.linstorCluster.linstorPassphraseSecret }}
{{- else }}
    {{- include "linstor-cluster.fullname" . }}-passphrase
{{- end }}
{{- end }}

{{- define "linstor-cluster.apiTLSIssuer" -}}
{{- dig "apiTLS" "certManager" "name" (printf "%s-api-ca" (include "linstor-cluster.fullname" .)) .Values.linstorCluster }}
{{- end }}

{{- define "linstor-cluster.internalTLSIssuer" -}}
{{- dig "internalTLS" "certManager" "name" (printf "%s-internal-ca" (include "linstor-cluster.fullname" .)) .Values.linstorCluster }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "linstor-cluster.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "linstor-cluster.labels" -}}
helm.sh/chart: {{ include "linstor-cluster.chart" . }}
{{ include "linstor-cluster.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "linstor-cluster.selectorLabels" -}}
app.kubernetes.io/name: {{ include "linstor-cluster.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
