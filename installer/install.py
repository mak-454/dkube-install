from __future__ import print_function
from kubernetes.client.rest import ApiException
from pprint import pprint
from kubernetes import config , client
import argparse
import subprocess as sp
import re
import sys
import time
import os
import shutil
import json
import requests

BASE_DIR = '/tmp'
DKUBE_PATH = BASE_DIR + '/dkube'
KUBEFLOW_APPNAME = 'my-kubeflow'
KUBEFLOW_PATH = BASE_DIR + '/' + KUBEFLOW_APPNAME
KF_ENV = 'nocloud'
VERSION = 'v0.1.2'
PWD = os.getcwd()
default_dockerhub_creds = ["lucifer001", "lucifer@dkube", "ocdlgit@oneconvergence.com"]

def pretty_green(msg):
	print("\033[1;32m[Dkube installer] %s\033[0m"%msg)

def pretty_red(msg):
	print("\033[1;31m[Dkube installer] %s\033[0m"%msg)

def pretty_blue(msg):
	print("\033[1;34m[Dkube installer] %s\033[0m"%msg)

def check_running_user():
	if not os.geteuid()==0:
		pretty_red("Please run this script as a root")
		sys.exit(1)

def dkube_installer_help():
	pretty_red("SYNTAX:  %s <cmd: deploy, delete, onboard, deboard> [--pkg <option: all, dkube, dkube-ui, kubeflow>] [--client_id <git-app-client-id>] [--client_secret <git-app-client-secret>] [--docker_username <docker_username>] [--docker_password <docker-password>] [--docker_email <docker-email>] [--git_username <git-username>]"% sys.argv[0])
	sys.exit(1)

def cmd_help(cmd):
	if (cmd == "deploy"):
		pretty_red("SYNTAX:  %s %s --pkg <all, dkube, dkube-ui, kubeflow> [--client_id <git-app-client-id>] [--client_secret <git-app-client-secret>] [--docker_username <docker-username>] [--docker_password <docker-password>] [--docker_email <docker-email>] "% (sys.argv[0], cmd))
	elif (cmd == "delete"):
		pretty_red("SYNTAX:  %s %s --pkg <all, dkube, dkube-ui, kubeflow>"% (sys.argv[0], cmd))
	elif (cmd == "operator"):
		pretty_red("SYNTAX:  %s %s --add <git_username> --org <organisation>"% (sys.argv[0], cmd))
	sys.exit(1)

def find_master_ip():
	file = open("/root/.kube/config")
	lines = file.readlines()
	line = ', '.join(lines)
	ip = re.findall( r'[0-9]+(?:\.[0-9]+){3}', line )
	ip_addr = ip[0]
	return ip_addr


def operator_add(user, org):
    master_ip = find_master_ip()
    url = "http://%s:32222/GPUaaS/operator/super"%master_ip
    job = {'username': user, 'organization': org}
    data = json.dumps(job)
    headers = {'Content-Type': 'application/json'}
    result = requests.post(url, data=data, headers=headers)
    print("status:",result.status_code)
    if (result.status_code != 200):
        pretty_red("Operator add Failed")
        sys.exit(1)

def operator_delete(user, org):
    pretty_red("This Feature is not available for now !!! please check the installation document")
    sys.exit(1)

def init_kubeflow():
	os.chdir(BASE_DIR)
	if os.path.isdir(KUBEFLOW_PATH):
		shutil.rmtree(KUBEFLOW_PATH)

	if sp.call("ks init %s"% KUBEFLOW_APPNAME,shell=True, executable='/bin/bash'):
		pretty_red("ks init kubeflow Failed")
		sys.exit(1)
	time.sleep(1)
	os.chdir(KUBEFLOW_APPNAME)
	if sp.call("ks registry add kubeflow github.com/kubeflow/kubeflow/tree/%s/kubeflow"% VERSION,shell=True, executable='/bin/bash'):
		pretty_red("Adding kubeflow registry Failed")
		sys.exit(1)
	time.sleep(1)

	if sp.call("ks pkg install kubeflow/core@%s"% VERSION,shell=True, executable='/bin/bash'):
		pretty_red("installing kubeflow/core Failed")
		sys.exit(1)
	time.sleep(1)

	if sp.call("ks pkg install kubeflow/tf-serving@%s"% VERSION,shell=True, executable='/bin/bash'):
		pretty_red("installing kubeflow/tf-serving Failed")
		sys.exit(1)
	time.sleep(1)

	if sp.call("ks pkg install kubeflow/tf-job@%s"% VERSION,shell=True, executable='/bin/bash'):
		pretty_red("installing kubeflow/tf-job Failed")
		sys.exit(1)
	time.sleep(1)

	if os.system("ks generate core kubeflow-core --name=kubeflow-core"):
		pretty_red("Creating Kubeflow core component Failed")
		sys.exit(1)
	time.sleep(1)

	sp.call("ks param set kubeflow-core reportUsage true",shell=True, executable='/bin/bash')
	uuid = sp.check_output("uuidgen",shell=True)
	sp.call("ks param set kubeflow-core usageId %s"% uuid,shell=True, executable='/bin/bash')

	if sp.call("ks env add nocloud",shell=True, executable='/bin/bash'):
		pretty_red("adding env Failed")
		sys.exit(1)
		

