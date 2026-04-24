
# Creating a Kubernetes cluster for SQL Server 2019 big data cluster

SQL Server 2019 big data cluster is deployed as docker containers on a Kubernetes cluster. These samples provide scripts that can be used to provision a Kubernetes clusters using different environments.

## __[Deploy a Kubernetes cluster using kubeadm](kubeadm/)__

Use the scripts in the **kubeadm** folder to deploy a Kubernetes cluster over one or more Linux machines (physical or virtualized) using `kubeadm` utility.

## __[Deploy a SQL Server big data cluster on Azure Kubernetes Service (AKS)](aks/)__

Using the sample Python script in **aks** folder, you will deploy a Kubernetes cluster in Azure using AKS and a SQL Server big data cluster using on top of it.

## __[Push SQL Server big data cluster images to your own private Docker repository](offline/)__

Using the sample Python script in **offline** folder, you will push the necessary images required for the deployment to your own repository.

## __[Deploy SQL Server big data clusters (BDC) with Azure Kubernetes service (AKS) private cluster](private-aks/)__

Using the sample Python script in **private-aks** folder, you will Deploy SQL Server big data cluster in in your private network with Azure Kubernetes service (AKS) private cluster.

## __[OpenShift manifests and scripts](openshift/)__

Use manifests and scripts in **openshift** folder, to support SQL Server Big Data Clusters on OpenShift.