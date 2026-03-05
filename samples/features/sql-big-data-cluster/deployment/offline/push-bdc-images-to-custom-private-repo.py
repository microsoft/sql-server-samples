# requires installation of Docker: https://docs.docker.com/install/ 

from subprocess import check_output, CalledProcessError, STDOUT, Popen, PIPE
import os
import getpass

def execute_cmd (cmd):
    if os.name=="nt":
        process = Popen(cmd.split(),stdin=PIPE, shell=True)
    else:
        process = Popen(cmd.split(),stdin=PIPE)
    stdout, stderr = process.communicate()
    if (stderr is not None):
        raise Exception(stderr)

SOURCE_DOCKER_REGISTRY = input("Provide Docker registry source - press ENTER for using `mcr.microsoft.com`:") or "mcr.microsoft.com"
SOURCE_DOCKER_REPOSITORY = input("Provide Docker repository source - press ENTER for using `mssql/bdc`:") or "mssql/bdc"
# Use this only if your source is a private Docker registry
# SOURCE_DOCKER_USERNAME = input("Provide Docker username for the source registry:")
# SOURCE_DOCKER_PASSWORD=getpass.getpass("Provide Docker password for the source registry:")
SOURCE_DOCKER_TAG = input("Provide Docker tag for the images at the source: ") or "latest"

TARGET_DOCKER_REGISTRY = input("Provide Docker registry target:")
TARGET_DOCKER_REPOSITORY = input("Provide Docker repository target:")
TARGET_DOCKER_USERNAME = input("Provide Docker username for the target registry:")
TARGET_DOCKER_PASSWORD = getpass.getpass("Provide Docker password for the target registry:")
TARGET_DOCKER_TAG = input("Provide Docker tag for the images at the target: ") or "latest"

images = ['mssql-app-service-proxy',
          'mssql-control-watchdog'
           'mssql-controller'
           'mssql-dns'
           'mssql-hadoop'
           'mssql-mleap-serving-runtime'
           'mssql-mlserver-py-runtime'
           'mssql-mlserver-r-runtime'
           'mssql-monitor-collectd'
           'mssql-monitor-elasticsearch'
           'mssql-monitor-fluentbit'
           'mssql-monitor-grafana'
           'mssql-monitor-influxdb'
           'mssql-monitor-kibana'
           'mssql-monitor-telegraf'
           'mssql-security-knox'
           'mssql-security-support'
           'mssql-server-controller'
           'mssql-server-data'
           'mssql-ha-operator'
           'mssql-ha-supervisor'
           'mssql-service-proxy'
           'mssql-ssis-app-runtime']

# Use this only if your source is a private Docker registry
# print("Execute docker login to source registry: " + SOURCE_DOCKER_REGISTRY)
# cmd = "docker login " + SOURCE_DOCKER_REGISTRY + " -u " + SOURCE_DOCKER_USERNAME + " -p " + SOURCE_DOCKER_PASSWORD
# execute_cmd(cmd)
# print("")


print("Pulling images from source repository: " + SOURCE_DOCKER_REGISTRY + "/" + SOURCE_DOCKER_REPOSITORY)
cmd = ""
for image in images:
     cmd += "docker pull " + SOURCE_DOCKER_REGISTRY + "/" + SOURCE_DOCKER_REPOSITORY + "/" + image + ":" + SOURCE_DOCKER_TAG +  " & "
cmd = cmd[:len(cmd)-3]
execute_cmd(cmd)

print("Execute docker login to target registry:" + TARGET_DOCKER_REGISTRY)
cmd = "docker login " + TARGET_DOCKER_REGISTRY + " -u " + TARGET_DOCKER_USERNAME + " -p " + TARGET_DOCKER_PASSWORD
execute_cmd(cmd)
print("")

print("Tagging local images...")
cmd = ""
for image in images:
     cmd += "docker tag " + SOURCE_DOCKER_REGISTRY + "/" + SOURCE_DOCKER_REPOSITORY + "/" + image + ":" + SOURCE_DOCKER_TAG + " " + TARGET_DOCKER_REGISTRY + "/" + TARGET_DOCKER_REPOSITORY + "/" + image + ":" + TARGET_DOCKER_TAG + " & "
cmd = cmd[:len(cmd)-3]
execute_cmd(cmd)

print("Push images to target Docker repository: " + TARGET_DOCKER_REGISTRY + "/" + TARGET_DOCKER_REPOSITORY)
cmd = ""
for image in images:
     cmd += "docker push " + TARGET_DOCKER_REGISTRY + "/" + TARGET_DOCKER_REPOSITORY + "/" + image + ":" + TARGET_DOCKER_TAG + " & "
cmd = cmd[:len(cmd)-3]
execute_cmd(cmd)

print("Images are now pushed to the target repository.")
cmd = "docker images"
execute_cmd(cmd)

