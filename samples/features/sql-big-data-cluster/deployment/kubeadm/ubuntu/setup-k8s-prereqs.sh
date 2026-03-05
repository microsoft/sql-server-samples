#!/bin/sh -x

# Setup the kubernetes preprequisites
#
echo $(hostname -i) $(hostname) >> /etc/hosts
sudo sed -i "/swap/s/^/#/" /etc/fstab
sudo swapoff -a
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

KUBE_DPKG_VERSION=1.20.7-00
apt-get update
apt-get install -y ebtables ethtool
apt-get install -y docker.io
apt-get install -y apt-transport-https
apt-get install -y kubelet=$KUBE_DPKG_VERSION kubeadm=$KUBE_DPKG_VERSION kubectl=$KUBE_DPKG_VERSION
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

. /etc/os-release
if [ "$UBUNTU_CODENAME" = "bionic" ]; then
    modprobe br_netfilter
fi
sysctl net.bridge.bridge-nf-call-iptables=1
