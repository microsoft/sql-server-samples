#!/usr/bin/python3
from argparse import ArgumentParser
from copy import deepcopy
from enum import Enum, IntEnum
from datetime import datetime
import os
import subprocess
import sys
from tempfile import mkdtemp
from threading import Timer
import time

from kubernetes import client as kclient, config as kconfig, watch as kwatch
import yaml

from utils import (AgRole, AgMode, OperatorYaml, SqlSecretsYaml,
                   PersistentVolumeYaml, PersistentVolumeClaimYaml,
                   SqlServerYaml, AgServiceYaml, FailoverYaml)

DEFAULT_K8S_AGENTS_IMAGE = (
    "mcr.microsoft.com/mssql/ha:2019-CTP2.1-ubuntu")



TEMPLATES_DIR = "templates"
SQLSERVER_TEMPLATE = os.path.join(TEMPLATES_DIR, "sqlserver.yaml")
OPERATOR_TEMPLATE = os.path.join(TEMPLATES_DIR, "operator.yaml")
AG_SERVICE_TEMPLATE = os.path.join(TEMPLATES_DIR, "ag-service.yaml")
SQL_SECRETS_TEMPLATE = os.path.join(TEMPLATES_DIR, "sql-secrets.yaml")
PV_TEMPLATE = os.path.join(TEMPLATES_DIR, "pv.yaml")
PVC_TEMPLATE = os.path.join(TEMPLATES_DIR, "pvc.yaml")
FAILOVER_YAML_TEMPLATE = os.path.join(TEMPLATES_DIR, "failover.yaml")

SQLSERVER_YAML_FILENAME = "sqlserver.yaml"
OPERATOR_YAML_FILENAME = "operator.yaml"
AG_SERVICES_YAML_FILENAME = "ag-services.yaml"
SQL_SECRETS_YAML_FILENAME = "sql-secrets.yaml"
PV_YAML_FILENAME = "pv.yaml"
PVC_YAML_FILENAME = "pvc.yaml"
FAILOVER_YAML_FILENAME = "failover.yaml"

SQLSERVER_NAME_PREFIX = "mssql"
DEFAULT_NUM_SQLSERVER = 3
DEFAULT_SQLSERVER_NAMES = [
    "{}{}".format(SQLSERVER_NAME_PREFIX, i + 1)
    for i in range(DEFAULT_NUM_SQLSERVER)
]
DEFAULT_AG_NAME = "ag1"
DEFAULT_NAMESPACE = "default"

TERM_RED = "\x1b[31m"
TERM_GREEN = "\x1b[32m"
TERM_END = "\x1b[0m"


class LogLevel(IntEnum):
    ALL = 0
    ERROR = 1
    WARNING = 2
    INFO = 3
    DEBUG = 4


log_verbosity = LogLevel.ALL


def log(level, *args):
    color = ""
    color_end = ""

    if level == LogLevel.ERROR:
        color = TERM_RED
        color_end = TERM_END
    if level <= log_verbosity:
        print(color, "[", level.name, "] ", color_end, sep="", end="")
        print(*args)


# YAML read/write functions
def create_operator_yaml(namespace,
                         k8s_agent_image,
                         operator_template=OPERATOR_TEMPLATE,
                         filepath=OPERATOR_YAML_FILENAME):
    with open(operator_template) as f:
        operator_yaml = OperatorYaml(yaml.load_all(f.read()))
        operator_yaml.set_namespace(namespace)
        operator_yaml.set_agent_image(k8s_agent_image)
        with open(filepath, "w") as operator_yaml_file:
            yaml.dump_all(operator_yaml.data, operator_yaml_file)
        log(LogLevel.INFO, "operator YAML file:", filepath)


def get_pv_name(namespace, sqlserver_name):
    return "{}-{}-pv".format(namespace, sqlserver_name)


