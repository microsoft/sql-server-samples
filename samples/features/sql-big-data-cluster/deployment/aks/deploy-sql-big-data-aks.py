#
# Prerequisites: 
# 
# Azure CLI (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli), python3 (https://www.python.org/downloads), azdata CLI (pip3 install -r https://aka.ms/azdata)
#
# Run `az login` at least once BEFORE running this script
#

from subprocess import check_output, CalledProcessError, STDOUT, Popen, PIPE, getoutput
from time import sleep
import os
import getpass
import json

def executeCmd (cmd):
    if os.name=="nt":
        process = Popen(cmd.split(),stdin=PIPE, shell=True)
    else:
        process = Popen(cmd.split(),stdin=PIPE)
    stdout, stderr = process.communicate()
    if (stderr is not None):
        raise Exception(stderr)

#
# MUST INPUT THESE VALUES!!!!!
#
SUBSCRIPTION_ID = input("Provide your Azure subscription ID:").strip()
GROUP_NAME = input("Provide Azure resource group name to be created:").strip()
# Use this only if you are using a private registry different than default Micrososft registry (mcr). 
#DOCKER_USERNAME = input("Provide your Docker username:").strip()
#DOCKER_PASSWORD  = getpass.getpass("Provide your Docker password:").strip()

#
# Optionally change these configuration settings
#
AZURE_REGION=input("Provide Azure region - Press ENTER for using `westus`:").strip() or "westus"
VM_SIZE=input("Provide VM size for the AKS cluster - Press ENTER for using  `Standard_L8s`:").strip() or "Standard_L8s"
AKS_NODE_COUNT=input("Provide number of worker nodes for AKS cluster - Press ENTER for using  `1`:").strip() or "1"

#This is both Kubernetes cluster name and SQL Big Data cluster name
CLUSTER_NAME=input("Provide name of AKS cluster and SQL big data cluster - Press ENTER for using  `sqlbigdata`:").strip() or "sqlbigdata"

#This password will be use for Controller user, Knox user and SQL Server Master SA accounts
# 
AZDATA_USERNAME=input("Provide username to be used for Controller and SQL Server master accounts - Press ENTER for using  `admin`:").strip() or "admin"
AZDATA_PASSWORD = getpass.getpass("Provide password to be used for Controller user, Knox user (root) and SQL Server Master accounts - Press ENTER for using  `MySQLBigData2019`").strip() or "MySQLBigData2019"

# Docker registry details
# Use this only if you are using a private registry different than mcr. If so, make sure you are also setting the environment variables for DOCKER_USERNAME and DOCKER_PASSWORD
# DOCKER_REGISTRY="<your private registry>"
# DOCKER_REPOSITORY="<your private repository>"
# DOCKER_IMAGE_TAG="<your Docker image tag>"

print ('Setting environment variables')
os.environ['AZDATA_PASSWORD'] = AZDATA_PASSWORD
os.environ['AZDATA_USERNAME'] = AZDATA_USERNAME
# Use this only if you are using a private registry different than mcr. If so, you must set the environment variables for DOCKER_USERNAME and DOCKER_PASSWORD
# os.environ['DOCKER_USERNAME']=DOCKER_USERNAME
# os.environ['DOCKER_PASSWORD']=DOCKER_PASSWORD
os.environ['ACCEPT_EULA']="Yes"

print ("Set azure context to subscription: "+SUBSCRIPTION_ID)
command = "az account set -s "+ SUBSCRIPTION_ID
executeCmd (command)

print ("Creating azure resource group: "+GROUP_NAME)
command="az group create --name "+GROUP_NAME+" --location "+AZURE_REGION
executeCmd (command)

SP_NAME = AZURE_REGION + '_' + GROUP_NAME + '_' + CLUSTER_NAME
print ("Creating Service Principal: "+SP_NAME)
command = "az ad sp create-for-rbac --skip-assignment --name http://" + SP_NAME
SP_RESULT=getoutput(command)
SP_JSON = json.loads(SP_RESULT[SP_RESULT.find("{"):])
SP_PRINCIPAL = (SP_JSON['appId'])
SP_PW = (SP_JSON['password'])

# Waiting for 10 seconds for the SP to sync
sleep(10)

print("Creating AKS cluster: "+CLUSTER_NAME)
command = "az aks create --name "+CLUSTER_NAME+" --resource-group "+GROUP_NAME+" --generate-ssh-keys --node-vm-size "+VM_SIZE+" --node-count "+AKS_NODE_COUNT+ " --service-principal " + SP_PRINCIPAL + " --client-secret " + SP_PW
executeCmd (command)

command = "az aks get-credentials --overwrite-existing --name "+CLUSTER_NAME+" --resource-group "+GROUP_NAME+" --admin"
executeCmd (command)

print("Creating SQL Big Data cluster:" +CLUSTER_NAME)
command="azdata bdc config init --source aks-dev-test --target custom --force"
executeCmd (command)

command="azdata bdc config replace -c custom/bdc.json -j ""metadata.name=" + CLUSTER_NAME + ""
executeCmd (command)

# Use this only if you are using a private registry different than default Micrososft registry (mcr). 
# command="azdata bdc config replace -c custom/control.json -j ""$.spec.controlPlane.spec.docker.registry=" + DOCKER_REGISTRY + ""
# executeCmd (command)

# command="azdata bdc config replace -c custom/control.json -j ""$.spec.controlPlane.spec.docker.repository=" + DOCKER_REPOSITORY + ""
# executeCmd (command)

# command="azdata bdc config replace -c custom/control.json -j ""$.spec.controlPlane.spec.docker.imageTag=" + DOCKER_IMAGE_TAG + ""
# executeCmd (command)

command="azdata bdc create -c custom --accept-eula yes"
executeCmd (command)

command="azdata login -n " + CLUSTER_NAME
executeCmd (command)

print("")
print("SQL Server big data cluster endpoints: ")
command="azdata bdc endpoint list -o table"
executeCmd(command)

