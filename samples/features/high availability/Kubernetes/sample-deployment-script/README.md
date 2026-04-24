# Overview
Sample script for doing the following:
 - Some basic validation of input parameters (i.e. more than 5 sync replicas
   should not be allowed)
 - Generate .yaml configuration file for the operator – all defaults, with AG
   name as the namespace name
 - Generate .yaml configuration file for SQL Server (and load balancer
   services for primary and secondaries endpoint) based on the required user
   inputs for each scenario and other implicit defaults as per below.
   Resources will be created in same namespace as the operator
-  Run kubectl apply

# Other semantics
 - If user runs the script multiple times with same AG name – deployment fails
   (creating a namespace with same name will fail)

 - If user runs the script multiple times with different AG name – the script
   will create a new namespace and new operator and new instances will be
   deployed. This means that users can not use the script to create multiple
   AGs in the same instances. They will have to use the .yaml edit files route
   to create multiple AGs in same instance.

# Setup/Requirements
 - python3.5
 - pyyaml (Python package)
 - kubernetes.client (Python package)

Assuming you have `pip` pointing to the python3 version, run the following to
install the required packages:
```sh
pip install --user -r requirements.txt
```

# Usage
Do `./deploy-ag.py --help` to get usage details.

Create the deployment specs and apply
```sh
./deploy-ag.py deploy
```

Create the specs but **NOT** apply
```sh
./deploy-ag.py deploy --dry-run
```

Edit the following constants for image pull secrets.

```python
IMAGE_PULL_SECRET_NAME
CREATE_IMAGE_PULL_SECRET
```

# Common errors:
- pod stuck in *ContainerCreating* state.
  Run: `kubectl describe pod <pod name> --namespace <namespace>`

  If you see something like:

  ```
   Warning  FailedScheduling  2m (x25 over 3m)  default-scheduler  0/3 nodes
   are available: 1 node(s) had taints that the pod didn't tolerate, 2 node(s)
   didn't match pod affinity/anti-affinity, 2 node(s) didn't satisfy existing
   pods anti-affinity rules.
  ```

  It means you need to enable pods to be schedule on cluster master. Run this:

  ```sh
  kubectl taint nodes --all node-role.kubernetes.io/master-
  ```
