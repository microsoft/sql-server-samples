# Deploy BDC in private AKS cluster with Advanced Networking (CNI)

SQL Server Big Data Clusters allow you to deploy scalable clusters of SQL Server, Spark, and HDFS containers running on Kubernetes, it allows you to easily combine and analyze your high-value relational data with high-volume big data.

This repository contains the scripts that you can use to deploy a BDC cluster in Azure Kubernetes Service (AKS) private cluster with advanced networking ( CNI ).

This repository contains 3 bash scripts :
- **deploy-private-aks.sh** : You can use it to deploy private AKS cluster with private endpoint, it fits the use case that you need to deploy BDC with AKS private cluster.

- **deploy-private-aks-udr.sh** : You can use it to deploy private AKS cluster with private endpoint, it fits the use case that you need to deploy BDC with AKS private cluster and limit egress traffic with UDR ( User-defined Routes ).

- **deploy-bdc.sh** : You can use it to deploy Big Data Clusters ( BDC ) in private deployment mode on private AKS cluster with or without user-defined routes based on your project requirements.  **Note** : Please use this scripts in the Azure VM or Azure Bastion instance which manages your AKS private cluster.


## Prerequisites

You can run those scripts on the following client environment with Linux OS or WSL/WSL2.

The following link listed common big data cluster tools and how to install them:

https://docs.microsoft.com/en-us/sql/big-data-cluster/deploy-big-data-tools?view=sql-server-ver15


## Instructions

### deploy-private-aks.sh

1. Download the script on the location that you are planning to use for the deployment

``` bash
curl --output deploy-private-aks.sh https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/features/sql-big-data-cluster/deployment/private-aks/scripts/deploy-private-aks.sh
```

2. Make the script executable

``` bash
chmod +x deploy-private-aks.sh
```

3. Run the script (make sure you are running with sudo)

``` bash
sudo ./deploy-private-aks.sh
```

### deploy-private-aks-udr.sh

1. Download the script on the location that you are planning to use for the deployment

``` bash
curl --output deploy-private-aks-udr.sh https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/features/sql-big-data-cluster/deployment/private-aks/scripts/deploy-private-aks-udr.sh
```

2. Make the script executable

``` bash
chmod +x deploy-private-aks-udr.sh
```

3. Run the script (make sure you are running with sudo)

``` bash
sudo ./deploy-private-aks-udr.sh
```

### deploy-bdc.sh


1. Download the script on the location that you are planning to use for the deployment

``` bash
curl --output deploy-bdc.sh https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/features/sql-big-data-cluster/deployment/private-aks/scripts/deploy-bdc.sh
```

2. Make the script executable

``` bash
chmod +x deploy-bdc.sh
```

3. Run the script (make sure you are running with sudo)

``` bash
sudo ./deploy-bdc.sh
```

