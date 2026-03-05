#!/bin/bash

DIR_PREFIX=$1

sudo kubeadm reset --force

# Clean up azdata-cli package.
#
sudo dpkg --remove --force-all azdata-cli

sudo systemctl stop kubelet
sudo rm -rf /var/lib/cni/
sudo rm -rf /var/lib/etcd/
sudo rm -rf /run/flannel/
sudo rm -rf /var/lib/kubelet/*
sudo rm -rf /etc/cni/
sudo rm -rf /etc/kubernetes/

sudo ip link set cni0 down
#brctl delbr cni0
sudo ip link set flannel.1 down
#brctl delbr flannel.1
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X

sudo rm -rf .azdata/

# Remove mounts.
#
SERVICE_STOP_FAILED=0

sudo systemctl | grep "/var/lib/kubelet/pods" | while read -r line; do

    # Retrieve the mount path
    #
    MOUNT_PATH=`echo "$line"  | grep -v echo | egrep -oh -m 1 "(/var/lib/kubelet/pods).+"`

    if [ -z "$MOUNT_PATH" ]; then
        continue
    fi

    if [[ ! -d "$MOUNT_PATH" ]] && [[ ! -f "$MOUNT_PATH" ]]; then

        SERVICE=$(echo $line | cut -f1 -d' ')

        echo "Mount "$MOUNT_PATH" no longer exists."
        echo "Stopping orphaned mount service: '$SERVICE'"

        sudo systemctl stop $SERVICE

        if [ $? -ne 0 ]; then
            SERVICE_STOP_FAILED=1
        fi

        echo ""
    fi
done

if [ $SERVICE_STOP_FAILED -ne 0 ]; then
    echo "Not all services were stopped successfully. Please check the above output for more inforamtion."
else
    echo "All orphaned services successfully stopped."
fi

# Clean the mounted volumes.
#

for i in $(seq 1 80); do

  vol="vol$i"

  sudo umount /azurearc/local-storage/$vol

  sudo rm -rf /azurearc/local-storage/$vol

done

# Reset kube
#
sudo apt-get purge -y kubeadm --allow-change-held-packages 
sudo apt-get purge -y kubectl --allow-change-held-packages
sudo apt-get purge -y kubelet --allow-change-held-packages
sudo apt-get purge -y kubernetes-cni --allow-change-held-packages
sudo apt-get purge -y kube* --allow-change-held-packages
sudo apt -y autoremove
sudo rm -rf ~/.kube

# Clean up working folders.
# 
export AZUREARCDATACONTROLLER_DIR=arc-data
if [ -d "$AZUREARCDATACONTROLLER_DIR" ]; then
    echo "Removing working directory $AZUREARCDATACONTROLLER_DIR."
    rm -f -r $AZUREARCDATACONTROLLER_DIR
fi