def create_pv_yaml(namespace,
                   sqlservers,
                   root_path,
                   pv_template=PV_TEMPLATE,
                   filepath=PV_YAML_FILENAME):
    with open(pv_template) as f:
        pv_yaml_template = PersistentVolumeYaml(yaml.load(f.read()))
        pv_yaml_list = []
        for sqlserver_name in sqlservers:
            pv_yaml = pv_yaml_template.copy()
            pv_yaml.set_storage(namespace)
            pv_name = get_pv_name(namespace, sqlserver_name)
            pv_yaml.set_name(pv_name)
            pv_yaml.set_path(os.path.join(root_path, pv_name))
            pv_yaml_list.append(pv_yaml)

        with open(filepath, "w") as pv_yaml_file:
            yaml.dump_all([pv.data for pv in pv_yaml_list], pv_yaml_file)
        log(LogLevel.INFO, "Persistent Volume YAML file:", filepath)
        return pv_yaml_list


# def create_pvc_yaml(namespace, name, storage_class_name="default",
#         pvc_template=PVC_TEMPLATE, filepath=PVC_YAML_FILENAME):
#     with open(pv_template) as f:
#         pvc_yaml_template = PersistentVolumeClaimYaml(yaml.load(f.read()))


def create_sqlservers_yaml(env,
                           namespace,
                           sqlservers,
                           ags,
                           sa_password,
                           k8s_agent_image,
                           sqlserver_template=SQLSERVER_TEMPLATE,
                           filepath=SQLSERVER_YAML_FILENAME):
    with open(sqlserver_template) as f:
        sqlserver_yaml_template = SqlServerYaml(yaml.load_all(f.read()))
        sqlserver_yaml_list = []
        for sqlserver_name in sqlservers:
            sqlserver_yaml = sqlserver_yaml_template.copy()
            sqlserver_yaml.set_name(sqlserver_name)
            sqlserver_yaml.set_namespace(namespace)
            sqlserver_yaml.set_availability_groups(ags)
            sqlserver_yaml.set_agent_image(k8s_agent_image)
            if env is Environment.ON_PREM:
                sqlserver_yaml.set_volume_claim_template_with_selector(
                    namespace)
                sqlserver_yaml.set_service_type("NodePort")
            elif env is Environment.AKS:
                sqlserver_yaml.set_volume_claim_template_with_storage_class()
                sqlserver_yaml.set_service_type("LoadBalancer")
            else:
                raise ValueError("Invalid Environment type")
            for data in sqlserver_yaml.data:
                sqlserver_yaml_list.append(data)

        with open(filepath, "w") as sqlserver_yaml_file:
            yaml.dump_all(sqlserver_yaml_list, sqlserver_yaml_file)
        log(LogLevel.INFO, "SQL Server YAML file:", filepath)


def create_ag_services_yaml(env,
                            namespace,
                            ag,
                            ag_service_template=AG_SERVICE_TEMPLATE,
                            filepath=AG_SERVICES_YAML_FILENAME):
    with open(ag_service_template) as f:
        ag_service_yaml = AgServiceYaml(yaml.load(f.read()))
        if env is Environment.ON_PREM:
            ag_service_yaml_list = create_ag_services(
                "NodePort", ag_service_yaml.data, namespace=namespace, ag=ag,annotations=env.service_annotations)
        elif env is Environment.AKS:
            ag_service_yaml_list = create_ag_services(
                "LoadBalancer",
                ag_service_yaml.data,
                namespace=namespace,
                ag=ag,
                annotations=env.service_annotations)
        else:
            raise ValueError("Invalid env")
        ag_services_yaml_raw = [
            ags_yaml.data for ags_yaml in ag_service_yaml_list
        ]
        with open(filepath, "w") as ag_services_yaml_file:
            yaml.dump_all(ag_services_yaml_raw, ag_services_yaml_file)
        log(LogLevel.INFO, "ag-services YAML file:", filepath)
        return ag_service_yaml_list


