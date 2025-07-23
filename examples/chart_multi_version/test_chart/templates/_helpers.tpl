{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}

{{/*
Create a default fully qualified base.name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "base.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default app name based on the namespace
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "base.fullapp" -}}
{{- default .Release.Namespace .Values.fullappOverride -}}
{{- end -}}

{{- define "base.basepath" -}}
{{- $path := (printf "/%s/" (default .Chart.Name .Values.nameOverride )) | trunc 63 | trimSuffix "-" -}}
{{- default $path .Values.basePath -}}
{{- end -}}

# http://masterminds.github.io/sprig/string_slice.html
# http://masterminds.github.io/sprig/lists.html

{{ define "dirname" -}}
{{ splitList "/" . | initial | join "/"}}
{{- end -}}

{{ define "filename" -}}
{{ splitList "/" . | last | join "/"}}
{{- end -}}