def create_secret(namespace, docker_user, docker_password, docker_email):
	if sp.call("kubectl get secret -n %s dkube-dockerhub-secret &> /dev/null"%namespace,shell=True, executable='/bin/bash'):
		if sp.call("kubectl --namespace %s create secret docker-registry dkube-dockerhub-secret --docker-server=https://index.docker.io/v1/ --docker-username=%s --docker-password=%s --docker-email=%s"% (namespace, docker_user, docker_password, docker_email),shell=True, executable='/bin/bash'):
			pretty_red("Failed to create dkube-dkube-secret")
			sys.exit(1)

def create_ui_secret(client_id, client_secret):
	if sp.call("kubectl get secret -n dkube dkube-github-app-secret &> /dev/null",shell=True, executable='/bin/bash'):
		if sp.call("kubectl --namespace dkube create secret generic dkube-github-app-secret --from-literal=client-id=%s --from-literal=client-secret=%s"% (client_id, client_secret),shell=True, executable='/bin/bash'):
			pretty_red("Failed to create dkube-ui-secret")
			sys.exit(1)

def delete_secret(namespace):
	if not sp.call("kubectl get secret -n %s dkube-dockerhub-secret &> /dev/null"%namespace,shell=True, executable='/bin/bash'):
		if sp.call("kubectl --namespace %s delete secret dkube-dockerhub-secret"%namespace,shell=True, executable='/bin/bash'):
			pretty_red("Failed to delete dkube-secret")
			sys.exit(1)

def delete_ui_secret():
	if not sp.call("kubectl get secret -n dkube dkube-github-app-secret &> /dev/null",shell=True, executable='/bin/bash'):
		if sp.call("kubectl --namespace dkube delete secret dkube-github-app-secret",shell=True, executable='/bin/bash'):
			pretty_red("Failed to delete dkube-ui-secret")
			sys.exit(1)


def create_namespace(ns_name):
	if sp.call("kubectl get namespaces %s &> /dev/null"%ns_name,shell=True, executable='/bin/bash'):
		if sp.call("kubectl create namespace %s"%ns_name,shell=True, executable='/bin/bash'):
			pretty_red("Failed to create namespace %s"%ns_name)
			sys.exit(1)


def delete_namespace(ns_name):
	if not sp.call("kubectl get namespaces %s &> /dev/null"%ns_name,shell=True, executable='/bin/bash'):
		sp.call("kubectl delete namespace %s"%ns_name,shell=True, executable='/bin/bash')

def install_kubeflow():
	os.chdir(KUBEFLOW_PATH)

	create_namespace("kubeflow")
	time.sleep(1)

	sp.call("ks env set %s --namespace kubeflow"%KF_ENV,shell=True, executable='/bin/bash')
	if sp.call("ks apply %s -c kubeflow-core"%KF_ENV,shell=True, executable='/bin/bash'):
		pretty_red("Applying kubeflow-core component Failed")
		sys.exit(1)
	time.sleep(1)

def kubeflow_delete():
	os.chdir(KUBEFLOW_PATH)

	sp.call("ks env set %s --namespace kubeflow"%KF_ENV,shell=True, executable='/bin/bash')
	if sp.call("ks delete %s -c kubeflow-core"%KF_ENV,shell=True, executable='/bin/bash'):
		pretty_red("Deleting kubeflow-core component Failed")
		sys.exit(1)
	time.sleep(1)

	delete_namespace("kubeflow")
	os.chdir(BASE_DIR)
	shutil.rmtree(KUBEFLOW_PATH)

