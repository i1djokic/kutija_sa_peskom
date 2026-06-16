{{- define "opencode.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "opencode.fullname" -}}
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

{{- define "opencode.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "opencode.labels" -}}
helm.sh/chart: {{ include "opencode.chart" . }}
{{ include "opencode.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "opencode.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opencode.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "opencode.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "opencode.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "opencode.imageTag" -}}
{{- .Values.image.tag | default .Chart.AppVersion | default "latest" }}
{{- end }}

{{- define "opencode.env" -}}
- name: OPENCODE_SERVER_PORT
  value: {{ .Values.config.port | quote }}
- name: OPENCODE_SERVER_HOSTNAME
  value: {{ .Values.config.hostname }}
{{- if .Values.config.password }}
- name: OPENCODE_SERVER_USERNAME
  value: {{ .Values.config.username }}
- name: OPENCODE_SERVER_PASSWORD
  value: {{ .Values.config.password }}
{{- end }}
{{- if .Values.config.mdns }}
- name: OPENCODE_SERVER_MDNS
  value: "true"
{{- end }}
{{- if .Values.config.cors }}
- name: OPENCODE_SERVER_CORS
  value: {{ join "," .Values.config.cors }}
{{- end }}
{{- with .Values.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- end }}
