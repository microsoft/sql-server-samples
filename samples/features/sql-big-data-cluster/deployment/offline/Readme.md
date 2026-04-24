# Push SQL Server big data cluster Docker images to your own private Docker repository

Big data clusters must have access to a Docker repository from which to pull container images. If you need to deploy to an environment  that can't access the registry provided by Microsoft, you need to first push necessary images to your own private repository that the environment can access. This repository is then used as the target for a new deployment.

Using this sample Python script, you can pull all images from the Microsoft repository to your local Docker environment, and then push them to your own private repo.

## Prerequisites

- Docker Engine 1.8+ on any supported Linux distribution or Docker for Mac/Windows. For more information, see [Install Docker](https://docs.docker.com/engine/installation/).
- Running the script will require: Python minimum version 3.0

## Instructions

Run the script using:
```
python push-bdc-images-to-custom-private-repo.py
```

>**Note**
>
>If you have both python3 and python2 on your client machine and in the path, you will have to run the command using python3:
>```
>python3 push-bdc-images-to-custom-private-repo.py
>```

When prompted, provide your input for:
- Docker registry, repository to access Microsoft registry where the images will be pulled from (source). Press enter to use default mcr registry.
- Docker registry, repository and credentials to access your private registry where the images will be pushed to (target)

## Deploy with from your private repository

To deploy from your private repository, use the steps described in the [deployment guide](deployment-guidance.md), but customize the following environment variables to match your private Docker repository.

- **DOCKER_USERNAME**
- **DOCKER_PASSWORD**

You must also customize the deployment configuration file to point to the correct docker repository:

```
  "docker": {
    "registry": "<your_docker_registry>",
    "repository": "<your_docker_repository>",
    "imageTag": "<your_docker_tag>",
    "imagePullPolicy": "Always"
  }
```
