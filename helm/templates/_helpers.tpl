{{/*
Generate the name of the application.
*/}}
{{- define "chatapp.name" -}}
{{ .Chart.Name }}
{{- end -}}

{{/*
Generate a full name including the release name.
*/}}
{{- define "chatapp.fullname" -}}
{{ printf "%s-%s" .Release.Name .Chart.Name }}
{{- end -}}

{{/*
Generate common labels.
*/}}
{{- define "chatapp.labels" -}}
app.kubernetes.io/name: {{ include "chatapp.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels (used in matchLabels)
*/}}
{{- define "chatapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chatapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
