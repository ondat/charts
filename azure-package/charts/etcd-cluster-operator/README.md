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
$ kubectl create namespace etcd-operator
$ helm install storageos-etcd ondat/etcd-cluster-operator \
    --namespace etcd-operator
```

This will install the Etcd cluster operator in `etcd-cluster-operator`
namespace and deploys Etcd with a minimal configuration.

```console
$ helm install ondat/etcd-cluster-operator \
    --namespace etcd-operator \
    --values <values-file>
```
> **Tip**: List all releases using `helm list -A`

## Configuration

The following tables lists the configurable parameters of the
Operator chart and their default values.

Parameter | Description | Default
--------- | ----------- | -------
`cluster.create` | If true, auto-create the Etcd cluster | `true`

## Deleting an Etcd Cluster

Deleting the `EtcdCluster` custom resource object would delete the
etcd cluster and its associated resources.

In the above example,

```console
$ kubectl delete etcdcluster storageos-etcd --namespace storageos-etcd
```

would delete the custom resource and the cluster.

## Uninstalling the Chart

To uninstall/delete the etcd cluster operator deployment:

```console
$ helm uninstall <release-name> --namespace etcd-operator
```
