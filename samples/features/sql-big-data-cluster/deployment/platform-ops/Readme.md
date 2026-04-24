# Deploy BDC on Azure Kubernetes Service cluster

SQL Server Big Data Clusters allow you to deploy scalable clusters of SQL Server, Spark, and HDFS containers running on Kubernetes, it allows you to easily combine and analyze your high-value relational data with high-volume big data.

This repository contains the scripts that you can use to deploy a BDC cluster on Azure Kubernetes Service (AKS)  cluster with basic networking ( Kubenet ) and advanced networking ( CNI ).

This repository contains 3 bash scripts :
- **deploy-cni-aks.sh** : You can use it to deploy AKS cluster using CNI networking, it fits the use case that you need to deploy BDC with AKS cluster with CNI networking plugin for integration with existing virtual networks in Azure, and this network model allows greater separation of resources and controls in an enterprise environment.

- **deploy-kubenet-aks.sh** : You can use it to deploy AKS cluster using kubenet networking, it fits the use case that you need to deploy BDC with AKS cluster with kubenet networking. Kubenet is a basic network plugin, on Linux only. AKS cluster by default is on kubenet networking, after provisioning it, it also creates an Azure virtual network and a subnet, where your nodes get an IP address from the subnet and all pods receive an IP address from a logically different address space to the subnet of the nodes.

- **deploy-bdc.sh** : You can use it to deploy Big Data Clusters ( BDC ) AKS cluster. Please find the inline comments about the deployment steps and configurations which allows your customization.

## Above all

SQL Server Big Data Clusters is a fully containerized solution orchestrated by Kubernetes. Starting with CU12, each release of SQL Server Big Data Clusters is tested against a fixed configuration of components. The configuration is evaluated with each release and adjustments are made to stay in-line with the ecosystem as Kubernetes continues to evolve. Further information see [Tested Configurations from SQL Server Big Data Clusters platform release notes](https://docs.microsoft.com/en-us/sql/big-data-cluster/release-notes-big-data-cluster?view=sql-server-ver15#tested-configurations).

Please note that a no later than 1.13 version for Kubernetes server to deploy your big data clusters. Therefore you need to use --kubernetes-version parameter to specify a version different than the default for AKS.

## Prerequisites

You can run those scripts on the following client environment with Linux OS or WSL/WSL2.

The following link listed common big data cluster tools and how to install them:

https://docs.microsoft.com/en-us/sql/big-data-cluster/deploy-big-data-tools?view=sql-server-ver15


## Instructions

### deploy-cni-aks.sh

1. Download the script on the location that you are planning to use for the deployment

``` bash
curl --output deploy-cni-aks.sh https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/features/sql-big-data-cluster/deployment/platform-ops/scripts/deploy-cni-aks.sh
```

2. Make the script executable

``` bash
chmod +x deploy-cni-aks.sh
```

3. Run the script (make sure you are running with sudo)

``` bash
sudo ./deploy-cni-aks.sh
```

### deploy-kubenet-aks.sh

1. Download the script on the location that you are planning to use for the deployment

``` bash
curl --output deploy-kubenet-aks.sh https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/features/sql-big-data-cluster/deployment/platform-ops/scripts/deploy-kubenet-aks.sh
```

2. Make the script executable

``` bash
chmod +x deploy-kubenet-aks.sh
```

3. Run the script (make sure you are running with sudo)

``` bash
sudo ./deploy-kubenet-aks.sh
```

### deploy-bdc-aks.sh


1. Download the script on the location that you are planning to use for the deployment

``` bash
curl --output deploy-bdc-aks.sh https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/features/sql-big-data-cluster/deployment/platform-ops/scripts/deploy-bdc-aks.sh
```

2. Make the script executable

``` bash
chmod +x deploy-bdc-aks.sh
```

3. Run the script (make sure you are running with sudo)

``` bash
sudo ./deploy-bdc-aks.sh
```

