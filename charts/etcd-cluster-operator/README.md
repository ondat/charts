# etcd-cluster-operator Helm Chart

Etcd Cluster Operator is an [Operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator) for automating
the creation and management of etcd inside of Kubernetes. It provides a
[custom resource definition (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources)
based API to define etcd clusters with Kubernetes resources, and enable management with native Kubernetes tooling.

## Prerequisites

- Helm 3
- Kubernetes 1.18+

## Installing the chart

```console
# Add ondat charts repo.
$ helm repo add ondat https://ondat.github.io/charts
# Install the chart in a namespace.
$ kubectl create namespace ondat-operator
$ helm install my-etcd ondat/ondat-operator \
    --namespace ondat-operator \
    --set cluster.kvBackend.address=<etcd-node-ip>:2379 \
    --set cluster.admin.password=<password>
```

This will install the Ondat cluster operator in `ondat-operator`
namespace and deploys StorageOS with a minimal configuration. Etcd address
(kvBackend) and admin password are mandatory values to install the chart.

The password must be at least 8 characters long and the default username is
`storageos`, which can be changed like the above values. Find more information
about installing etcd in our [etcd
docs](https://docs.ondat.io/docs/prerequisites/etcd/).

To avoid passing the password as a flag, install the chart with the values file.
Create a values.yaml file and pass the file name with `--values` flag.

```yaml
cluster:
  kvBackend:
    address: <etcd-node-ip>:2379
  admin:
    password: <password>
```

```console
$ helm install ondat/ondat-operator \
    --namespace ondat-operator \
    --values <values-file>
```
> **Tip**: List all releases using `helm list -A`

## Creating a StorageOS cluster manually

The Helm chart supports a subset of StorageOSCluster custom resource parameters.
For advanced configurations, you may wish to create the cluster resource
manually and only use the Helm chart to install the Operator.

To disable auto-provisioning the cluster with the Helm chart, set
`cluster.create` to false:

```yaml
cluster:
  ...
  create: false
```

Create a secret to store storageos cluster secrets:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: "storageos-api"
  namespace: <storageos-cluster-namespace>
  labels:
    app: "storageos"
type: "kubernetes.io/storageos"
data:
  # echo -n '<secret>' | base64
  username: c3RvcmFnZW9z
  password: c3RvcmFnZW9z
```

Create a `StorageOSCluster` custom resource and refer the above secret in the
`secretRefName` field.

```yaml
apiVersion: "storageos.com/v1"
kind: "StorageOSCluster"
metadata:
  name: "example-storageos"
  namespace: <storageos-cluster-namespace>
spec:
  secretRefName: "storageos-api"
  kvBackend:
    address: "etcd-client.etcd.svc.cluster.local:2379"
    # address: '10.42.15.23:2379,10.42.12.22:2379,10.42.13.16:2379' # You can set ETCD server IPs.
  storageClassName: "storageos"
```

<!--- TODO: replace this when an equivalent specification exsists for the new
operator, ticket has been created. Also replace in app-readme -->
Learn more about advanced configuration options
[here](https://github.com/storageos/cluster-operator/blob/master/README.md#storageoscluster-resource-configuration).

To check cluster status, run:

```console
$ kubectl get storageoscluster --namespace <storageos-cluster-namespace>
NAME                READY     STATUS    AGE
example-storageos   3/3       Running   4m
```

All the events related to this cluster are logged as part of the cluster object
and can be viewed by describing the object.

```console
$ kubectl describe storageoscluster example-storageos --namespace <storageos-cluster-namespace>
Name:         example-storageos
Namespace:    default
Labels:       <none>
...
...
Events:
  Type     Reason         Age              From                       Message
  ----     ------         ----             ----                       -------
  Warning  ChangedStatus  1m (x2 over 1m)  storageos-operator  0/3 StorageOS nodes are functional
  Normal   ChangedStatus  35s              storageos-operator  3/3 StorageOS nodes are functional. Cluster healthy
```

## Configuration

The following tables lists the configurable parameters of the StorageOSCluster
Operator chart and their default values.

Parameter | Description | Default
--------- | ----------- | -------
`operator.image.repository` | StorageOS Operator container image repository | `storageos/operator`
`operator.image.tag` | StorageOS Operator container image tag | `v2.5.0`
`operator.image.pullPolicy` | StorageOS Operator container image pull policy | `IfNotPresent`
`podSecurityPolicy.enabled` | If true, create & use PodSecurityPolicy resources | `false`
`podSecurityPolicy.annotations` | Specify pod annotations in the pod security policy | `{}`
`cluster.create` | If true, auto-create the StorageOS cluster | `true`
`cluster.name` | Name of the storageos deployment | `storageos`
`cluster.namespace` | Namespace to install the StorageOS cluster into |
`storageos`
`cluster.secretRefName` | Name of the secret containing StorageOS API credentials | `storageos-api`
`cluster.admin.username` | Username to authenticate to the StorageOS API with | `storageos`
`cluster.admin.password` | Password to authenticate to the StorageOS API with |
`cluster.sharedDir` | The path shared into to kubelet container when running kubelet in a container |
`cluster.kvBackend.address` | List of etcd targets, in the form ip[:port], separated by commas |
`cluster.kvBackend.backend` | Key-Value store backend name | `etcd`
`cluster.kvBackend.tlsSecretName` | Name of the secret containing kv backend tls cert |
`cluster.kvBackend.tlsSecretNamespace` | Namespace of the secret containing kv backend tls cert |
`cluster.nodeSelectorTerm.key` | Key of the node selector term used for pod placement |
`cluster.nodeSelectorTerm.value` | Value of the node selector term used for pod placement |
`cluster.toleration.key` | Key of the pod toleration parameter |
`cluster.toleration.value` | Value of the pod toleration parameter |
`cluster.disableTelemetry` | If true, no telemetry data will be collected from the cluster | `false`
`cluster.storageClassName` | Name of the StorageClass to be created | `storageos`
`cluster.images.apiManager.repository` | StorageOS API Manager container image repository |
`cluster.images.apiManager.tag` | StorageOS API Manager container image tag |
`cluster.images.csiV1ExternalAttacherV3.repository` | CSI v1 External Attacher v3 image repository |
`cluster.images.csiV1ExternalAttacherV3.tag` | CSI v1 External Attacher v3 image tag |
`cluster.images.csiV1ExternalProvisioner.repository` | CSI v1 External Provisioner image repository |
`cluster.images.csiV1ExternalProvisioner.tag` | CSI v1 External Provisioner image tag |
`cluster.images.csiV1ExternalResizer.repository` | CSI v1 External Resizer image repository |
`cluster.images.csiV1ExternalResizer.tag` | CSI v1 External Resizer image tag |
`cluster.images.csiV1LivenessProbe.repository` | CSI v1 Liveness Probe image repository |
`cluster.images.csiV1LivenessProbe.tag` | CSI v1 Liveness Probe image tag |
`cluster.images.csiV1NodeDriverRegistrar.repository` | CSI v1 Node Driver Registrar image repository |
`cluster.images.csiV1NodeDriverRegistrar.tag` | CSI v1 Node Driver Registrar image tag |
`cluster.images.init.repository` | StorageOS init container image repository |
`cluster.images.init.tag` | StorageOS init container image tag |
`cluster.images.node.repository` | StorageOS Node container image repository |
`cluster.images.node.tag` | StorageOS Node container image tag |

## Deleting a StorageOS Cluster

Deleting the `StorageOSCluster` custom resource object would delete the
storageos cluster and its associated resources.

In the above example,

```console
$ kubectl delete storageoscluster example-storageos --namespace <storageos-cluster-namespace>
```

would delete the custom resource and the cluster.

## Uninstalling the Chart

To uninstall/delete the storageos cluster operator deployment:

```console
$ helm uninstall <release-name> --namespace ondat-operator
```

If the chart was installed with cluster auto-provisioning enabled, chart
uninstall will clean-up the installed StorageOS cluster resources as well.

Learn more about configuring the StorageOS Operator on
[GitHub](https://github.com/storageos/operator).
