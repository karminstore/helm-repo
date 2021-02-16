{{/*
Return requests memory
*/}}
{{- define "requests.memory" }}
{{- if eq .Release.Namespace "production" }}
  {{- .Values.resources.requests.memory.production | quote }}
{{- else }}
  {{- .Values.resources.requests.memory.default | quote }}
{{- end }}
{{- end }}

{{/*
Return requests cpu
*/}}
{{- define "requests.cpu" }}
{{- if eq .Release.Namespace "production" }}
  {{- .Values.resources.requests.cpu.production | quote }}
{{- else }}
  {{- .Values.resources.requests.cpu.default | quote }}
{{- end }}
{{- end }}

{{/*
Return limits memory
*/}}
{{- define "limits.memory" }}
{{- if eq .Release.Namespace "production" }}
  {{- .Values.resources.limits.memory.production | quote }}
{{- else }}
  {{- .Values.resources.limits.memory.default | quote }}
{{- end }}
{{- end }}

{{/*
Return limits cpu
*/}}
{{- define "limits.cpu" }}
{{- if eq .Release.Namespace "production" }}
  {{- .Values.resources.limits.cpu.production | quote }}
{{- else }}
  {{- .Values.resources.limits.cpu.default | quote }}
{{- end }}
{{- end }}

{{/*
Return resources min_replicas
*/}}
{{- define "resources.min_replicas" }}
{{- if eq .Release.Namespace "production" }}
  {{- .Values.resources.min_replicas.production }}
{{- else }}
  {{- .Values.resources.min_replicas.default }}
{{- end }}
{{- end }}

{{/*
Return resources max_replicas
*/}}
{{- define "resources.max_replicas" }}
{{- if eq .Release.Namespace "production" }}
  {{- .Values.resources.max_replicas.production }}
{{- else }}
  {{- .Values.resources.max_replicas.default }}
{{- end }}
{{- end }}

{{/*
Return containers spec
*/}}
{{- define "containers.base" }}
  {{- $root       := index . "root" }}
  {{- $containers := index . "containers" }}
  {{- $kind       := index . "kind" }}
  {{- $chartName  := index . "chartName" }}
  {{- $additional := index . "additional" }}

  {{- if gt (len $containers) 0 }}
{{ $kind }}:
    {{- range $i, $container := $containers }}
- name: {{ printf "%s-%s-%s" $chartName (trimSuffix "s" $kind) (toString $i) | lower }}
  command: {{ $container.command | toJson }}
      {{- if $root.Values.global.image.digest }}
  image: {{ $root.Values.global.image.registry }}/{{ $root.Values.global.image.repository }}@{{ $root.Values.global.image.digest }}
      {{- else }}
  image: {{ $root.Values.global.image.registry }}/{{ $root.Values.global.image.repository }}:{{ $root.Values.global.image.tag }}
      {{- end }}
  imagePullPolicy: {{ $root.Values.global.image.pullPolicy }}
  env:
  - name: APP_ENVIRONMENT
    valueFrom:
      fieldRef:
        fieldPath: metadata.namespace
      {{- if $root.Values.global.extraEnvs }}
{{ toYaml $root.Values.global.extraEnvs | indent 2 }}
      {{- end}}
      {{- if $root.Values.global.services }}
        {{- range $key, $value := $root.Values.global.services }}
          {{- if eq ( kindOf $value ) "bool" }}
            {{- if eq (lower (toString $value)) "true" }}
              {{- range $valueType := list "configMap" "secret" }}
                {{- range index $root.Values.services (printf "%s-%s" $key $valueType ) }}
  - name: {{ printf "%s_%s" $key . | upper }}
    valueFrom:
      {{ printf "%sKeyRef" $valueType }}:
        name: {{ $key }}
        key: {{ . }}
                {{- end }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- if eq ( kindOf $value ) "map" }}
            {{- range $keyInObject, $valueInObject := index $root.Values.global.services $key }}
              {{- if eq (lower (toString $valueInObject)) "true" }}
                {{- range $valueType := list "configMap" "secret" }}
                  {{- range index $root.Values.services $key (printf "%s-%s" $keyInObject $valueType ) }}
  - name: {{ printf "%s_%s_%s" $key $keyInObject . | upper }}
    valueFrom:
      {{ printf "%sKeyRef" $valueType }}:
        name: {{ printf "%s-%s" $key $keyInObject }}
        key: {{ . }}
                  {{- end }}
                {{- end }}
              {{- end }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}
  volumeMounts:
  - name: {{ printf "%s-config" $chartName }}
    mountPath: {{ $root.Values.global.config_mount_path | default "/app/config" }}
    {{- end }}
  {{- end }}
  {{- if $additional }}
{{ $additional | indent 2}}
  {{- end }}
{{- end }}


{{/*
Template main containers additional specs
*/}}
{{- define "containers.additional" }}
  {{- $root := . }}
{{- /* // LIFECYCLE PRESTOP
lifecycle:
  preStop:
    exec:
      command: ["/bin/sleep", "15"]
// LIFECYCLE PRESTOP END */}}
  {{- if $root.Values.global.ports }}
    {{- if contains "true" (toString $root.Values.global.ports) }}
ports:
      {{- range $key, $value := $root.Values.global.ports }}
        {{- if eq (lower (toString $value )) "true" }}
- containerPort: {{ index $root.Values.server.ports $key }}
  name: {{ $key }}
  protocol: TCP
        {{- end }}
      {{- end }}
      {{- if contains "true" (toString $root.Values.global.serviceMonitor.enabled) }}
- containerPort: {{ $root.Values.global.serviceMonitor.port }}
  name: {{ $root.Values.global.serviceMonitor.portName }}
  protocol: TCP
      {{- end }}
livenessProbe:
  failureThreshold: 5
  initialDelaySeconds: 30
  periodSeconds: 5
  successThreshold: 1
  tcpSocket:
      {{- if $root.Values.global.custom_tcp_probe_port }}
    port: {{ $root.Values.global.custom_tcp_probe_port }}
      {{- else if eq (lower (toString $root.Values.global.ports.grpc)) "true" }}
    port: {{ $root.Values.server.ports.grpc }}
      {{- else if eq (lower (toString $root.Values.global.ports.http )) "true" }}
    port: {{ $root.Values.server.ports.http }}
      {{- end }}
  timeoutSeconds: 1
readinessProbe:
  failureThreshold: 5
  initialDelaySeconds: 30
  periodSeconds: 5
  successThreshold: 1
  tcpSocket:
      {{- if $root.Values.global.custom_tcp_probe_port }}
    port: {{ $root.Values.global.custom_tcp_probe_port }}
      {{- else if eq (lower (toString $root.Values.global.ports.grpc)) "true" }}
    port: {{ $root.Values.server.ports.grpc }}
      {{- else if eq (lower (toString $root.Values.global.ports.http )) "true" }}
    port: {{ $root.Values.server.ports.http }}
      {{- end }}
  timeoutSeconds: 1
    {{- end }}
  {{- end }}
resources:
  limits:
    cpu: {{ template "limits.cpu" . }}
    memory: {{ template "limits.memory" . }}
  requests:
    cpu: {{ template "requests.cpu" . }}
    memory: {{ template "requests.memory" . }}
{{- end }}
