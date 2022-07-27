# Maintaining the Chart
This chart is mainly the contents of the latest release of the [etcd-cluster-operator](https://github.com/storageos/etcd-cluster-operator/releases) translated to Helm format.

Updating the chart for a new release begins by clearing out the old release:

```shell
rm crds/*.yml
rm templates/*.yml
```

Following that, we should obtain the new version and decompile it into the format expected by Helm:

```shell
OPERATOR_VERSION=v0.4.2
curl -Lo storageos-etcd-cluster-operator.yaml https://github.com/storageos/etcd-cluster-operator/releases/download/$OPERATOR_VERSION/storageos-etcd-cluster-operator.yaml
curl -Lo storageos-etcd-cluster.yaml https://github.com/storageos/etcd-cluster-operator/releases/download/$OPERATOR_VERSION/storageos-etcd-cluster.yaml
yq ea 'select(.kind=="CustomResourceDefinition")' storageos-etcd-cluster-operator.yaml --split-exp='"crds/" + (.metadata.name)'
yq ea 'select(.kind != "CustomResourceDefinition")' storageos-etcd-cluster-operator.yaml --split-exp='"templates/" + (.kind) + "-" + (.metadata.name)'
```

The next step will then template various values in the `templates` directory to fit helm's configuration format:

```shell
# Template namespace
sed -i templates/* -e 's/namespace: storageos-etcd/namespace: {{ .Release.Namespace }}/g' -e 's/storageos-etcd.svc/{{ .Release.Namespace }}.svc/g'
# Template namespace name
sed -i templates/Namespace-storageos-etcd.yml -e 's/name: storageos-etcd/name: {{ .Release.Namespace }}/g'
# Template arguments to the operator
sed -i templates/* -e 's%--leader-election-cm-namespace=storageos%--leader-election-cm-namespace={{ .Release.Namespace }}\n            - --etcd-repository={{ .Values.images.etcd.repository }}%g'
# Add labels to all manifests
sed -i templates/*.yml -e '0,/labels:/{/labels:/d;}' -e '0,/metadata:/{s/metadata:/metadata:\n{{- template "etcd-cluster-operator.labels" . }}/}'
# Set the proxy image
sed -i templates/Deployment-storageos-etcd-proxy.yml -e 's/image: storageos\/etcd-cluster-operator-proxy.*$/image: {{ .Values.images.etcdClusterOperatorProxy.repository }}:{{ .Values.images.etcdClusterOperatorProxy.tag }}/g'
# Set the operator image
sed -i templates/Deployment-storageos-etcd-controller-manager.yml -e 's/image: storageos\/etcd-cluster-operator-controller.*$/image: {{ .Values.images.etcdClusterOperatorController.repository }}:{{ .Values.images.etcdClusterOperatorController.tag }}/g'
```

Then create the template for the namespace:

```
cat <<EOF > templates/Namespace-storageos-etcd.yml
{{- if .Values.cluster.namespace -}}
{{- if not (lookup "v1" "Namespace" "" .Values.cluster.namespace) }}
{{- if not (eq .Release.Namespace .Values.cluster.namespace) }}
apiVersion: v1
kind: Namespace
metadata:
{{- template "etcd-cluster-operator.labels" . }}
  name: {{ .Values.cluster.namespace }}
{{- end -}}
{{- end -}}
{{- end -}}
EOF
```

Then update any relevant default values in the values file.
And be sure to update `appVersion` in `Chart.yaml` to the new version used of the operator.
When this is complete, we should rewrite `templates/etcdcluster_cr.yaml` with any changes. This one file is heavily templated for Helm to provide configurability and is correspondent to the file `storageos-etcd-cluster.yaml` from the above mentioned repository.

Before you commit, be sure to check the output of `git diff` and `helm template .` and ensure that the changes make sense.