def create_ag_services(service_type, template_data, namespace, ag,
                       annotations):
    primary = AgServiceYaml.create_ag_service(service_type,
                                              deepcopy(template_data),
                                              namespace, ag, AgRole.PRIMARY,
                                              None, annotations)
    sec_sync = AgServiceYaml.create_ag_service(service_type,
                                               deepcopy(template_data),
                                               namespace, ag, AgRole.SECONDARY,
                                               AgMode.SYNC, annotations)
    sec_async = AgServiceYaml.create_ag_service(
        service_type, deepcopy(template_data), namespace, ag, AgRole.SECONDARY,
        AgMode.ASYNC, annotations)
    sec_config_only = AgServiceYaml.create_ag_service(
        service_type, deepcopy(template_data), namespace, ag, AgRole.SECONDARY,
        AgMode.CONFIG, annotations)

    return (primary, sec_sync, sec_async, sec_config_only)


def create_sql_secrets_yaml(namespace,
                            sapassword,
                            sql_secrets_template=SQL_SECRETS_TEMPLATE,
                            filepath=SQL_SECRETS_YAML_FILENAME):
    with open(sql_secrets_template) as f:
        sql_secrets_yaml = SqlSecretsYaml(yaml.load(f.read()))
        sql_secrets_yaml.set_namespace(namespace)
        sql_secrets_yaml.set_sapassword(sapassword)
        with open(filepath, "w") as sql_secretes_yaml_file:
            yaml.dump_all([sql_secrets_yaml.data], sql_secretes_yaml_file)
        log(LogLevel.INFO, "sql-secrets YAML file:", filepath)
        return sql_secrets_yaml


def create_failover_yaml(namespace,
                         agent_image,
                         ag,
                         target_replica,
                         failover_template=FAILOVER_YAML_TEMPLATE,
                         filepath=FAILOVER_YAML_FILENAME):
    with open(failover_template) as f:
        failover_yaml = FailoverYaml(yaml.load_all(f.read()))
        failover_yaml.set_namespace(namespace)
        failover_yaml.set_config_map_name(ag)
        failover_yaml.set_endpoint_name(ag)
        failover_yaml.set_failover_container(
            agent_image=agent_image, ag=ag, new_primary=target_replica)
        with open(filepath, "w") as failover_yaml_file:
            yaml.dump_all(failover_yaml.data, failover_yaml_file)
        log(LogLevel.INFO, "failover YAML file:", filepath)
        return failover_yaml


# kubectl functions
def kubectl(args, **kwargs):
    proc_args = ["kubectl"] + args
    log(LogLevel.ALL, "Running command:", "`{}`".format(" ".join(proc_args)))
    proc = subprocess.run(
        args=proc_args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
        **kwargs)
    if proc.stdout:
        log(LogLevel.INFO, proc_args, "\n", proc.stdout)
    if proc.stderr:
        log(LogLevel.ERROR, proc_args, "\n", proc.stderr)
    log(LogLevel.INFO, proc_args, "exit code:", proc.returncode)
    return proc


def deploy_operator(namespace, operator_yaml):
    # We use `kubectl` here because for the kubernetes client we would
    # need to handle the document kind individually.
    kubectl(["apply", "-f", operator_yaml])
    operator_deployed = False

    def is_operator_deployed(event):
        if (event["type"] == "ADDED"
                and event["object"].metadata.name == "mssql-operator"):
            return True, event["object"]
        else:
            return False, event["object"]

    apps_api = kclient.AppsV1Api()
    operator_success, operator_deployed = kube_watch_event(
        is_operator_deployed,
        apps_api.list_namespaced_deployment,
        namespace=namespace,
        timeout_seconds=10)
    log(LogLevel.ALL, "operator deployed:", operator_success)

    def is_crd_deployed(event):
        expected = "sqlservers.mssql.microsoft.com"
        if (event["type"] == "ADDED"
                and event["object"].metadata.name == expected):
            return True, event["object"]
        else:
            return False, event["object"]

    extensions_api = kclient.ApiextensionsV1beta1Api()

    # We need to sleep here.
    # Kubernetes client API will raise the following exception if the operator
    # is not fully deployed when trying to list_custom_resource_definition:
    # File "kubernetes/client/models/v1beta1_custom_resource_definition_status.py", line 105, in conditions # noqa: E501
    #   raise ValueError("Invalid value for `conditions`, must not be `None`")
    log(LogLevel.ALL, "Waiting 10 seconds...")
    time.sleep(10)

    # Wait for crd to be deployed.
    log(LogLevel.ALL,
        "Waiting for Custom Resource Definition to be initialized")
    log(LogLevel.INFO,
        "This can be slow during the first deployment because we need to",
        "pull docker images")
    kube_watch_event(is_crd_deployed,
                     extensions_api.list_custom_resource_definition)

    return operator_success


