#!/bin/bash
#Get Subscription ID and Azure service principal as input. It is used as default for controller, SQL Server Master instance (sa account) and Knox.
##
#You can also create service principal instead of using an existing one
#az ad sp create-for-rbac -n "bdcaks-sp" --skip-assignment
#
read -p "Your Azure Subscription: " subscription
echo
read -p "Your Resource Group Name: " resourcegroup
echo
read -p "In which region you're deploying: " region
echo
read -p "Your Azure service principal ID: " sp_id
echo
read -p "Your Azure service principal Password: " sp_pwd


#Define a set of environment variables to be used in resource creations.
export SUBID=$subscription

export REGION_NAME=$region
export RESOURCE_GROUP=$resourcegroup
export SUBNET_NAME=aks-subnet
export VNET_NAME=bdc-vnet
export AKS_NAME=bdcaksprivatecluster
export FWNAME=bdcaksazfw
export FWPUBIP=$FWNAME-ip
export FWIPCONFIG_NAME=$FWNAME-config

export FWROUTE_TABLE_NAME=bdcaks-rt
export FWROUTE_NAME=bdcaksroute
export FWROUTE_NAME_INTERNET=bdcaksrouteinet

#Set Azure subscription current in use
az account set --subscription $subscription

#Create Azure Resource Group
az group create -n $RESOURCE_GROUP -l $REGION_NAME
 
#Create Azure Virtual Network to host your AKS cluster
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


#Add Azure firewall extension
az extension add --name azure-firewall

#Dedicated subnet for Azure Firewall (Firewall name cannot be changed)
az network vnet subnet create \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --name AzureFirewallSubnet \
    --address-prefix 10.3.0.0/24

#Create Azure firewall 
az network firewall create -g $RESOURCE_GROUP -n $FWNAME -l $REGION_NAME --enable-dns-proxy true

#Create public IP for Azure Firewall 
az network public-ip create -g $RESOURCE_GROUP -n $FWPUBIP -l $REGION_NAME --sku "Standard"

#Create IP configurations for Azure Firewall 
az network firewall ip-config create -g $RESOURCE_GROUP -f $FWNAME -n $FWIPCONFIG_NAME --public-ip-address $FWPUBIP --vnet-name $VNET_NAME


#Getting public and private IP addresses for Azure Firewall 
export FWPUBLIC_IP=$(az network public-ip show -g $RESOURCE_GROUP -n $FWPUBIP --query "ipAddress" -o tsv)
export FWPRIVATE_IP=$(az network firewall show -g $RESOURCE_GROUP -n $FWNAME --query "ipConfigurations[0].privateIpAddress" -o tsv)

#Create an User defined route table
az network route-table create -g $RESOURCE_GROUP --name $FWROUTE_TABLE_NAME

#Create User defined routes 
az network route-table route create -g $RESOURCE_GROUP --name $FWROUTE_NAME --route-table-name $FWROUTE_TABLE_NAME --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $FWPRIVATE_IP --subscription $SUBID

az network route-table route create -g $RESOURCE_GROUP --name $FWROUTE_NAME_INTERNET --route-table-name $FWROUTE_TABLE_NAME --address-prefix $FWPUBLIC_IP/32 --next-hop-type Internet


#Add FW Network Rules
az network firewall network-rule create -g $RESOURCE_GROUP -f $FWNAME --collection-name 'aksfwnr' -n 'apiudp' --protocols 'UDP' --source-addresses '*' --destination-addresses "AzureCloud.$REGION_NAME" --destination-ports 1194 --action allow --priority 100
az network firewall network-rule create -g $RESOURCE_GROUP -f $FWNAME --collection-name 'aksfwnr' -n 'apitcp' --protocols 'TCP' --source-addresses '*' --destination-addresses "AzureCloud.$REGION_NAME" --destination-ports 9000
az network firewall network-rule create -g $RESOURCE_GROUP -f $FWNAME --collection-name 'aksfwnr' -n 'time' --protocols 'UDP' --source-addresses '*' --destination-fqdns 'ntp.ubuntu.com' --destination-ports 123

#Add FW Application Rules
az network firewall application-rule create -g $RESOURCE_GROUP -f $FWNAME --collection-name 'aksfwar' -n 'fqdn' --source-addresses '*' --protocols 'http=80' 'https=443' --fqdn-tags "AzureKubernetesService" --action allow --priority 100

#Associate User defined route table (UDR) to AKS cluster where deployed BDC previsouly 
az network vnet subnet update -g $RESOURCE_GROUP --vnet-name $VNET_NAME --name $SUBNET_NAME --route-table $FWROUTE_TABLE_NAME





#Create SP and Assign Permission to Virtual Network
export APPID=$sp_id
export PASSWORD=$sp_pwd
export VNETID=$(az network vnet show -g $RESOURCE_GROUP --name $VNET_NAME --query id -o tsv)

#Assign SP Permission to VNET
az role assignment create --assignee $APPID --scope $VNETID --role "Network Contributor"

#Assign SP Permission to route table
export RTID=$(az network route-table show -g $RESOURCE_GROUP -n $FWROUTE_TABLE_NAME --query id -o tsv)
az role assignment create --assignee $APPID --scope $RTID --role "Network Contributor"


#Create AKS Cluster
az aks create \
    --resource-group $RESOURCE_GROUP \
    --location $REGION_NAME \
    --name $AKS_NAME \
    --load-balancer-sku standard \
    --outbound-type userDefinedRouting \
    --enable-private-cluster \
    --network-plugin azure \
    --vnet-subnet-id $SUBNET_ID \
    --docker-bridge-address 172.17.0.1/16 \
    --dns-service-ip 10.2.0.10 \
    --service-cidr 10.2.0.0/24 \
    --service-principal $APPID \
    --client-secret $PASSWORD \
    --node-vm-size Standard_D13_v2 \
    --node-count 2 \
    --generate-ssh-keys


az aks get-credentials -g $RESOURCE_GROUP -n $AKS_NAME