def init_dkube():
	os.chdir(BASE_DIR)
	if os.path.isdir(DKUBE_PATH):
		shutil.rmtree(DKUBE_PATH)

	if sp.call("ks init dkube",shell=True, executable='/bin/bash'):
		pretty_red("ks init dkube Failed")
		sys.exit(1)
	time.sleep(1)
	os.chdir(DKUBE_PATH)
	if sp.call("ks registry add dkube github.com/mak-454/dkube-install/tree/master/ksonnet",shell=True, executable='/bin/bash'):
		pretty_red("Failed to add dkube registry")
		sys.exit(1)
	time.sleep(1)

	sp.call("ks pkg install dkube/spinner",shell=True, executable='/bin/bash')
	time.sleep(1)
	sp.call("ks pkg install dkube/ui",shell=True, executable='/bin/bash')
	time.sleep(1)
	sp.call("ks pkg install dkube/user",shell=True, executable='/bin/bash')
	time.sleep(1)
	sp.call("ks pkg install dkube/argo",shell=True, executable='/bin/bash')
	time.sleep(1)
	sp.call("ks pkg install dkube/minio",shell=True, executable='/bin/bash')
	time.sleep(1)
	sp.call("ks pkg install dkube/efk",shell=True, executable='/bin/bash')
	time.sleep(1)
	sp.call("ks pkg install dkube/monitoring",shell=True, executable='/bin/bash')
	time.sleep(1)

	if sp.call("ks generate dkube-spinner dkube-spinner",shell=True, executable='/bin/bash'):
		pretty_red("Failed to generate dkube-spinner")
		sys.exit(1)
	time.sleep(1)

	if sp.call("ks generate dkube-ui dkube-ui",shell=True, executable='/bin/bash'):
		pretty_red("Failed to generate dkube-ui")
		sys.exit(1)
	time.sleep(1)

	if sp.call("ks generate dkube-user dkube-user",shell=True, executable='/bin/bash'):
		pretty_red("Failed to generate dkube-user")
		sys.exit(1)
	time.sleep(1)

	if sp.call("ks generate argo argo",shell=True, executable='/bin/bash'):
		pretty_red("Failed to generate argo")
		sys.exit(1)
	time.sleep(1)

	if sp.call("ks generate minio minio",shell=True, executable='/bin/bash'):
		pretty_red("Failed to generate minio")
		sys.exit(1)
	time.sleep(1)

	if sp.call("ks generate efk efk",shell=True, executable='/bin/bash'):
		pretty_red("Failed to generate efk")
		sys.exit(1)
	time.sleep(1)

	if sp.call("ks generate monitoring monitoring",shell=True, executable='/bin/bash'):
		pretty_red("Failed to generate monitoring")
		sys.exit(1)
	time.sleep(1)

def install_dkube_deps():
    os.chdir(DKUBE_PATH)

    create_namespace("dkube")
    if sp.call("ks apply default -c argo",shell=True, executable='/bin/bash'):
        pretty_red("Installing argo Failed")
        sys.exit(1)
	
    if sp.call("ks apply default -c minio",shell=True, executable='/bin/bash'):
        pretty_red("Installing minio Failed")
        sys.exit(1)
    time.sleep(30)

    if not os.path.isfile('/usr/local/bin/mc'):
        sp.call("wget https://dl.minio.io/client/mc/release/linux-amd64/mc",shell=True, executable='/bin/bash')
        sp.call("chmod +x mc",shell=True, executable='/bin/bash')
        sp.call("cp mc /usr/local/bin/mc",shell=True, executable='/bin/bash')

    if sp.call("mc config host add minio http://10.96.0.22:9000 dkube dkube123",shell=True, executable='/bin/bash'):
        pretty_red("minio config Failed")
        sys.exit(1)
	
    if sp.call("mc mb minio/dkube",shell=True, executable='/bin/bash'):
        pretty_red("minio bucket create Failed")
        sys.exit(1)
	
    if sp.call("ks apply default -c efk",shell=True, executable='/bin/bash'):
        pretty_red("Installing efk Failed")
        sys.exit(1)
	
	
