#!/bin/bash
#Define a set of environment variables to be used in resource creations.
#

#!/bin/bash
#Get Subscription ID and resource groups. It is used as default for controller, SQL Server Master instance (sa account) and Knox.
#

read -p "Your Azure Subscription: " subscription
echo
read -p "Your Resource Group Name: " resourcegroup
echo
read -p "In which region you're deploying: " region
echo


#Define a set of environment variables to be used in resource creations.
export SUBID=$subscription

export REGION_NAME=$region
export RESOURCE_GROUP=$resourcegroup
export KUBERNETES_VERSION=$version
export AKS_NAME=bdcakscluster
 
#Set Azure subscription current in use
az account set --subscription $subscription

#Create Azure Resource Group
az group create -n $RESOURCE_GROUP -l $REGION_NAME
 
#Create AKS Cluster
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --kubernetes-version $version \
    --node-vm-size Standard_D13_v2 \
    --node-count 2 \
    --generate-ssh-keys

az aks get-credentials -g $RESOURCE_GROUP -n $AKS_NAME