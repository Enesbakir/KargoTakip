{{- define "plateau-gaia-bfa.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Standard fullname with nameOverride/fullnameOverride support. Umbrella installs
set nameOverride to the solution slug (one aliased instance per solution), so
two solutions in the same release never collide on resource names.
*/}}
{{- define "plateau-gaia-bfa.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Single source of truth for the selected environment's config glob. ConfigMap
and the deployment checksum MUST both use this helper so they can never point
at different directories. Fails the render when either slug is missing.
*/}}
{{- define "plateau-gaia-bfa.configGlob" -}}
{{- $solution := required "config.solutionSlug is required" .Values.config.solutionSlug -}}
{{- $environment := required "config.environmentSlug is required" .Values.config.environmentSlug -}}
config/{{ $solution }}/{{ $environment }}/*.gwcjson
{{- end -}}

{{- define "plateau-gaia-bfa.labels" -}}
app.kubernetes.io/name: {{ include "plateau-gaia-bfa.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{- define "plateau-gaia-bfa.selectorLabels" -}}
app.kubernetes.io/name: {{ include "plateau-gaia-bfa.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "plateau-gaia-bfa.redisSelectorLabels" -}}
app.kubernetes.io/name: {{ include "plateau-gaia-bfa.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: redis
{{- end -}}
