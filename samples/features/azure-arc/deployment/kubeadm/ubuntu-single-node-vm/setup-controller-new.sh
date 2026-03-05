#!/bin/bash

# Prompt for private preview repository username and password provided by Microsoft
#
if [ -z "$DOCKER_USERNAME" ]
then
    read -p 'Enter Azure Arc Data Controller repo username provided by Microsoft:' AADC_USERNAME
    echo
    export DOCKER_USERNAME=$AADC_USERNAME
fi
if [ -z "$DOCKER_PASSWORD" ]
then
    read -sp 'Enter Azure Arc Data Controller repo password provided by Microsoft:' AADC_PASSWORD
    echo
    export DOCKER_PASSWORD=$AADC_PASSWORD
fi


# Propmpt for Arc Data Controller properties.
#
if [ -z "$ARC_DC_NAME" ]
then
    read -p "Enter a name for the new Azure Arc Data Controller: " dc_name
    echo
    export ARC_DC_NAME=$dc_name
fi

if [ -z "$ARC_DC_SUBSCRIPTION" ]
then
    read -p "Enter a subscription ID for the new Azure Arc Data Controller: " dc_subscription
    echo
    export ARC_DC_SUBSCRIPTION=$dc_subscription
fi

if [ -z "$ARC_DC_RG" ]
then
    read -p "Enter a resource group for the new Azure Arc Data Controller: " dc_rg
    echo
    export ARC_DC_RG=$dc_rg
fi

if [ -z "$ARC_DC_REGION" ]
then
    read -p "Enter a region for the new Azure Arc Data Controller (eastus, eastus2, centralus, westus2, westeurope, southeastasia, japaneast, australiaeast, koreacentral, northeurope, uksouth, or francecentral): " dc_region
    echo
    export ARC_DC_REGION=$dc_region
fi

# Get controller username and password as input. It is used as default for the controller.
#
if [ -z "$AZDATA_USERNAME" ]
then
    read -p "Create Username for Azure Arc Data Controller: " username
    echo
    export AZDATA_USERNAME=$username
fi
if [ -z "$AZDATA_PASSWORD" ]
then
    while true; do
        read -s -p "Create Password for Azure Arc Data Controller: " password
        echo
        read -s -p "Confirm your Password: " password2
        echo
        [ "$password" = "$password2" ] && break
        echo "Password mismatch. Please try again."
    done
    export AZDATA_PASSWORD=$password
fi

set -Eeuo pipefail

# This is a script to create single-node Kubernetes cluster and deploy Azure Arc Data Controller on it.
#
export AZUREARCDATACONTROLLER_DIR=arc-data

# Name of virtualenv variable used.
#
export LOG_FILE="arc-data-controller.log"
export DEBIAN_FRONTEND=noninteractive

# Requirements file.
export OSCODENAME=$(lsb_release -cs)
export AZDATA_PRIVATE_PREVIEW_DEB_PACKAGE="https://aka.ms/aug-2020-arc-azdata-$OSCODENAME"

# Kube version.
#
KUBE_DPKG_VERSION=1.16.3-00
KUBE_VERSION=1.16.3

# Wait for 5 minutes for the cluster to be ready.
#
TIMEOUT=600
RETRY_INTERVAL=5

# Variables used for azdata cluster creation.
#
export ACCEPT_EULA=yes
export CLUSTER_NAME=arc
export PV_COUNT="100"

# Make a directory for installing the scripts and logs.
#
rm -f -r $AZUREARCDATACONTROLLER_DIR
mkdir -p $AZUREARCDATACONTROLLER_DIR
cd $AZUREARCDATACONTROLLER_DIR/
touch $LOG_FILE

