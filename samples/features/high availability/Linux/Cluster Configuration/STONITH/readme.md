# Samples for STONITH Configuration in a Pacemaker Cluster

Pacemaker cluster vendors require STONITH to be enabled and a fencing device configured for a supported cluster setup. When the cluster resource manager cannot determine the state of a node or of a resource on a node, fencing is used to bring the cluster to a known state again. Resource level fencing ensures mainly that there is no data corruption in case of an outage by configuring a resource. You can use resource level fencing, for instance, with DRBD (Distributed Replicated Block Device) to mark the disk on a node as outdated when the communication link goes down. Node level fencing ensures that a node does not run any resources. This is done by resetting the node and the Pacemaker implementation of it is called STONITH (which stands for "shoot the other node in the head"). Pacemaker supports a great variety of fencing devices, e.g. an uninterruptible power supply or management interface cards for servers. For more details, see [Pacemaker Clusters from Scratch](http://clusterlabs.org/doc/en-US/Pacemaker/1.1-plugin/html/Clusters_from_Scratch/ch05.html), [Fencing and Stonith](http://clusterlabs.org/doc/crm_fencing.html), [Red Hat High Availability Add-On with Pacemaker: Fencing](http://access.redhat.com/documentation/Red_Hat_Enterprise_Linux/6/html/Configuring_the_Red_Hat_High_Availability_Add-On_with_Pacemaker/ch-fencing-HAAR.html) and [Fencing in a Red Hat High Availability Cluster](https://access.redhat.com/solutions/15575).

##  Other considerations

*  Disabling STONITH is just for testing purposes. If you plan to use Pacemaker in a production environment, you should plan a STONITH implementation depending on your environment and keep it enabled.
* Type of fence depends on the machine ( baremetal) or VM type.
* RHEL does not provide fencing agents for any cloud environments (including Azure) or Hyper-V. Consequentially, the cluster vendor does not offer support for running production clusters in these environments.
*  All fencing agents are shell scripts in /usr/sbin, so you can go through them and figure out what they are doing.
* Shell scripts often point to /usr/share/fence which have few python scripts
* Fencing should be tested from command line BEFORE you actually create a stonith fence with PCS.

* On many baremetal recommended seems to be ilo ( ilo/ilo2/ilo3/ilo4 which go over ipmi )  or second option is the ssh equivalents ( ilo3_ssh/ilo4_ssh)
    * Have to find out what version of ilo machine supports
    * For _ssh agents, have to add public key/auth to ilo  under the Administration—security to enable passwordless auth


## Other fencing configurations

[How do I configure a stonith device using agent fence_vmware_soap in a RHEL 6 or 7 High Availability cluster with pacemaker](https://access.redhat.com/solutions/917813)

[What are the requirements for using the fence agent fence_vmware_soap](https://access.redhat.com/solutions/306233)

[How can I diagnose fence_vmware_soap failures in RHEL 5, 6, or 7?](https://access.redhat.com/solutions/473603)

[How to configure stonith agent fence_xvm in pacemaker cluster when cluster nodes are KVM guests and are on different KVM hosts](https://access.redhat.com/solutions/2386421)

[How to configure fence agent fence_xvm in RHEL cluster](https://access.redhat.com/solutions/917833)
