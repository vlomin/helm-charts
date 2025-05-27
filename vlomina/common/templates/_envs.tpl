{{- define "global.envs" -}}
{{- $top := first . }}
{{- $values := index . 1 }}
{{- $microservice := $values.microservice | default dict }}
{{- $common := $values.common | default dict }}
{{- $envs := merge ($microservice.envs | default dict) ($common.envs | default dict) }}
{{- range $key, $value := $envs }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- $secretEnvs := append ($microservice.secret_envs | default list) ($common.secret_envs | default list) }}
{{- range $item := $secretEnvs }}
- name: {{ $item.env_name }}
  valueFrom:
    secretKeyRef:
      name: {{ $item.secret_name }}
      key: {{ $item.secret_key }}
{{- end }}

{{- $lookupEnvs := append ($microservice.lookup_envs | default list) ($common.lookup_envs | default list) }}
{{- range $item := $lookupEnvs }}
  {{- $apiVersion := default "v1" $item.api_version }}
  {{- $namespace := default $top.Release.Namespace $item.namespace }}
  {{- $entityKind := $item.entity_kind | default "ConfigMap" }}
  {{- $entity := lookup $apiVersion $entityKind $namespace $item.entity_name }}
  {{- if and $entity $entity.data }}
    {{- $rawValue := index $entity.data $item.entity_key }}
    {{- if $rawValue }}
- name: {{ $item.env_name }}
  value: {{ if eq ($item.b64decode | default false) false }}
    {{ $rawValue | quote }}
    {{- else }}
    {{ $rawValue | b64dec | quote }}
    {{- end }}
    {{- else }}
# Warning: key '{{ $item.entity_key }}' not found in {{ $entityKind }} '{{ $item.entity_name }}'
    {{- end }}
  {{- else }}
# Warning: {{ $entityKind }} '{{ $item.entity_name }}' not found in namespace '{{ $namespace }}'
  {{- end }}
{{- end }}

{{- end }}
