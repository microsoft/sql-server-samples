#!/bin/bash
set -Eeuo pipefail

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

STARTUP_PATH=$(pwd)

# This is a script to create single-node Kubernetes cluster and deploy BDC on it.
#
export BDCDEPLOY_DIR=bdcdeploy

# Get password as input. It is used as default for controller, SQL Server Master instance (sa account) and Knox.
#
while true; do
    read -s -p "Create Password for Big Data Cluster: " password
    echo
    read -s -p "Confirm Password for Big Data Cluster: " password2
    echo
    [ "$password" = "$password2" ] && break
    echo "Password mismatch. Please try again."
done

echo ""

# Get Domain Service Account Username and Password.
#
read -p "Enter the Domain Service Account Username: " ds_username
export DOMAIN_SERVICE_ACCOUNT_USERNAME=$ds_username

while true; do
    read -s -p "Enter Password for Domain Service Account: " ds_password
    echo
    read -s -p "Confirm your Domain Service Account Password: " ds_password2
    echo
    [ "$ds_password" = "$ds_password2" ] && break
    echo "Password mismatch. Please try again."
done
export DOMAIN_SERVICE_ACCOUNT_PASSWORD=$ds_password
echo ""

# Name of virtualenv variable used.
#
export VIRTUALENV_NAME="bdcvenv"
export LOG_FILE="bdcdeploy.log"
export DEBIAN_FRONTEND=noninteractive

# Kube version.
#
KUBE_DPKG_VERSION=1.20.7-00
KUBE_VERSION=1.20.7

# Wait for 5 minutes for the cluster to be ready.
#
TIMEOUT=600
RETRY_INTERVAL=5

# Variables for pulling dockers.
#
export DOCKER_REGISTRY="mcr.microsoft.com"
export DOCKER_REPOSITORY="mssql/bdc"
export DOCKER_TAG="2019-CU13-ubuntu-20.04"

# Variables used for azdata cluster creation.
#
export AZDATA_USERNAME=admin
export AZDATA_PASSWORD=$password
export ACCEPT_EULA=yes
export CLUSTER_NAME=mssql-cluster
export STORAGE_CLASS=local-storage
export PV_COUNT="30"

IMAGES=(
	    mssql-app-service-proxy
        mssql-control-watchdog
        mssql-controller
        mssql-dns
        mssql-hadoop
        mssql-mleap-serving-runtime
        mssql-mlserver-py-runtime
        mssql-mlserver-r-runtime
        mssql-monitor-collectd
        mssql-monitor-elasticsearch
        mssql-monitor-fluentbit
        mssql-monitor-grafana
        mssql-monitor-influxdb
        mssql-monitor-kibana
        mssql-monitor-telegraf
        mssql-security-knox
        mssql-security-support
        mssql-server-controller
        mssql-server-data
        mssql-ha-operator
	    mssql-ha-supervisor
        mssql-service-proxy
        mssql-ssis-app-runtime
)


# Make a directory for installing the scripts and logs.
#
mkdir -p $BDCDEPLOY_DIR
cd $BDCDEPLOY_DIR/
touch $LOG_FILE

{
# Install all necessary packages: kubernetes, docker, python3, python3-pip, request, azdata.
#
echo ""
echo "######################################################################################"
echo "Starting installing packages..." 

# Install docker.
#
apt-get update -q

apt --yes install \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    lsb-release \
    gnupg \
    wget \
    curl

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

apt update -q
apt-cache policy docker-ce
apt --yes install docker-ce

usermod --append --groups docker $USER


# Install azdata cli.
#
curl -sL https://packages.microsoft.com/keys/microsoft.asc |
gpg --dearmor |
tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null

code=$(lsb_release -cs)
if [ $code == "focal" ]; then
   add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/prod.list)"
elif [ $code == "bionic" ]; then
   add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/18.04/prod.list)"
elif [ $code == "xenial" ]; then
   add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/16.04/prod.list)"
fi

apt-get update
apt-get install -y azdata-cli

cd -

azdata --version
echo "Azdata has been successfully installed."

# Load all pre-requisites for Kubernetes.
#
echo "###########################################################################"
echo "Starting to setup pre-requisites for kubernetes..." 

# Setup the kubernetes preprequisites.
#
echo $(hostname -i) $(hostname) >> /etc/hosts