def install_dkube(DOCKER_USER, DOCKER_PASSWORD, DOCKER_EMAIL):
	os.chdir(DKUBE_PATH)

	create_namespace("dkube")
	if not os.path.isdir('/var/dkube/'):
		os.makedirs('/var/dkube/')

	create_secret("dkube", DOCKER_USER, DOCKER_PASSWORD, DOCKER_EMAIL)
	if sp.call("ks apply default -c dkube-spinner",shell=True, executable='/bin/bash'):
		pretty_red("Installing dkube-spinner Failed")
		sys.exit(1)
	time.sleep(1)

def install_dkube_ui(client_id, client_secret):
	os.chdir(DKUBE_PATH)

	create_namespace("dkube")
	sp.call("ks param set dkube-ui gitClientId %s"%client_id,shell=True, executable='/bin/bash')
	sp.call("ks param set dkube-ui gitClientSecret %s"%client_secret,shell=True, executable='/bin/bash')
	if sp.call("ks apply default -c dkube-ui",shell=True, executable='/bin/bash'):
		pretty_red("dkube-ui installation Failed")
		sys.exit(1)

def install_dkube_monitoring(DOCKER_USER, DOCKER_PASSWORD, DOCKER_EMAIL):
	
	os.chdir(DKUBE_PATH)
	if sp.call("helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/",shell=True, executable='/bin/bash'):
		pretty_red("help repo add Failed")
		sys.exit(1)
	if sp.call("helm repo update",shell=True, executable='/bin/bash'):
		pretty_red("helm update Failed")
		sys.exit(1)
	if sp.call("helm install coreos/prometheus-operator --name prometheus-operator --namespace monitoring",shell=True, executable='/bin/bash'):
		pretty_red("prometheus-operator install Failed")
		sys.exit(1)
	if sp.call("helm install coreos/kube-prometheus --name kube-prometheus --set global.rbacEnable=true --namespace monitoring",shell=True, executable='/bin/bash'):
		pretty_red("kube-prometheus install Failed")
		sys.exit(1)
	
	create_secret("monitoring", DOCKER_USER, DOCKER_PASSWORD, DOCKER_EMAIL)

	if sp.call("ks apply default -c monitoring",shell=True, executable='/bin/bash'):
		pretty_red("monitoring component install Failed")
		sys.exit(1)
	
def delete_dkube_monitoring():
	
	os.chdir(DKUBE_PATH)
	if sp.call("ks delete default -c monitoring",shell=True, executable='/bin/bash'):
		pretty_red("monitoring component delete Failed")
		#sys.exit(1)

	delete_secret("monitoring")
	
	if not sp.call("helm ls | grep kube-prometheus > /dev/null",shell=True, executable='/bin/bash'):
	    if sp.call("helm delete --purge kube-prometheus",shell=True, executable='/bin/bash'):
	        pretty_red("kube-prometheus delete Failed")
	        sys.exit(1)
	        
	if not sp.call("helm ls | grep prometheus-operator > /dev/null",shell=True, executable='/bin/bash'):
	    if sp.call("helm delete --purge prometheus-operator",shell=True, executable='/bin/bash'):
		    pretty_red("prometheus-operator delete Failed")
		    sys.exit(1)

def deploy_all(args):
	if((not args.client_id) or (not args.client_secret)):
		cmd_help("deploy")
	else:
		CLIENT_ID = args.client_id
		CLIENT_SECRET = args.client_secret

	if ((not args.docker_username) and (not args.docker_password) and (not args.docker_email)):
		DOCKER_USER = default_dockerhub_creds[0]
		DOCKER_PASSWORD = default_dockerhub_creds[1]
		DOCKER_EMAIL = default_dockerhub_creds[2]
	elif ((args.docker_username) and (args.docker_password) and (args.docker_email)):
		DOCKER_USER = args.docker_username
		DOCKER_PASSWORD = args.docker_password
		DOCKER_EMAIL = args.docker_email
	else:
		cmd_help("deploy")
		
	pretty_green("Starting kubeflow installation ...")
	init_kubeflow()
	install_kubeflow()
	pretty_green("Kubeflow installation is done !!!")
	time.sleep(1)

	pretty_green("Starting dkube installation ...")
	init_dkube()
	install_dkube_deps()
	install_dkube(DOCKER_USER, DOCKER_PASSWORD, DOCKER_EMAIL)
	install_dkube_monitoring(DOCKER_USER, DOCKER_PASSWORD, DOCKER_EMAIL)
	pretty_green("Dkube installation is done !!!")
	time.sleep(1)

	pretty_green("Starting dkube-ui installation ...")
	create_ui_secret(CLIENT_ID, CLIENT_SECRET)
	install_dkube_ui(CLIENT_ID, CLIENT_SECRET)
	pretty_green("dKube-ui installation is done !!!")
	time.sleep(1)


