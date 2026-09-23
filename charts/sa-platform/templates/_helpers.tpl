{{/*
Nombre completo de un componente: <release>-<nombre-subchart>
Uso: {{ include "sa.fullname" (dict "root" $ "name" .Chart.Name) }}
*/}}
{{- define "sa.fullname" -}}
{{- printf "%s-%s" .root.Release.Name .name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Labels comunes aplicados a todo objeto de la plataforma.
*/}}
{{- define "sa.labels" -}}
app.kubernetes.io/part-of: sa-platform
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
sa-platform/component: {{ .name }}
{{- end -}}

{{/*
Selector labels: subconjunto estable usado por Service/Deployment/HPA/PDB.
*/}}
{{- define "sa.selectorLabels" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
{{- end -}}

{{/*
Nombre del ServiceAccount dedicado del componente (nunca "default").
*/}}
{{- define "sa.serviceAccountName" -}}
{{- include "sa.fullname" . -}}-sa
{{- end -}}

{{/*
securityContext a nivel POD (spec.securityContext / PodSecurityContext).
Solo incluye campos que EXISTEN en ese objeto. readOnlyRootFilesystem,
allowPrivilegeEscalation y capabilities NO son campos validos de
PodSecurityContext (solo existen en container.securityContext); antes
estaban aqui por error y el API server los ignora/rechaza.
*/}}
{{- define "sa.securityContext" -}}
runAsNonRoot: true
runAsUser: 10001
seccompProfile:
  type: RuntimeDefault
{{- end -}}

{{/*
securityContext a nivel CONTENEDOR (containers[].securityContext).
Aqui SI existen readOnlyRootFilesystem, allowPrivilegeEscalation y capabilities.
*/}}
{{- define "sa.containerSecurityContext" -}}
runAsNonRoot: true
runAsUser: 10001
readOnlyRootFilesystem: true
allowPrivilegeEscalation: false
capabilities:
  drop: ["ALL"]
{{- end -}}

{{/*
Genera bloques de env vars a partir de .Values.extraEnv (lista de objetos).
Cada entrada DEBE tener "name"; "value" es opcional y adopta "" si no se define.
Uso: {{ include "sa.extraEnv" (dict "root" $ "list" .Values.extraEnv) | nindent 12 }}

Demuestra: range · required · default · quote
*/}}
{{- define "sa.extraEnv" -}}
{{- range .list }}
- name: {{ required "sa.extraEnv: cada entrada debe tener 'name' definido" .name | quote }}
  value: {{ .value | default "" | quote }}
{{- end -}}
{{- end -}}
