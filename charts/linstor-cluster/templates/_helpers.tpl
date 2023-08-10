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

{{/*
Return true, if apiTLS enabled
*/}}
{{- define "linstor-cluster.createApiTLSCert" -}}
{{- if .Values.linstorCluster }}
    {{- if .Values.linstorCluster.apiTLS }}
        {{- if .Values.linstorCluster.apiTLS.enabled }}
            {{- true -}}
        {{- end }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
Return true, if internalTLS enabled
*/}}
{{- define "linstor-cluster.createInternalTLSCert" -}}
{{- if .Values.linstorCluster }}
    {{- if .Values.linstorCluster.internalTLS }}
        {{- if .Values.linstorCluster.internalTLS.enabled }}
            {{- true -}}
        {{- end }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
Retur true, if Secret with MASTER_PASSPHRASE will be created from this chart
*/}}
{{- define "linstor-cluster.createPassPhraseSecret" }}
{{- if .Values.linstorCluster }}
    {{- if .Values.linstorCluster.linstorPassphraseSecret }}
        {{- if .Values.linstorCluster.linstorPassphraseSecret.masterPassPhrase }}
            {{- true -}}
        {{- end }}
        {{- if and (.Values.linstorCluster.linstorPassphraseSecret.masterPassPhrase) (.Values.linstorCluster.linstorPassphraseSecret.existingSecretName) }}
            {{ fail "Values of masterPassPhrase and existingSecretName was defined! Expected only one" }}
        {{- end }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
Define name of secret with MASTER_PASSPHRASE in linstorCluter
*/}}
{{- define "linstor-cluster.passPhraseSecretName" }}
{{- if .Values.linstorCluster }}
    {{- if .Values.linstorCluster.linstorPassphraseSecret }}
        {{- if .Values.linstorCluster.linstorPassphraseSecret.masterPassPhrase }}
            {{- printf "%s-passphrase" (include "linstor-cluster.fullname" .) }}
        {{- else if .Values.linstorCluster.linstorPassphraseSecret.existingSecretName }}
            {{- .Values.linstorCluster.linstorPassphraseSecret.existingSecretName }}
        {{- end }}
    {{- end }}
{{- end }}
{{- end }}
