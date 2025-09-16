{{/*
Expand the name of the chart.
*/}}
{{- define "pay-log-aggregator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pay-log-aggregator.fullname" -}}
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
{{- define "pay-log-aggregator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels (following common-helm-templates pattern)
*/}}
{{- define "pay-log-aggregator.selectorLabels" }}
app.kubernetes.io/name: {{ include "pay-log-aggregator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels (following common-helm-templates pattern)
*/}}
{{- define "pay-log-aggregator.labels" }}
helm.sh/chart: {{ include "pay-log-aggregator.chart" . }}
{{ include "pay-log-aggregator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: "log-aggregator"
app.kubernetes.io/part-of: "observability-stack"
team: {{ required "value '.Values.global.team' is required" .Values.global.team }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "pay-log-aggregator.serviceAccountName" -}}
{{- if .Values.deployment.createServiceAccount }}
{{- default (include "pay-log-aggregator.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image name helper (following common-helm-templates pattern)
*/}}
{{- define "pay-log-aggregator.image" -}}
{{- $image := .Values.deployment.image.name | default .Values.global.defaultImageName }}
{{- $tag := .Values.deployment.image.tag | default .Values.global.defaultTag }}
{{- printf "%s:%s" $image $tag }}
{{- end }}

{{/*
Container environment variables helper
*/}}
{{- define "pay-log-aggregator.containerEnv" -}}
{{- range .Values.deployment.containerEnv }}
- name: {{ .name | quote }}
  value: {{ .value | quote }}
{{- end }}
{{- if .Values.global.configurations.enabled }}
{{- range $key, $value := .Values.global.configurations.values }}
- name: {{ $key | quote }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Container environment variables from secrets helper
*/}}
{{- define "pay-log-aggregator.containerValueFrom" -}}
{{- range .Values.deployment.containerValueFrom }}
- name: {{ .envName | quote }}
  valueFrom:
    secretKeyRef:
      name: {{ .name | quote }}
      key: {{ .key | quote }}
{{- end }}
{{- end }}