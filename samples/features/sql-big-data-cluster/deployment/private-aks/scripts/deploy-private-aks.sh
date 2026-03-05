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
export SUBNET_NAME=aks-subnet
export VNET_NAME=bdc-vnet
export AKS_NAME=bdcaksprivatecluster
 
#Set Azure subscription current in use
az account set --subscription $subscription

#Create Azure Resource Group
az group create -n $RESOURCE_GROUP -l $REGION_NAME
 
#Create Azure Virtual Network to host your AKS clus
az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --location $REGION_NAME \
    --name $VNET_NAME \
    --address-prefixes 10.0.0.0/8 \
    --subnet-name $SUBNET_NAME \
    --subnet-prefix 10.1.0.0/16

SUBNET_ID=$(az network vnet subnet show \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --name $SUBNET_NAME \
    --query id -o tsv)
 
#Create AKS Cluster
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --load-balancer-sku standard \
    --enable-private-cluster \
    --kubernetes-version $version \
    --network-plugin azure \
    --vnet-subnet-id $SUBNET_ID \
    --docker-bridge-address 172.17.0.1/16 \
    --dns-service-ip 10.2.0.10 \
    --service-cidr 10.2.0.0/24 \
    --node-vm-size Standard_D13_v2 \
    --node-count 2 \
    --generate-ssh-keys

az aks get-credentials -g $RESOURCE_GROUP -n $AKS_NAME