def deploy_dkube(args):
	if ((not args.docker_username) and (not args.docker_password) and (not args.docker_email)):
		DOCKER_USER = default_dockerhub_creds[0]
		DOCKER_PASSWORD = default_dockerhub_creds[1]
		DOCKER_EMAIL = default_dockerhub_creds[2]
	elif ((args.docker_username) and (args.docker_password) and (args.docker_email)):
		DOCKER_USER = args.docker_username
		DOCKER_PASSWORD = args.docker_password
		DOCKER_EMAIL = args.docker_email
	else:
		cmd_help("deploy")
		
	pretty_green("Starting dkube installation ...")
	init_dkube()
	install_dkube_deps()
	install_dkube(DOCKER_USER, DOCKER_PASSWORD, DOCKER_EMAIL)
	install_dkube_monitoring(DOCKER_USER, DOCKER_PASSWORD, DOCKER_EMAIL)
	pretty_green("Dkube installation is done !!!")
	time.sleep(1)


def deploy_dkube_ui(args):
	if((not args.client_id) or (not args.client_secret)):
		cmd_help("deploy")
	else:
		CLIENT_ID = args.client_id
		CLIENT_SECRET = args.client_secret

	if ((not args.docker_username) and (not args.docker_password) and (not args.docker_email)):
		DOCKER_USER = default_dockerhub_creds[0]
		DOCKER_PASSWORD = default_dockerhub_creds[1]
		DOCKER_EMAIL = default_dockerhub_creds[2]
	elif ((args.docker_username) and (args.docker_password) and (args.docker_email)):
		DOCKER_USER = args.docker_username
		DOCKER_PASSWORD = args.docker_password
		DOCKER_EMAIL = args.docker_email
	else:
		cmd_help("deploy")
		
	pretty_green("Starting dkube-ui installation ...")
	init_dkube()
	create_secret("dkube", DOCKER_USER, DOCKER_PASSWORD, DOCKER_EMAIL)
	create_ui_secret(CLIENT_ID, CLIENT_SECRET)
	install_dkube_ui(CLIENT_ID, CLIENT_SECRET)
	pretty_green("dKube-ui installation is done !!!")
	time.sleep(1)


def deploy_kubeflow(args):
	pretty_green("Starting kubeflow installation ...")
	init_kubeflow()
	install_kubeflow()
	pretty_green("Kubeflow installation is done !!!")
	time.sleep(1)

def delete_all():
	pretty_green("Deleting dkube-ui ...")
	init_dkube()
	dkube_ui_delete()
	delete_ui_secret()
	pretty_green("Dkube-ui deletion is Done")
	time.sleep(1)

	pretty_green("Deleting dkube ...")
	delete_dkube_monitoring()
	dkube_delete()
	delete_secret("dkube")
	dkube_deps_delete()
	delete_namespace('dkube')
	pretty_green("Dkube deletion is Done")
	time.sleep(1)

	pretty_green("Deleting kubeflow ...")
	init_kubeflow()
	kubeflow_delete()
	pretty_green("Kubeflow deletion is Done")

def dkube_ui_delete():
    os.chdir(DKUBE_PATH)
    if sp.call("ks delete default -c dkube-ui",shell=True, executable='/bin/bash'):
        pretty_red("deleting dkube-ui Failed")
        sys.exit(1)

def dkube_delete():
    os.chdir(DKUBE_PATH)
    if sp.call("ks delete default -c dkube-spinner",shell=True, executable='/bin/bash'):
        pretty_red("deleting dkube-spinner Failed")
        sys.exit(1)

    time.sleep(2)
    if not sp.call("df -h | grep /var/dkube/spinner > /dev/null",shell=True, executable='/bin/bash'):
        sp.call("umount /var/dkube/spinner",shell=True, executable='/bin/bash')
        time.sleep(1)
    if os.path.isdir('/var/dkube/'):
        shutil.rmtree('/var/dkube/')
	