def deploy_pv(namespace, sql_servers, pv_yaml):
    pv_names = [get_pv_name(namespace, sql_name) for sql_name in sql_servers]
    log(LogLevel.INFO, "Deploying Persistent Volumes")
    kubectl(["apply", "-f", pv_yaml])
    pvs_deployed = []

    def all_pvs_deployed(event):
        name = event["object"].metadata.name
        if event["type"] == "ADDED" and name in pv_names:
            pvs_deployed.append(name)
        if (len(pv_names) == len(pvs_deployed)
                and (sorted(pv_names) == sorted(pvs_deployed))):
            return True, pvs_deployed
        else:
            return False, pvs_deployed

    core_v1_api = kclient.CoreV1Api()

    deployed_pvs = kube_watch_event(
        all_pvs_deployed,
        core_v1_api.list_persistent_volume,
        timeout_seconds=60)

    return deployed_pvs


def deploy_sqlservers(namespace, sql_servers, sqlserver_yaml):
    log(LogLevel.INFO, "Deploying SQL Servers:", sql_servers)
    kubectl(["apply", "-f", sqlserver_yaml])
    sql_pods_deployed = []

    def all_sql_deployed(event):
        # Custom objects API returns dictionaries
        name = event["object"]["metadata"]["name"]
        if event["type"] == "ADDED" and name in sql_servers:
            sql_pods_deployed.append(name)
        if (len(sql_servers) == len(sql_pods_deployed)
                and (sorted(sql_servers) == sorted(sql_pods_deployed))):
            return True, sql_pods_deployed
        else:
            return False, sql_pods_deployed

    custom_objects_api = kclient.CustomObjectsApi()

    _, sql_pods_deployed = kube_watch_event(
        all_sql_deployed,
        custom_objects_api.list_namespaced_custom_object,
        group="mssql.microsoft.com",
        version="v1",
        plural="sqlservers",
        namespace=namespace)

    return sql_pods_deployed


def deploy_ag_services(namespace, expected_names, ag_services_yaml):
    log(LogLevel.INFO, "Deploying AG services in YAML:", ag_services_yaml)
    kubectl(["apply", "-f", ag_services_yaml])
    deployed_ag_services = []

    def all_ag_services_deployed(event):
        # service name
        name = event["object"].metadata.name
        if event["type"] == "ADDED" and name in expected_names:
            deployed_ag_services.append(name)

        if (len(expected_names) == len(deployed_ag_services)
                and (sorted(expected_names) == sorted(deployed_ag_services))):
            # all services have been deployed
            return True, deployed_ag_services
        else:
            return False, deployed_ag_services

    core_v1_api = kclient.CoreV1Api()

    deployed_ag_services = kube_watch_event(
        all_ag_services_deployed,
        core_v1_api.list_namespaced_service,
        namespace=namespace,
        timeout_seconds=60)

    return deployed_ag_services


def create_namespace(namespace):
    log(LogLevel.INFO, "Creating namespace:", namespace)
    kconfig.load_kube_config()
    core_v1_api = kclient.CoreV1Api()
    v1_ns = kclient.V1Namespace(metadata=kclient.V1ObjectMeta(name=namespace))
    core_v1_api.create_namespace(body=v1_ns)

    return v1_ns


class KubeWatchEventError(Exception):
    pass

