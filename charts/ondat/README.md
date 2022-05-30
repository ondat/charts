# ondat Helm Chart

Ondat is a Helm chart that includes an [etcd](https://etcd.io)
installation alongside the [Ondat](https://ondat.io) Kubernetes storage solution.

It uses two sub-charts:

- [etcd-cluster-operator](https://github.com/ondat/charts/tree/main/charts/etcd-cluster-operator)
for automated installation and management of an etcd cluster
- [ondat-operator](https://github.com/ondat/charts/tree/main/charts/ondat-operator)
for automated installation and management of Ondat

For more information on Ondat, visit [Ondat.io](https://ondat.io) or refer to
the operator helm chart linked above.

## Prerequisites

- Helm 3
- Kubernetes 1.18+

## Installing the chart

First, customise `values.yaml` or prepare to pass in appropriate parameters to
`helm install` for configuration. Though the default values will work for a basic
installation, we recommend that you at least change the default username/password
for API access and the etcd StorageClass.

Documentation on StorageClasses is available [here](https://kubernetes.io/docs/concepts/storage/storage-classes/).

To deploy Ondat with default settings, use:

```console
# Add ondat charts repo.
$ helm repo add ondat https://ondat.github.io/charts
# Install the chart in a namespace
$ kubectl create namespace ondat
$ helm install ondat ondat/ondat \
    --namespace ondat
```

Or, alternatively, with a custom `values.yaml` file:

```console
$ helm install ondat/ondat \
    --namespace ondat \
    --values <values-file>
```
> **Tip**: List all releases using `helm list -A`

All options in the sub-charts can be adjusted - see the etcd and Ondat operator
charts listed above for more information.

This will install the Ondat and etcd operators within the `ondat` namespace
in a default configuration.
The operators will automatically create the etcd and Ondat clusters.

To monitor the progress of cluster creation, use:

```shell
kubectl get po -n storageos-etcd -w
# < CTRL > + C to exit when all pods are Ready
kubectl get po -n storageos -w
# < CTRL > + C to exit when all pods are Ready
```

Note that some pods depend on others and will initially fail to start. An
example of this is the Ondat node pods that depend on etcd being available.
Until etcd is available, they may show an 'Error' status but Kubernetes
will restart them automatically until they are up and running. It will take
around 5 minutes until the cluster is ready for new volumes.

A properly running cluster with three nodes looks like:

```shell
$ kubectl get po -n ondat
NAME                                        READY   STATUS    RESTARTS   AGE
ondat-controller-manager-854d87db6f-6bl5r   1/1     Running   0          5m27s
ondat-ondat-operator-7c68bb968-5ntsn        2/2     Running   0          5m27s
ondat-proxy-59bd66965f-q2xz7                1/1     Running   0          5m27s
$ kubectl get po -n storageos-etcd
NAME                     READY   STATUS    RESTARTS   AGE
storageos-etcd-0-hcsfs   1/1     Running   0          6m36s
storageos-etcd-1-49z7r   1/1     Running   0          6m33s
storageos-etcd-2-ft9w4   1/1     Running   0          6m29s
$ kubectl get po -n storageos
NAME                                    READY   STATUS    RESTARTS   AGE
storageos-api-manager-89776bf5d-dczqr   1/1     Running   1          4m32s
storageos-api-manager-89776bf5d-lztgb   1/1     Running   0          4m32s
storageos-csi-helper-65db657d7c-hj9bw   3/3     Running   0          4m33s
storageos-node-8cpct                    3/3     Running   3          5m46s
storageos-node-cdp9q                    3/3     Running   3          5m46s
storageos-node-h4npw                    3/3     Running   3          5m46s
storageos-scheduler-5ddc468b54-67xsm    1/1     Running   0          5m55s
```

When the cluster is fully up and running, you can now install the
CLI in order to check health status.

```shell
$ kubectl -n storageos create -f-<<END
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storageos-cli
  namespace: storageos
  labels:
    app: storageos
    run: cli
spec:
  replicas: 1
  selector:
    matchLabels:
      app: storageos-cli
      run: cli
  template:
    metadata:
      labels:
        app: storageos-cli
        run: cli
    spec:
      containers:
      - command:
        - /bin/sh
        - -c
        - "while true; do sleep 3600; done"
        env:
        - name: STORAGEOS_ENDPOINTS
          value: http://storageos:5705
        - name: STORAGEOS_USERNAME
          value: storageos
        - name: STORAGEOS_PASSWORD
          value: storageos
        image: storageos/cli:v2.5.0
        name: cli
END
```

Once the pod is launched, set a variable to refer to the current CLI pod for
convenience and check the clusterID and health of the cluster:

```shell
$ POD=$(kubectl -n storageos get pod -ocustom-columns=_:.metadata.name --no-headers -lapp=storageos-cli)
$ kubectl -n storageos exec $POD -- storageos get cluster
ID:           704dd165-9580-4da4-a554-0acb96d328cb
Created at:   2022-01-10T13:58:00Z (2 weeks ago)
Updated at:   2022-01-10T14:05:27Z (2 weeks ago)
Nodes:        3
  Healthy:    3
  Unhealthy:  0
```

Take a note of the Cluster ID and ensure that all nodes are healthy.
The first step in a new cluster is to license it, even if you intend to use
our free community edition - see [our documentation](https://docs.ondat.io/docs/operations/licensing/)
for full details.

We recommend familiarising yourself with the Ondat feature set - our
documentation has sections for [Concepts](https://docs.ondat.io/docs/concepts/)
and [Operations](https://docs.ondat.io/docs/operations/) that will help to answer
any questions you may have.

From there, see [our self-evaluation guide](https://docs.ondat.io/docs/introduction/self-eval/#provision-an-ondat-volume)
to run some basic functional tests and benchmarks or [use cases](https://docs.ondat.io/docs/usecases/)
for examples of running Ondat with different applications.

We'd also suggest joining our community
[Slack](https://slack.storageos.com/?__hstc=194682738.f2cc24d4e0397989c5891c18138328f0.1651239332232.1653648751454.1653658610921.16&__hssc=194682738.32.1653658610921&__hsfp=711141870),
we hope to see you there soon!
.

## Configuration

The following tables lists the configurable parameters of the
chart and their default values.

Parameter | Description | Default
--------- | ----------- | -------
`ondat-operator.*` | Customize settings for the Ondat operator | See [`values.yaml`](https://github.com/ondat/charts/blob/main/charts/ondat/values.yaml) and [`values.yaml` from subchart](https://github.com/ondat/charts/blob/main/charts/ondat-operator/values.yaml)
`etcd-cluster-operator.*` | Customize settings for the etcd operator | See [`values.yaml`](https://github.com/ondat/charts/blob/main/charts/ondat/values.yaml) and [`values.yaml` from subchart](https://github.com/ondat/charts/blob/main/charts/etcd-cluster-operator/values.yaml)

## Uninstalling the Chart

To uninstall/delete the etcd cluster operator deployment:

```console
$ helm uninstall <release-name> --namespace ondat
```