swapoff -a
sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

# Install docker and packages to allow apt to use a repository over HTTPS.
#
apt-get update -q

apt-get install -q -y ebtables ethtool

#apt-get install -y docker.ce

apt-get install -q -y apt-transport-https

# Setup daemon.
#
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
#
systemctl daemon-reload
systemctl restart docker

apt-get install -q -y kubelet=$KUBE_DPKG_VERSION kubeadm=$KUBE_DPKG_VERSION kubectl=$KUBE_DPKG_VERSION

# Holding the version of kube packages.
#
apt-mark hold kubelet kubeadm kubectl
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

. /etc/os-release
if [ "$UBUNTU_CODENAME" == "bionic" ]; then
    modprobe br_netfilter
fi

# Disable Ipv6 for cluster endpoints.
#
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1

echo net.ipv6.conf.all.disable_ipv6=1 >> /etc/sysctl.conf
echo net.ipv6.conf.default.disable_ipv6=1 >> /etc/sysctl.conf
echo net.ipv6.conf.lo.disable_ipv6=1 >> /etc/sysctl.conf


sysctl net.bridge.bridge-nf-call-iptables=1

# Setting up the persistent volumes for the kubernetes.
#
for i in $(seq 1 $PV_COUNT); do

  vol="vol$i"

  mkdir -p /mnt/local-storage/$vol

  mount --bind /mnt/local-storage/$vol /mnt/local-storage/$vol

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
mkdir -p /home/$SUDO_USER/.kube

sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u $SUDO_USER):$(id -g $SUDO_USER) $HOME/.kube/config

# To enable a single node cluster remove the taint that limits the first node to master only service.
#
master_node=`kubectl get nodes --no-headers=true --output=custom-columns=NAME:.metadata.name`
kubectl taint nodes ${master_node} node-role.kubernetes.io/master:NoSchedule-

# Local storage provisioning.
#
kubectl apply -f https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/features/sql-big-data-cluster/deployment/kubeadm/ubuntu/local-storage-provisioner.yaml

# Install the software defined network.
#
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# helm init

kubectl apply -f https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/features/sql-big-data-cluster/deployment/kubeadm/ubuntu/rbac.yaml

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

# Pull docker images of SQL Server big data cluster.
#
echo ""
echo "############################################################################"
echo "Starting to pull docker images..." 
echo "Pulling images from repository: " $DOCKER_REGISTRY"/"$DOCKER_REPOSITORY

for image in "${IMAGES[@]}";
do
    docker pull $DOCKER_REGISTRY/$DOCKER_REPOSITORY/$image:$DOCKER_TAG
    echo "Docker image" $image " pulled."
done
echo "Docker images pulled." 

# Deploy azdata bdc create cluster.
#
echo ""
echo "############################################################################"
echo "Starting to deploy azdata cluster..." 

# Command to create cluster for single node cluster.
#
azdata bdc config init --source kubeadm-prod  --target kubeadm-custom -f
azdata bdc config replace -c kubeadm-custom/control.json -j ".spec.docker.repository=$DOCKER_REPOSITORY"
azdata bdc config replace -c kubeadm-custom/control.json -j ".spec.docker.registry=$DOCKER_REGISTRY"
azdata bdc config replace -c kubeadm-custom/control.json -j ".spec.docker.imageTag=$DOCKER_TAG"
azdata bdc config replace -c kubeadm-custom/bdc.json -j "$.spec.resources.data-0.spec.replicas=1"
azdata bdc config replace -c kubeadm-custom/control.json -j "spec.storage.data.className=$STORAGE_CLASS"
azdata bdc config replace -c kubeadm-custom/control.json -j "spec.storage.logs.className=$STORAGE_CLASS"
azdata bdc config patch -c kubeadm-custom/control.json -p $STARTUP_PATH/security-patch.json
azdata bdc config patch -c kubeadm-custom/bdc.json -p $STARTUP_PATH/endpoint-patch.json

azdata bdc create -c kubeadm-custom --accept-eula $ACCEPT_EULA
echo "Big data cluster being created..." 

# Setting context to cluster.
#
kubectl config set-context --current --namespace $CLUSTER_NAME

# Login and get endpoint list for the cluster.
#
azdata login -n $CLUSTER_NAME
azdata bdc endpoint list --output table
