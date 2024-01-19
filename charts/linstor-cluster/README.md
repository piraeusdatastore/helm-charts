# LinstorCluster and LinstorSattelitConfig

Deploy the LinstorCluster and LinstorSattelitConfig via helm chart

## Usage

First, ensure you have Piraeus Operator installed

Then install this chart:

```
helm repo add piraeus-charts https://piraeus.io/helm-charts/
helm install linstor-cluster piraeus-charts/linstor-cluster
```

Check out the available options:

```
helm show values piraeus-charts/linstor-cluster
```
