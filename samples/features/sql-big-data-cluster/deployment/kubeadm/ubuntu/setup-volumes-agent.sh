#!/bin/bash -e

# num of persistent volumes
PV_COUNT=25

for i in $(seq 1 $PV_COUNT); do
  vol="vol$i"

  mkdir -p /mnt/local-storage/$vol
  # If wondering why the next code line is needed, see https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner/blob/master/docs/faqs.md#why-i-need-to-bind-mount-normal-directories-to-create-pvs-for-them
  # Experience showed that the mount need to exist at cluster provision time. The fact they're not put in fstab and will disappear after reboot doesn't seem to be an issue once the K8S PV are created.
  mount --bind /mnt/local-storage/$vol /mnt/local-storage/$vol
done
