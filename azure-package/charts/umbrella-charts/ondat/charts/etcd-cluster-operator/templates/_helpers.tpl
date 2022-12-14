{{- define "etcd-cluster-operator.labels" }}
  labels:
    app.kubernetes.io/name: {{ .Chart.Name }}
    helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    app.kubernetes.io/version: {{ .Chart.AppVersion }}
{{- end }}

{{/*
The version of the etcd container to use is input as a field in the CR
Bizarrely, this is taken as a 'version' not an image tag (not leading 'v')
This function removes the v from the tag string, such that we can have consistent image values
{{- define etcdImageVersion -}}
{{ trimPrefix "v" .Values.global.azure.images.etcd.digest }}
{{- end -}}
*/}}