def dkube_deps_delete():
	os.chdir(DKUBE_PATH)

	if sp.call("ks delete default -c argo",shell=True, executable='/bin/bash'):
		pretty_red("Deleting argo Failed")
		sys.exit(1)

	if sp.call("ks delete default -c minio",shell=True, executable='/bin/bash'):
		pretty_red("Deleting minio Failed")
		sys.exit(1)

	if sp.call("ks delete default -c efk",shell=True, executable='/bin/bash'):
		pretty_red("Deleting efk Failed")
		sys.exit(1)


def delete_dkube():
	pretty_green("Deleting dkube ...")
	init_dkube()
	delete_dkube_monitoring()
	dkube_delete()
	dkube_deps_delete()
	pretty_green("Dkube deletion is Done")


def delete_dkube_ui():
	pretty_green("Deleting dkube-ui ...")
	init_dkube()
	dkube_ui_delete()
	delete_ui_secret()
	pretty_green("Dkube-ui deletion is Done")
	time.sleep(1)

def delete_kubeflow():
	pretty_green("Deleting kubeflow ...")
	init_kubeflow()
	kubeflow_delete()
	pretty_green("Kubeflow deletion is Done")

def handle_operator(args):
	if( (not args.add) or (not args.org)):
		cmd_help("operator")
	elif(args.add):
	    username = args.add
	    pretty_green("Adding operator ...")
	    operator_add(username, args.org)
	    pretty_green("Operator addition is Done ...!!!")

def handle_delete(args):
	install_ksonnet()
	option_switcher = {
		'all': delete_all,
		'dkube': delete_dkube,
		'dkube-ui': delete_dkube_ui,
		'kubeflow': delete_kubeflow,
	}

	if (args.pkg in option_switcher):
		option_switcher[args.pkg]() 
	else:
		pretty_red("Invalid option")
		cmd_help("delete")
	if os.path.isdir(DKUBE_PATH):
		shutil.rmtree(DKUBE_PATH)
	if os.path.isdir(KUBEFLOW_PATH):
		shutil.rmtree(KUBEFLOW_PATH)

def handle_deploy(args):
	os.chdir(BASE_DIR)
	install_ksonnet()
	option_switcher = {
		'all': deploy_all,
		'dkube': deploy_dkube,
		'dkube-ui': deploy_dkube_ui,
		'kubeflow': deploy_kubeflow,
	}

	if (args.pkg in option_switcher):
		option_switcher[args.pkg](args) 
	else:
		pretty_red("Invalid option")
		cmd_help("deploy")
	if os.path.isdir(DKUBE_PATH):
		shutil.rmtree(DKUBE_PATH)
	if os.path.isdir(KUBEFLOW_PATH):
		shutil.rmtree(KUBEFLOW_PATH)

def force_delete_pods():
    print("Some pods were not deleted. cleaning up forcefully ....")
    sp.call("kubectl get pod -n dkube | awk 'NR>1 {print $1}' | xargs kubectl delete pod --force --grace-period=0 -n dkube",shell=True)
    sp.call("kubectl get pod -n monitoring | awk 'NR>1 {print $1}' | xargs kubectl delete pod --force --grace-period=0 -n monitoring",shell=True)
    delete_namespace("monitoring")


def check_env():
	if not os.path.isfile('/root/.kube/config'):
		pretty_red("kubernetes config is not set at standard path")
		pretty_red("please run: \"cp /etc/kubernetes/admin.conf /root/.kube/config\" then run this script")
		sys.exit(1)

def install_ksonnet():
	os.chdir(BASE_DIR)
	if not os.path.isfile('ks_0.11.0_linux_amd64.tar.gz'):
		os.system("wget -c https://github.com/ksonnet/ksonnet/releases/download/v0.11.0/ks_0.11.0_linux_amd64.tar.gz")
	os.system("tar -xzf ks_0.11.0_linux_amd64.tar.gz")
	if os.path.exists('ks_0.11.0_linux_amd64/ks'):
		os.system("cp -r ks_0.11.0_linux_amd64/ks /usr/bin/")
	else:
		pretty_red("File Not Found: ks_0.11.0_linux_amd64/ks")
		sys.exit()


def check(RunnningStatus):
    for value in RunnningStatus:
        if value == False:
            return False
    return True    