{
# Install all necessary packages: kuberenetes, docker, request, azdata.
#
echo ""
echo "######################################################################################"
echo "Starting installing packages..." 

# Install docker.
#
sudo apt-get update -q

sudo apt --yes install \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    curl

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt update -q
sudo apt-get install -q --yes docker-ce=18.06.2~ce~3-0~ubuntu --allow-downgrades
sudo apt-mark hold docker-ce

sudo usermod --append --groups docker $USER

# Create working directory
#
rm -f -r setupscript
mkdir -p setupscript
cd setupscript/

# Download and install azdata prerequisites
#
sudo apt install -y libodbc1 odbcinst odbcinst1debian2 unixodbc apt-transport-https libkrb5-dev

# Download and install azdata package
#
echo ""

if [[ -v AZDATA_DEB_PACKAGE_PATH ]]; then
  sudo dpkg -i $AZDATA_DEB_PACKAGE_PATH
elif [[ -v AZDATA_DEB_PACKAGE_URL ]]; then
  echo "Downloading azdata installer from" $AZDATA_DEB_PACKAGE_URL 
  curl --location $AZDATA_DEB_PACKAGE_URL --output azdata_setup.deb
  sudo dpkg -i azdata_setup.deb
else
  echo "Downloading azdata installer from" $AZDATA_PRIVATE_PREVIEW_DEB_PACKAGE 
  curl --location $AZDATA_PRIVATE_PREVIEW_DEB_PACKAGE --output azdata_setup.deb
  sudo dpkg -i azdata_setup.deb
fi

cd -

azdata --version
echo "Azdata has been successfully installed."

# Install Azure CLI
#
#curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Load all pre-requisites for Kubernetes.
#
echo "###########################################################################"
echo "Starting to setup pre-requisites for kubernetes..." 

# Setup the kubernetes preprequisites.
#
sudo swapoff -a
sudo sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list

deb http://apt.kubernetes.io/ kubernetes-xenial main

EOF

# Install docker and packages to allow apt to use a repository over HTTPS.
#
sudo apt-get update -q

sudo apt-get install -q -y ebtables ethtool

#apt-get install -y docker.ce

sudo apt-get install -q -y apt-transport-https

# Setup daemon.
#
sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
#
sudo systemctl daemon-reload
sudo systemctl restart docker

sudo apt-get install -q -y kubelet=$KUBE_DPKG_VERSION kubeadm=$KUBE_DPKG_VERSION kubectl=$KUBE_DPKG_VERSION

# Holding the version of kube packages.
#
sudo apt-mark hold kubelet kubeadm kubectl
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | sudo bash

. /etc/os-release
if [ "$UBUNTU_CODENAME" == "bionic" ]; then
    modprobe br_netfilter
fi

# Disable Ipv6 for cluster endpoints.
#
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1

echo net.ipv6.conf.all.disable_ipv6=1 | sudo tee -a /etc/sysctl.conf
echo net.ipv6.conf.default.disable_ipv6=1 | sudo tee -a /etc/sysctl.conf
echo net.ipv6.conf.lo.disable_ipv6=1 | sudo tee -a /etc/sysctl.conf


sudo sysctl net.bridge.bridge-nf-call-iptables=1

# Setting up the persistent volumes for the kubernetes.
#
for i in $(seq 1 $PV_COUNT); do

  vol="vol$i"

  sudo mkdir -p /azurearc/local-storage/$vol

  sudo mount --bind /azurearc/local-storage/$vol /azurearc/local-storage/$vol

done
echo "Kubernetes pre-requisites have been completed." 

# Setup kubernetes cluster including remove taint on master.
#
echo ""
echo "#############################################################################"
echo "Starting to setup Kubernetes master..." 

# Initialize a kubernetes cluster on the current node.
#
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=$KUBE_VERSION

mkdir -p $HOME/.kube

sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u $USER):$(id -g $USER) $HOME/.kube/config

# To enable a single node cluster remove the taint that limits the first node to master only service.
#
master_node=`kubectl get nodes --no-headers=true --output=custom-columns=NAME:.metadata.name`
kubectl taint nodes ${master_node} node-role.kubernetes.io/master:NoSchedule-

# Local storage provisioning.
#
kubectl apply -f https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/features/azure-arc/deployment/kubeadm/ubuntu/local-storage-provisioner.yaml

# Set local-storage as the default storage class
#
kubectl patch storageclass local-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Install the software defined network.
#
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# helm init
#
kubectl apply -f https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/features/azure-arc/deployment/kubeadm/ubuntu/rbac.yaml

# Verify that the cluster is ready to be used.
#
echo "Verifying that the cluster is ready for use..."
while true ; do

    if [[ "$TIMEOUT" -le 0 ]]; then
        echo "Cluster node failed to reach the 'Ready' state. Kubeadm setup failed."
        exit 1
    fi

    status=`kubectl get nodes --no-headers=true | awk '{print $2}'`

    if [ "$status" == "Ready" ]; then
        break
    fi

    sleep "$RETRY_INTERVAL"

    TIMEOUT=$(($TIMEOUT-$RETRY_INTERVAL))

    echo "Cluster not ready. Retrying..."
done


# Install the dashboard for Kubernetes.
#
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml

kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
echo "Kubernetes master setup done."

# Deploy azdata Azure Arc Data Cotnroller create cluster.
#
echo ""
echo "############################################################################"
echo "Starting to deploy azdata cluster..." 

# Command to create cluster for single node cluster.
#
azdata arc dc config init --source azure-arc-kubeadm --path azure-arc-custom --force

if [[ -v DOCKER_REGISTRY ]]; then
    azdata arc dc config replace --path azure-arc-custom/control.json --json-values '$.spec.docker.registry=$DOCKER_REGISTRY'
fi

if [[ -v DOCKER_REPOSITORY ]]; then
    azdata arc dc config replace --path azure-arc-custom/control.json --json-values '$.spec.docker.repository=$DOCKER_REPOSITORY'
fi

if [[ -v DOCKER_IMAGE_TAG ]]; then
    azdata arc dc config replace --path azure-arc-custom/control.json --json-values '$.spec.docker.imageTag=$DOCKER_IMAGE_TAG'
fi

# azdata arc dc config replace --path azure-arc-custom/control.json --json-values '$.spec.docker.imagePullPolicy=IfNotPresent'
azdata arc dc config replace --path azure-arc-custom/control.json --json-values '$.spec.storage.data.className=local-storage'
azdata arc dc config replace --path azure-arc-custom/control.json --json-values '$.spec.storage.logs.className=local-storage'

azdata arc dc create --name $ARC_DC_NAME --path azure-arc-custom --namespace $CLUSTER_NAME --location $ARC_DC_REGION --resource-group $ARC_DC_RG --subscription $ARC_DC_SUBSCRIPTION --connectivity-mode indirect
echo "Azure Arc Data Controller cluster created." 

# Setting context to cluster.
#
kubectl config set-context --current --namespace $CLUSTER_NAME

# Login and get endpoint list for the cluster.
#
azdata login --namespace $CLUSTER_NAME

echo "Cluster successfully setup. Run 'azdata --help' to see all available options."
}| tee $LOG_FILE
