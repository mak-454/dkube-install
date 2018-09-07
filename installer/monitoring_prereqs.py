import subprocess as sp
import re
import sys
import time
import os
import shutil

BASE_DIR = '/tmp'

def pretty_green(msg):
        print("\033[1;32m%s\033[0m"%msg)

def pretty_red(msg):
        print("\033[1;31m%s\033[0m"%msg)

def pretty_blue(msg):
        print("\033[1;34m%s\033[0m"%msg)

def install_helm():
    os.chdir(BASE_DIR)
    if not os.path.isfile('/usr/local/bin/helm'):
        pretty_blue("Installing helm ...")
        os.system("wget -c https://storage.googleapis.com/kubernetes-helm/helm-v2.10.0-linux-amd64.tar.gz")
        os.system("tar -xzvf helm-v2.10.0-linux-amd64.tar.gz")
        if os.path.exists('linux-amd64/helm'):
            os.system("sudo cp linux-amd64/helm /usr/local/bin/helm")
        else:
            pretty_red("File Not Found: linux-amd64/helm")
            sys.exit()

def setup_helm():
    if sp.call("sudo kubectl get sa tiller -n kube-system &> /dev/null",shell=True, executable='/bin/bash'):
        pretty_blue("Create a ServiceAccount for Tiller ...")
        if sp.call("sudo kubectl -n kube-system create sa tiller",shell=True, executable='/bin/bash'):
            pretty_red("Failed to create ServiceAccount tiller")
            sys.exit(1)

    if sp.call("sudo kubectl get clusterrolebinding tiller &> /dev/null",shell=True, executable='/bin/bash'):
        pretty_blue("Create a ClusterRoleBinding for Tiller ...")
        if sp.call("sudo kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller",shell=True, executable='/bin/bash'):
            pretty_red("Failed to create ClusterRoleBinding tiller")
            sys.exit(1)

    if sp.call("sudo kubectl get pod -n kube-system | grep tiller-deploy &> /dev/null",shell=True, executable='/bin/bash'):
        pretty_blue("Install Tiller, specifying the new ServiceAccount ...")
        if sp.call("sudo helm init --service-account tiller",shell=True, executable='/bin/bash'):
            pretty_red("helm init failed")
            sys.exit(1)

def run():
    pretty_green("Setup monitoring prerequisites ...")
    install_helm()
    setup_helm()
    pretty_green("Setup monitoring prerquisites Done... !!!")

run()