def monitorOnDeletion():

    try:
        config.load_kube_config()
    except:
        config.load_incluster_config()

    # create an instance of the API class
    api_instance = client.ExtensionsV1beta1Api()

    namespace = 'dkube' # str | object name and auth scope, such as for teams and projects
    pretty = 'pretty_example' # str | If 'true', then the output is pretty printed. (optional)
    exact = True # bool | Should the export be exact.  Exact export maintains cluster-specific fields like 'Namespace'. (optional)

    deploymentList = ['ambassador','dkube-spinner','dkube-ui','kibana-logging','minio-deployment','workflow-controller']
    daemonsetName = 'fluentd-es'
    RunnningStatus = []

    for name in deploymentList:
        try:
            api_response = api_instance.read_namespaced_deployment(name, namespace, exact=exact, async=False)
            RunnningStatus.append(False)
        except ApiException as e:
            if e.status == 404:
                RunnningStatus.append(True)
            else:
                RunnningStatus.append(False)
    # get the daemonSet
    try:
        api_response = api_instance.read_namespaced_daemon_set(daemonsetName, namespace, exact=exact,async=False)
        RunnningStatus.append(False)
    except ApiException as e:
        if e.status == 404:
            RunnningStatus.append(True)
        else:
            RunnningStatus.append(False)

    try:
        v1_api_instance = client.AppsV1Api()
        api_response = v1_api_instance.read_namespaced_stateful_set('elasticsearch-logging', namespace, exact=exact,async=False)
        RunnningStatus.append(False)
    except ApiException as e:
        if e.status == 404:
            RunnningStatus.append(True)
        else:
            RunnningStatus.append(False)

    status = check(RunnningStatus)
    v1 = client.CoreV1Api()
    listOfPods = v1.list_namespaced_pod(namespace)
    if len(listOfPods.items) == 0 and status: 
        return True
    else:
        return False


def monitorOnCreation():

    try:
        config.load_kube_config()
    except:
        config.load_incluster_config()

    # create an instance of the API class
    api_instance = client.ExtensionsV1beta1Api()

    namespace = 'dkube' # str | object name and auth scope, such as for teams and projects
    exact = True # bool | Should the export be exact.  Exact export maintains cluster-specific fields like 'Namespace'. (optional)

    deploymentList = ['ambassador','dkube-spinner','dkube-ui','kibana-logging','minio-deployment','workflow-controller']
    daemonsetName = 'fluentd-es'
    RunnningStatus = []

    for name in deploymentList:
        try:
            api_response = api_instance.read_namespaced_deployment(name, namespace, exact=exact, async=False)
            if api_response.status.replicas == api_response.status.ready_replicas:
                RunnningStatus.append(True)
            else:
                RunnningStatus.append(False) 
        except ApiException as e:
                RunnningStatus.append(False)
    # get the daemonSet
    try: 
        api_response = api_instance.read_namespaced_daemon_set(daemonsetName, namespace, exact=exact,async=False)
        if  api_response.status.desired_number_scheduled == api_response.status.number_ready:
            RunnningStatus.append(True)
        else:
            RunnningStatus.append(False)
    except ApiException as e:
        RunnningStatus.append(False)
    try:
        v1_api_instance = client.AppsV1Api()
        api_response = v1_api_instance.read_namespaced_stateful_set('elasticsearch-logging', namespace, exact=exact,async=False)
        if api_response.status.replicas == api_response.status.ready_replicas:
            RunnningStatus.append(True)
        else:
	        RunnningStatus.append(False)	
    except ApiException as e:
	    RunnningStatus.append(False)
 
    return check(RunnningStatus)


def prettyTable(status):
    from prettytable import PrettyTable

    print("\n\n")
    pretty_blue("Dkube Components Status")

    a = "success"
    b = "failed"
    t = PrettyTable(['Component', 'Status'])

    if status:
        status = "\033[1;32m%s\033[0m" %a
    else:
        status = "\033[1;31m%s\033[0m" %b

    t.add_row(['kubeflow', status])
    t.add_row(['dkube', status])
    t.add_row(['dkube-ui', status])
    t.add_row(['argo', status])
    t.add_row(['minio', status])
    t.add_row(['efk', status])

    t.align = 'l'
    t.right_padding_width = 20
 
    print(t)