def kube_watch_event(completion_func, api_func, **kwargs):
    watch = kwatch.Watch()
    count = 8
    completed = False
    result = None
    watch_timer = Timer(60.0, lambda: watch.stop())

    ex_timer = Timer(300.0, KubeWatchEventError)

    # watch.stream generator might throw an exception
    # not sure how to handle.
    watch_timer.start()
    ex_timer.start()
    try:
        for event in watch.stream(api_func, **kwargs):
            log(LogLevel.DEBUG, "Watch count:", count)
            log(LogLevel.DEBUG, "Event:", event["type"], "object:",
                event["object"])
            count -= 1
            completed, result = completion_func(event)
            log(LogLevel.DEBUG, "Completed:", completed)
            if completed:
                watch.stop()
            if not count:
                watch.stop()
    except KubeWatchEventError:
        raise
    except Exception as ex:
        log(LogLevel.ERROR, "Caught exception:", str(ex))
        watch.stop()

    watch_timer.cancel()
    ex_timer.cancel()
    if not completed:
        log(LogLevel.ERROR, str(api_func), "Could not complete sucessfully")

    return completed, result


def apply_specs(namespace,
                sql_servers,
                ag_services,
                operator_yaml_file=OPERATOR_YAML_FILENAME,
                sql_secrets_yaml_file=SQL_SECRETS_YAML_FILENAME,
                pv_yaml_file=PV_YAML_FILENAME,
                sqlserver_yaml_file=SQLSERVER_YAML_FILENAME,
                ag_services_yaml_file=AG_SERVICES_YAML_FILENAME):
    kconfig.load_kube_config()
    operator_deployed = deploy_operator(namespace, operator_yaml_file)

    if operator_deployed:
        log(LogLevel.ALL, "Successfully deployed mssql-operator")
        log(LogLevel.ALL)

        kubectl(["apply", "-f", sql_secrets_yaml_file])

        if pv_yaml_file:
            pvs_deployed = deploy_pv(namespace, sql_servers, pv_yaml_file)
            log(LogLevel.ALL, "Successfully deployed Persistent Volumes",
                pvs_deployed)
            log(LogLevel.ALL)

        sql_pods_deployed = (deploy_sqlservers(namespace, sql_servers,
                                               sqlserver_yaml_file))
        log(LogLevel.ALL, "Successfully deployed SQL pods", sql_pods_deployed)
        log(LogLevel.ALL)

        ag_services_deployed = (deploy_ag_services(namespace, ag_services,
                                                   ag_services_yaml_file))

        log(LogLevel.ALL, "Successfully deployed AG services",
            ag_services_deployed)
        log(LogLevel.ALL)


def exit(exitcode):
    color = TERM_GREEN if exitcode == 0 else TERM_RED
    print(color, sys.argv[0], " exitcode: ", exitcode, TERM_END, sep="")
    sys.exit(exitcode)


class ActionBase:
    def __init__(self, parser):
        self.parser = parser
        self.init_parser()
        self.parser.set_defaults(obj=self)

    def parse_args(self):
        args = self.parser.parse_args()
        return args

    def validate_args(self):
        return True

    def run(self, args, working_dir):
        pass

    def __str__(self):
        return self.parser.prog

    @classmethod
    def add_to_parser(cls, parser):
        return cls(parser)


class Environment(Enum):
    ON_PREM = 0
    AKS = 1

    def __str__(self):
        return self.name

    @staticmethod
    def from_str_ignore_case(s):
        try:
            return Environment[s.upper()]
        except KeyError:
            raise ValueError()

    @property
    def service_annotations(self):
        # if self is Environment.AKS:
        #     return {
        #         "service.beta.kubernetes.io/azure-load-balancer-internal":
        #         "true"
        #     }
        # else:
        return None


