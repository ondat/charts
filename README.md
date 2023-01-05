# Ondat Helm Charts

This repository hosts the official Ondat Helm Charts.

## Install

Get the latest [Helm release](https://github.com/helm/helm#install).

Add the Ondat chart repo to Helm:

```bash
helm repo add ondat https://ondat.github.io/charts
helm repo update
```

Run `helm search repo ondat` to list the available charts.

## Contribution

Please open a PR with your changes!

Your contribution should:
 - Not modfiy both component- and umbrella-charts.
 - Not release charts (by bumping their version numbers in their
   `Chart.yaml`s). We'll handle that.