def pretty(delete=False):
    import random
    from time import sleep

    from blessings import Terminal

    from progressive.bar import Bar
    from progressive.tree import ProgressTree, Value, BarDescriptor

    leaf_values = [Value(0) for i in range(1)]
    bd_defaults = dict(type=Bar, kwargs=dict(max_value=900))

    test_d = {
        "Verifying [kubeflow]": BarDescriptor(value=leaf_values[0], **bd_defaults),
        "Verifying [dkube]": BarDescriptor(value=leaf_values[0], **bd_defaults),
        "Verifying [dkube-ui]": BarDescriptor(value=leaf_values[0], **bd_defaults),
        "Verifying [argo]": BarDescriptor(value=leaf_values[0], **bd_defaults),
        "Verifying [minio]": BarDescriptor(value=leaf_values[0], **bd_defaults),
        "Verifying [efk]": BarDescriptor(value=leaf_values[0], **bd_defaults)
    }

    # We'll use this function to bump up the leaf values
    def incr_value(obj):
        for val in leaf_values:
            if val.value < 900:
                val.value += 10
                break

    # And this to check if we're to stop drawing
    def are_we_done(obj):
        return all(val.value == 900 for val in leaf_values)

    ###################
    # The actual code #
    ###################

    # Create blessings.Terminal instance
    t = Terminal()
    # Initialize a ProgressTree instance
    n = ProgressTree(term=t)
    # We'll use the make_room method to make sure the terminal
    #   is filled out with all the room we need
    n.make_room(test_d)

    monitor_freq = 0
    status = False
    while not status and not are_we_done(test_d):
        if monitor_freq >= 60:
            if not delete:
            	status = monitorOnCreation()
            else:
                status = monitorOnDeletion()
            monitor_freq = 0
        # After the cursor position is first saved (in the first draw call)
        #   this will restore the cursor back to the top so we can draw again
        n.cursor.restore()
        # We use our incr_value method to bump the fake numbers
        incr_value(test_d)
        # Actually draw out the bars
        n.draw(test_d, BarDescriptor(bd_defaults))
        sleep(10)
        monitor_freq += 10
    return status



def run():
	check_running_user()

	parser = argparse.ArgumentParser(description="Dkube installer")
	parser.add_argument("cmd", help="Cmd to perform <deploy, delete, operator>")
	parser.add_argument("--pkg", help="Packages to install <all, kubeflow, dkube, dkube-ui>")
	parser.add_argument("--add", help="Username of operator to be added")
	#parser.add_argument("--delete", help="Username of operator to be deleted")
	parser.add_argument("--org", help="name of the organization for operator")
	parser.add_argument("--client_id", help="Client ID for git OAuth app")
	parser.add_argument("--client_secret", help="Client Secret for git OAuth app")
	parser.add_argument("--docker_username", help="Username for docker hub")
	parser.add_argument("--docker_password", help="Password for docker hub")
	parser.add_argument("--docker_email", help="Email id for docker hub")
	parser.add_argument("--git_username", help="Username for github")
	if len(sys.argv)==1:
		parser.print_help(sys.stderr)
		sys.exit(1)
	args = parser.parse_args()

	params = sys.argv[1:]
	if( not params ):
		dkube_installer_help()

	check_env()

	cmd_switcher = {
		'deploy': handle_deploy,
		'delete': handle_delete,
		'operator': handle_operator,
	}

	if (args.cmd in cmd_switcher):
		cmd_switcher[args.cmd](args) 
	else:
		pretty_red("Invalid cmd")
		dkube_installer_help()

	# Dkube Monitoring
	if ((args.cmd == "deploy") and (args.pkg == "all")):
		print("\n")
		pretty_blue("Verifying deployment ... ")
		status = pretty()
		prettyTable(status)
		if status:
		    external_access_ip = find_master_ip()
		    print("\n")
		    pretty_green("('\u2714') Dkube deployed and available @ http://%s:32222/dkube/ui/ , The IP address in the link is master node IP address"%external_access_ip)
		else:
			print("\n")
			pretty_red("('\u274c') Dkube deploy failed. For reinstall, see below instructions")
			pretty_blue("     dkubectl delete --pkg all")
			pretty_blue("     dkubectl deploy --pkg all [--client_id <git-app-client-id>] [--client_secret <git-app-client-secret>] [--docker_username <docker_username>] [--docker_password <docker-password>] [--docker_email <docker-email>]")

	if ((args.cmd == "delete") and (args.pkg == "all")):
		try:
			force_delete_pods()
		except:
			print("")
		print("\n")
		pretty_blue("Verifying deletion ... ")
		status = pretty(delete=True)
		prettyTable(status)
		if status:
			print("\n")
			pretty_green("('\u2714') Dkube deleted ")
		else:
			pretty_red("('\u274c') Dkube delete failed. Retry again with same command ")