class DeployAction(ActionBase):
    def init_parser(self):
        parser = self.parser
        parser.description = (
            "Deploy SQL Server and k8s Agents in namespace(AG name)")
        parser.add_argument(
            "--ag",
            default=DEFAULT_AG_NAME,
            help="name of the Availability Group. Default=" + DEFAULT_AG_NAME)
        parser.add_argument(
            "-n",
            "--namespace",
            help=("name of the k8s namespace. " +
                  "Defaults to AG name if not specified."))
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Perform a dry run and not apply the specs.")
        parser.add_argument(
            "-s",
            "--sql-servers",
            nargs="+",
            default=DEFAULT_SQLSERVER_NAMES,
            help="names of SQL Server instances(up to 5, separated by spaces)"
            "Default=" + str(DEFAULT_SQLSERVER_NAMES))
        default_sa_password = "SAPassword2018"
        parser.add_argument(
            "-p",
            "--sa-password",
            default=default_sa_password,
            help="SA Password. Default='{}'".format(default_sa_password))
        parser.add_argument(
            "-e",
            "--env",
            type=Environment.from_str_ignore_case,
            choices=list(Environment),
            default=Environment.ON_PREM)

        parser.add_argument(
                "--skip-create-namespace",
                action="store_true",
                help="Skip namespace creation.")

    def validate_args(self, args):
        args.sql_servers.sort()
        sql_list = []
        for sql in args.sql_servers:
            if len(sql_list) > 0 and sql_list[-1] == sql:
                log(LogLevel.WARNING, "duplicate SQL Server = ", sql)
            else:
                sql_list.append(sql)

        if not (0 < len(sql_list) <= 5):
            log(LogLevel.ERROR, "Invalid number of sql_servers =", sql_list,
                "size =", len(sql_list))
            log(LogLevel.Error, "Expected 0 < number of SQL Server <= 5")
            return False

        return True

    def run(self, args, working_dir):
        exitcode = 0

        log(LogLevel.INFO, "Working directory:", working_dir)
        log(LogLevel.INFO)

        operator_yaml_path = os.path.join(working_dir, OPERATOR_YAML_FILENAME)
        sql_secrets_yaml_path = os.path.join(working_dir,
                                             SQL_SECRETS_YAML_FILENAME)
        pv_yaml_path = None
        sqlservers_yaml_path = os.path.join(working_dir,
                                            SQLSERVER_YAML_FILENAME)
        ag_services_yaml_path = os.path.join(working_dir,
                                             AG_SERVICES_YAML_FILENAME)

        create_operator_yaml(
            args.namespace,
            DEFAULT_K8S_AGENTS_IMAGE,
            filepath=operator_yaml_path)
        create_sql_secrets_yaml(
            args.namespace, args.sa_password, filepath=sql_secrets_yaml_path)

        if args.env is Environment.ON_PREM:
            pv_yaml_path = os.path.join(working_dir, PV_YAML_FILENAME)
            pv_yaml_list = create_pv_yaml(
                args.namespace,
                args.sql_servers,
                root_path=working_dir,
                filepath=pv_yaml_path)

        create_sqlservers_yaml(
            args.env,
            args.namespace,
            args.sql_servers, [args.ag],
            args.sa_password,
            DEFAULT_K8S_AGENTS_IMAGE,
            filepath=sqlservers_yaml_path)
        load_balancer_services = create_ag_services_yaml(
                args.env,
            args.namespace, args.ag, filepath=ag_services_yaml_path)

        if not args.dry_run:
            if not args.skip_create_namespace:
                create_namespace(args.namespace)

            log(LogLevel.ALL)
            if args.env is Environment.ON_PREM:
                for pv_yaml in pv_yaml_list:
                    log(LogLevel.ALL, "Persistent Volume:", pv_yaml.get_name(),
                        "mkdir:", pv_yaml.get_path())
                    os.mkdir(pv_yaml.get_path())

            expected_service_names = [
                service_yaml.name for service_yaml in load_balancer_services
            ]
            apply_specs(args.namespace, args.sql_servers,
                        expected_service_names, operator_yaml_path,
                        sql_secrets_yaml_path, pv_yaml_path,
                        sqlservers_yaml_path, ag_services_yaml_path)

        paths = [
            operator_yaml_path, sql_secrets_yaml_path, pv_yaml_path,
            sqlservers_yaml_path, ag_services_yaml_path
        ]
        paths = [path for path in paths if path]
        return (exitcode, paths)


