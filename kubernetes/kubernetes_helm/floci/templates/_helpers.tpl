{{- define "floci.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "floci.fullname" -}}
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

{{- define "floci.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "floci.labels" -}}
helm.sh/chart: {{ include "floci.chart" . }}
{{ include "floci.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "floci.selectorLabels" -}}
app.kubernetes.io/name: {{ include "floci.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "floci.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "floci.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "floci.imageTag" -}}
{{- .Values.image.tag | default .Chart.AppVersion | default "latest" }}
{{- end }}

{{- define "floci.env" -}}
{{- $host := .Values.config.hostname | default (printf "%s:%d" (include "floci.fullname" .) (.Values.service.port | int)) }}
- name: FLOCI_PORT
  value: {{ .Values.service.port | quote }}
- name: FLOCI_STORAGE_MODE
  value: {{ .Values.config.storageMode }}
- name: FLOCI_LOG_LEVEL
  value: {{ .Values.config.logLevel }}
- name: EDGE_PORT
  value: {{ .Values.config.edgePort | quote }}
- name: AWS_ENDPOINT_URL
  value: http://{{ $host }}
{{- if .Values.config.services }}
- name: SERVICES
  value: {{ .Values.config.services }}
{{- end }}
{{- if .Values.config.tlsEnabled }}
- name: FLOCI_TLS_ENABLED
  value: "true"
{{- end }}
{{- if .Values.config.dockerNetwork }}
- name: FLOCI_SERVICES_DOCKER_NETWORK
  value: {{ .Values.config.dockerNetwork }}
{{- end }}
{{- if .Values.config.localstackCompat }}
- name: LOCALSTACK_HOST
  value: {{ $host }}
- name: PERSISTENCE
  value: {{ .Values.persistence.enabled | quote }}
{{- end }}
{{- with .Values.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- end }}
