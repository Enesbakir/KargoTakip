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
Redis-specific resource name. Reuses plateau-gaia-bfa.fullname but reserves
room for the "-redis" suffix by truncating to 57 chars first, so the redis
Deployment/Service name never exceeds the 63-char Kubernetes Service (DNS
label) limit. Only redis resources use this helper; every other resource
(Deployment, Service, Ingress, ConfigMaps, Secret) keeps using fullname
unchanged.
*/}}
{{- define "plateau-gaia-bfa.redisFullname" -}}
{{- printf "%s-redis" (include "plateau-gaia-bfa.fullname" . | trunc 57 | trimSuffix "-") -}}
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

{{/*
Selector labels for the main app Service only. Adds component: app on top of
selectorLabels so the Service never picks up the redis pod (which carries
component: redis) as an endpoint. NOT used for the Deployment's
spec.selector.matchLabels, which is immutable once created and must keep
using plain selectorLabels to avoid breaking helm upgrade on existing
installs. The pod template adds the matching component: app label alongside
selectorLabels, which is a safe superset change (normal rollout, no
immutability issue).
*/}}
{{- define "plateau-gaia-bfa.appSelectorLabels" -}}
{{- include "plateau-gaia-bfa.selectorLabels" . }}
app.kubernetes.io/component: app
{{- end -}}