class FailoverAction(ActionBase):
    def init_parser(self):
        parser = self.parser
        parser.description = "Perform a manual failover"
        parser.add_argument(
            "target_replica",
            help="name of target SQL Server replica to failover to")
        parser.add_argument(
            "--ag",
            default=DEFAULT_AG_NAME,
            help="name of the Availability Group. Default=" + DEFAULT_AG_NAME)
        parser.add_argument(
            "--namespace",
            help=("name of the k8s namespace. " +
                  "Defaults to AG name if not specified"))
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Perform a dry run and NOT apply the specs")
        # parser.add_argument(
        #     "--force-failover-allow-data-loss",
        #     action="store_true",
        #     help="Perform a force failover allow data loss")

    def validate_args(self, args):
        """
        Validate the target replica exists?
        """
        return True

    def run(self, args, working_dir):
        exitcode = 0
        failover_yaml_path = os.path.join(working_dir, FAILOVER_YAML_FILENAME)
        failover_yaml = create_failover_yaml(
            namespace=args.namespace,
            agent_image=DEFAULT_K8S_AGENTS_IMAGE,
            ag=args.ag,
            target_replica=args.target_replica,
            filepath=failover_yaml_path)
        if not args.dry_run:
            log(LogLevel.ALL, "Creating failover job")
            proc = kubectl(["apply", "-f", failover_yaml_path])
            log(LogLevel.ALL, "Failover job created")
            exitcode = proc.returncode
        return (exitcode, [failover_yaml_path])


def main():
    parent_parser = ArgumentParser(add_help=False)
    parent_parser.add_argument(
        "--verbose",
        "-v",
        default=LogLevel.ERROR,
        action="count",
        help="Verbosity of output")
    root_parser = ArgumentParser()
    subparsers = root_parser.add_subparsers(
        description="Actions on k8s agent", dest="subaction")
    DeployAction.add_to_parser(
        subparsers.add_parser(
            "deploy",
            help="Deploy a set of SQL Servers in an Availability Group",
            parents=[parent_parser]))
    FailoverAction.add_to_parser(
        subparsers.add_parser(
            "failover",
            help="Perform a failover to a target replica.",
            parents=[parent_parser]))

    args = root_parser.parse_args()
    # namespace defaults to AG name
    if args.namespace is None or args.namespace == "":
        args.namespace = args.ag

    log(LogLevel.INFO, "args:", vars(args))

    if not args.subaction:
        root_parser.print_help()
        exit(1)

    global log_verbosity
    log_verbosity = args.verbose

    if not args.obj.validate_args(args):
        print("action.validate_args failed:", args.obj, args)
        root_parser.print_help()
        exit(1)

    log(LogLevel.INFO, sys.argv[0], "Startup Time:", datetime.now(), "UTC:",
        datetime.utcnow())
    log(LogLevel.INFO)

    # create temp directory
    working_dir = mkdtemp(
        prefix="kube_agent_{}-".format(args.subaction),
        suffix=(args.namespace))

    # Run action here
    exitcode, spec_paths = args.obj.run(args, working_dir)

    log(LogLevel.INFO, sys.argv[0], "Completion Time:", datetime.now(), "UTC:",
        datetime.utcnow())
    log(LogLevel.INFO, "----------")
    if spec_paths:
        log(LogLevel.ALL, "Created the following specs:")
        for path in spec_paths:
            log(LogLevel.ALL, "\t", path)
        log(LogLevel.ALL)
        try:
            specs_file = "{}_{}_specs".format(args.subaction, args.namespace)
            log(LogLevel.ALL, "Wrote spec paths:", "'{}'".format(specs_file))
            with open(specs_file, "w") as f:
                f.write("\n".join(spec_paths) + "\n")
        except IOError as ex:
            log(LogLevel.ALL, "Caught IOError:", ex, "writing to",
                "'{}'".format(specs_file))
    exit(exitcode)


if __name__ == "__main__":
    main()
