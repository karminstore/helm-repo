{{- define "app_conf" }}
{{- $dot := . }}
listen:
  host: 0.0.0.0
{{- if .Values.global.ports }}
  {{- if contains "true" (toString .Values.global.ports) }}
  ports:
    {{- range $key, $value := .Values.global.ports }}
      {{- if eq (lower (toString $value )) "true" }}
    {{ $key }}: {{ index $dot.Values.server.ports $key }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
app:
  name: {{ regexReplaceAll (printf "-%s$" .Release.Namespace) .Release.Name "" }}
{{- if .Values.global.config.app }}
{{ toYaml .Values.global.config.app | indent 2 }}
{{- end }}
microservices:
{{ toYaml .Values.microservices | indent 2 }}
{{- end }}
