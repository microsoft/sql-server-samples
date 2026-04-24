#!/bin/bash

#Get password as input. It is used as default for controller, SQL Server Master instance (sa account) and Knox.
#

while true; do
    read -p "Create Admin username for Big Data Cluster: " bdcadmin
    echo
    read -s -p "Create Password for Big Data Cluster: " password
    echo
    read -s -p "Confirm your Password: " password2
    echo
    [ "$password" = "$password2" ] && break
    echo "Password mismatch. Please try again."
done


#Create BDC custom profile
azdata bdc config init --source aks-dev-test --target bdc-aks --force

#Configurations for BDC deployment
azdata bdc config replace -p private-bdc-aks/control.json -j "$.spec.docker.imageTag=2019-CU13-ubuntu-20.04"
azdata bdc config replace -p private-bdc-aks/control.json -j "$.spec.storage.data.className=default"
azdata bdc config replace -p private-bdc-aks/control.json -j "$.spec.storage.logs.className=default"


azdata bdc create --config-profile bdc-aks --accept-eula yes

#Login and get endpoint list for the cluster.
#
azdata login -n mssql-cluster

azdata bdc endpoint list --output table
