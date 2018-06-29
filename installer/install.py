import subprocess as sp
import re
import sys
import time
import monitor

dkubeScript = """#!/bin/bash

pretty_green()
{
    echo -e "\e[1;32m[Dkube Installer] $@ \e[0m"
}

pretty_red()
{
    echo -e "\e[1;31m[Dkube Installer] $@ \e[0m"
}

pretty_blue()
{
    echo -e "\n\n\e[1;34m[Dkube Installer] $@ \e[0m\n"
}

if [[ $EUID -ne 0 ]]; then
   pretty_red "This script must be run as root" 
   exit 1
fi

if [[ $# -lt 2 ]]; then
    pretty_red "SYNTAX: " $0 "<cmd: deploy, delete, onboard> <option: --all, --dkube-deps, --dkube, --dkube-ui, --kubeflow> [--client-id <git-app-client-id>] [--client-secret <git-app-client-secret>] [--docker-username <docker-username>] [--docker-password <docker-password>] [--docker-email <docker-email>] [--git-username <git-username>]"
    exit 1
fi

BASE_DIR="/tmp"
DKUBE_PATH="${BASE_DIR}/dkube"
KUBEFLOW_APPNAME="my-kubeflow"
KUBEFLOW_PATH="${BASE_DIR}/${KUBEFLOW_APPNAME}"
KF_ENV=nocloud
VERSION=v0.1.2


check_env()
{
    if [ ! -f ${HOME}/.kube/config ]; then
        pretty_red "kubernetes config is not set at standard path"
        pretty_red "please run: \"cp /etc/kubernetes/admin.conf ~/.kube/config\" then this script"
        exit 1
    else
        export MASTER_IP=$(cat ${HOME}/.kube/config | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
        pretty_green "MASTER_IP: "$MASTER_IP " From ${HOME}/.kube/config"
    fi
}

export_env()
{
    pretty_green "Exporting env ..."
    if [ -f "/etc/kubernetes/admin.conf" ]; then
        mkdir -p $HOME/.kube
        cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        export MASTER_IP=$(cat ${HOME}/.kube/config | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
        pretty_green "MASTER_IP: "$MASTER_IP
    else
        pretty_red "File Not Found: /etc/kubernetes/admin.conf"
        exit 1
    fi
}

user_onbord()
{
    cd $DKUBE_PATH
    ks param set dkube-user username $GIT_USERNAME
    ks apply default -c dkube-user
    if [ ! $? -eq 0 ]; then
        pretty_red "User onboarding Failed"
        exit 1
    fi
}

install_ksonnet()
{
    cd $BASE_DIR
    if [ ! -f 'ks_0.11.0_linux_amd64.tar.gz' ]; then
        wget -c https://github.com/ksonnet/ksonnet/releases/download/v0.11.0/ks_0.11.0_linux_amd64.tar.gz
    fi    

    tar -xzf ks_0.11.0_linux_amd64.tar.gz

    if [ -f 'ks_0.11.0_linux_amd64/ks' ]; then
        cp -r ks_0.11.0_linux_amd64/ks /usr/bin/
    else
        pretty_red "File Not Found: ks_0.11.0_linux_amd64/ks"
        exit 1
    fi
    cd -
}

init_kubeflow()
{
    cd $BASE_DIR
    if [ -d $KUBEFLOW_APPNAME ]; then
        rm -rf $KUBEFLOW_APPNAME
    fi

    ks init $KUBEFLOW_APPNAME
    if [ ! -d $KUBEFLOW_APPNAME ]; then
        pretty_red "ks init $KUBEFLOW_APPNAME Failed"
        exit 1
    fi

    cd $KUBEFLOW_APPNAME
    ks registry add kubeflow github.com/kubeflow/kubeflow/tree/${VERSION}/kubeflow
    if [ ! $? -eq 0 ]; then
        pretty_red "Adding kubeflow registry Failed"
        exit 1
    fi
    sleep 1

    ks pkg install kubeflow/core@${VERSION}
    if [ ! $? -eq 0 ]; then
        pretty_red "installing kubeflow/core Failed"
        exit 1
    fi
    sleep 1

    ks pkg install kubeflow/tf-serving@${VERSION}
    if [ ! $? -eq 0 ]; then
        pretty_red "installing kubeflow/tf-serving Failed"
        exit 1
    fi
    sleep 1

    ks pkg install kubeflow/tf-job@${VERSION}
    if [ ! $? -eq 0 ]; then
        pretty_red "installing kubeflow/tf-job Failed"
        exit 1
    fi
    sleep 1

    ks generate core kubeflow-core --name=kubeflow-core
    if [ ! $? -eq 0 ]; then
        pretty_red "Creating Kubeflow core component Failed"
        exit 1
    fi
    sleep 1

    ks param set kubeflow-core reportUsage true
    sleep 1

    ks param set kubeflow-core usageId $(uuidgen)
    sleep 1

    ks env add nocloud
    if [ ! $? -eq 0 ]; then
        pretty_red "adding env Failed"
        exit 1
    fi
    sleep 1


}

create_kubeflow_namespace()
{
    RES=$(kubectl get namespaces | grep kubeflow)

    if [ $? != 0 ]; then
        kubectl create namespace kubeflow
        RES=$(kubectl get namespaces | grep kubeflow)
        pretty_green $RES
    fi
}

install_kubeflow()
{
    cd $BASE_DIR
    cd $KUBEFLOW_APPNAME
    create_kubeflow_namespace
    sleep 1

    ks env set ${KF_ENV} --namespace kubeflow
    sleep 1

    ks apply ${KF_ENV} -c kubeflow-core
    if [ ! $? -eq 0 ]; then
        pretty_red "Applying kubeflow-core component Failed"
        exit 1
    fi
    sleep 1
}

create_dkube_db()
{
    if [ ! -f '/var/dkube/' ]; then
        pretty_green "creating dkube.db"
        mkdir -p /var/dkube/
    fi
    
}

delete_dkube_db()
{
    if [ -f '/var/dkube/' ]; then
        rm -f /var/dkube/
    fi
}


create_dkube_namespace()
{
    RES=$(kubectl get namespaces | grep dkube)

    if [ $? != 0 ]; then
        kubectl create namespace dkube
        RES=$(kubectl get namespaces | grep dkube)
        pretty_green $RES
    fi
}

create_dkube_secret()
{
    kubectl --namespace dkube create secret docker-registry dkube-dockerhub-secret --docker-server=https://index.docker.io/v1/ --docker-username=$DOCKER_USER --docker-password=$DOCKER_PASSWORD --docker-email=$DOCKER_EMAIL
    if [ ! $? -eq 0 ]; then
        pretty_red "Failed to create dkube-secret"
        exit 1
    fi

}

create_ui_secret()
{
    kubectl --namespace dkube create secret generic dkube-github-app-secret --from-literal=client-id=$CLIENT_ID --from-literal=client-secret=$CLIENT_SECRET
    if [ ! $? -eq 0 ]; then
        pretty_red "Failed to create dkube-ui-secret"
        exit 1
    fi
}

delete_dkube_secret()
{
    kubectl --namespace dkube delete secret dkube-dockerhub-secret
    if [ ! $? -eq 0 ]; then
        pretty_red "Failed to delete dkube-secret"
        exit 1
    fi
}

delete_ui_secret()
{
    kubectl --namespace dkube delete secret dkube-github-app-secret
    if [ ! $? -eq 0 ]; then
        pretty_red "Failed to delete dkube-ui-secret"
        exit 1
    fi
}

init_dkube()
{
    cd $BASE_DIR

    if [ -d dkube ]; then
        rm -rf dkube
    fi

    ks init dkube
    if [ ! -d dkube ]; then
        pretty_red "dkube init failed"
        exit 1
    fi
    cd dkube

    ks registry add dkube github.com/mak-454/dkube-install/tree/master/ksonnet
    if [ ! $? -eq 0 ]; then
        pretty_red "Failed to add dkube registry"
        exit 1
    fi
    sleep 1
    
    ks pkg install dkube/spinner
    sleep 1
    ks pkg install dkube/ui
    sleep 1
    ks pkg install dkube/argo
    sleep 1
    ks pkg install dkube/nfs
    sleep 1
    ks pkg install dkube/efk
    sleep 1
    ks pkg install dkube/pachyderm
    sleep 1
    ks pkg install dkube/user
    sleep 1

    ks generate dkube-spinner dkube-spinner
    if [ ! $? -eq 0 ]; then
        pretty_red "Failed to generate dkube-spinner"
        exit 1
    fi
    sleep 1
    ks generate dkube-ui dkube-ui
    if [ ! $? -eq 0 ]; then
        pretty_red "Failed to generate dkube-ui"
        exit 1
    fi
    sleep 1
    ks generate argo argo
    if [ ! $? -eq 0 ]; then
        pretty_red "Failed to generate argo"
        exit 1
    fi
    sleep 1
    ks generate nfs nfs
    if [ ! $? -eq 0 ]; then
        pretty_red "Failed to generate nfs"
        exit 1
    fi
    sleep 1
    ks generate efk efk
    if [ ! $? -eq 0 ]; then
        pretty_red "Failed to generate efk"
        exit 1
    fi
    sleep 1
    ks generate pachyderm pachyderm
    if [ ! $? -eq 0 ]; then
        pretty_red "Failed to generate pachyderm"
        exit 1
    fi
    sleep 1
    ks generate dkube-user dkube-user
    if [ ! $? -eq 0 ]; then
        pretty_red "Failed to generate dkube-user"
        exit 1
    fi
    sleep 1

}

install_dkube_deps()
{
    cd $DKUBE_PATH
    if [ ! -d '/var/dkube/' ]; then
        mkdir -p '/var/dkube/'
    fi
    create_dkube_namespace

    ks apply default -c argo
    if [ ! $? -eq 0 ]; then
        pretty_red "Installing argo Failed"
        exit 1
    fi
    ks apply default -c nfs
    if [ ! $? -eq 0 ]; then
        pretty_red "Installing nfs Failed"
        exit 1
    fi
    ks apply default -c efk
    if [ ! $? -eq 0 ]; then
        pretty_red "Installing efk Failed"
        exit 1
    fi
    ks apply default -c pachyderm
    if [ ! $? -eq 0 ]; then
        pretty_red "Installing pachyderm Failed"
        exit 1
    fi
}

install_dkube()
{
    cd $DKUBE_PATH
    create_dkube_namespace
    create_dkube_db
    ks apply default -c dkube-spinner 
    if [ ! $? -eq 0 ]; then
        pretty_red "Installing dkube Failed"
        exit 1
    fi
     
}

install_dkube_ui()
{
    cd $DKUBE_PATH
    ks param set dkube-ui restServerEndpoint http://$MASTER_IP:32222
    sleep 2
    ks param set dkube-ui gitClientId $CLIENT_ID
    sleep 2
    ks param set dkube-ui gitClientSecret $CLIENT_SECRET
    sleep 2
    ks apply default -c dkube-ui
    if [ ! $? -eq 0 ]; then
        pretty_red "dkube-ui installation Failed"
        exit 1
    fi
}

delete_dkube_ui()
{
    cd $DKUBE_PATH
    ks delete default -c dkube-ui
    if [ ! $? -eq 0 ]; then
        pretty_red "deleting dkube-ui Failed"
        exit 1
    fi
}

delete_dkube()
{
    cd $DKUBE_PATH
    ks delete default -c dkube-spinner
    if [ ! $? -eq 0 ]; then
        pretty_red "deleting dkube Failed"
        exit 1
    fi
    sleep 2
    kubectl delete namespace dkube
    delete_dkube_db
}

delete_dkube_deps()
{
    cd $DKUBE_PATH
    ks delete default -c argo
    if [ ! $? -eq 0 ]; then
        pretty_red "Deleting argo Failed"
        exit 1
    fi
    ks delete default -c nfs
    if [ ! $? -eq 0 ]; then
        pretty_red "Deleting nfs Failed"
        exit 1
    fi
    ks delete default -c efk
    if [ ! $? -eq 0 ]; then
        pretty_red "Deleting efk Failed"
        exit 1
    fi
    ks delete default -c pachyderm
    if [ ! $? -eq 0 ]; then
        pretty_red "Deleting pachyderm Failed"
        exit 1
    fi
    ks delete default -c dkube-user
    if [ ! $? -eq 0 ]; then
        pretty_red "Deleting dkube-user Failed"
        exit 1
    fi

    if [ -d '/var/dkube/' ]; then
        rm -rf '/var/dkube/'
    fi
}

delete_kubeflow()
{
    cd $BASE_DIR
    cd $KUBEFLOW_APPNAME
    ks env set ${KF_ENV} --namespace kubeflow
    ks delete ${KF_ENV} -c kubeflow-core
    if [ ! $? -eq 0 ]; then
        pretty_red "deleting kubeflow Failed"
        exit 1
    fi
    sleep 2
    kubectl delete namespace kubeflow
    cd $BASE_DIR
    rm -rf $KUBEFLOW_APPNAME
}

main_fun()
{
    cmd=$1
    option=$2

    check_env
    case ${cmd} in
        deploy)

            install_ksonnet
            case ${option} in
                --all)
                    if [ $# -ne 12 ] || [ "$3" != "--client-id" ] || [ "$5" != "--client-secret" ] || [ "$7" != "--docker-username" ] || [ "$9" != "--docker-password" ] || [ "${11}" != "--docker-email" ]; then
                        pretty_red "SYNTAX: " $0 "deploy <option: --all, --dkube-deps, --dkube, --dkube-ui, --kubeflow> --client-id <git-app-client-id> --client-secret <git-app-client-secret> --docker-username <docker-username> --docker-password <docker-password> --docker-email <docker-email>"
                        exit 1
                    else
                        export CLIENT_ID=$4
                        export CLIENT_SECRET=$6
                        export DOCKER_USER=$8
                        export DOCKER_PASSWORD=${10}
                        export DOCKER_EMAIL=${12}
                    fi

                    pretty_green "Starting kubeflow installation..."
                    init_kubeflow
                    install_kubeflow            
                    pretty_green "Kubeflow installation is done !!!"
                    sleep 1

                    pretty_green "Starting dkube-deps installation ..."
                    init_dkube
                    install_dkube_deps
                    pretty_green "Dkube deps installation is done !!!"
                    sleep 1

                    pretty_green "Starting dkube installation ..."
                    create_dkube_secret
                    install_dkube
                    pretty_green "Dkube installation is Done !!!"
                    sleep 1

                    pretty_green "Starting dkube-ui installation ..."
                    create_ui_secret
                    install_dkube_ui
                    pretty_green "Dkube UI installation is Done !!!"
                    ;;

                --dkube-deps)
                    pretty_green "Starting dkube-deps installation ..."
                    init_dkube
                    install_dkube_deps
                    pretty_green "Dkube-deps installation is Done !!!"
                    ;;

                --kubeflow)
                    pretty_green "Starting kubeflow installation ..."
                    init_kubeflow
                    install_kubeflow            
                    pretty_green "kubeflow installation is Done !!!"
                    ;;

                --dkube)
                    if [ $# -ne 8 ] || [ "$3" != "--docker-username" ] || [ "$5" != "--docker-password" ] || [ "$7" != "--docker-email" ]; then
                        pretty_red "SYNTAX: " $0 "deploy --dkube --docker-username <docker-username> --docker-password <docker-password> --docker-email <docker-email>"
                        exit 1
                    else
                        export DOCKER_USER=$4
                        export DOCKER_PASSWORD=$6
                        export DOCKER_EMAIL=$8
                    fi
                    pretty_green "Starting dkube installation ..."
                    init_dkube
                    create_dkube_secret
                    install_dkube
                    pretty_green "Dkube installation is Done !!!"
                    ;;
                --dkube-ui)
                    if [ $# -ne 12 ] || [ "$3" != "--client-id" ] || [ "$5" != "--client-secret" ] || [ "$7" != "--docker-username" ] || [ "$9" != "--docker-password" ] || [ "$11" != "--docker-email" ]; then
                        pretty_red "SYNTAX: " $0 "deploy <option: --all, --dkube-deps, --dkube, --dkube-ui, --kubeflow> --client-id <git-app-client-id> --client-secret <git-app-client-secret> --docker-username <docker-username> --docker-password <docker-password> --docker-email <docker-email>"
                        exit 1
                    else
                        export CLIENT_ID=$4
                        export CLIENT_SECRET=$6
                        export DOCKER_USER=$8
                        export DOCKER_PASSWORD=$10
                        export DOCKER_EMAIL=$12
                    fi

                    pretty_green "Starting dkube-ui installation ..."
                    init_dkube
                    create_ui_secret
                    install_dkube_ui
                    pretty_green "Dkube-ui installation is Done !!!"
                    ;;
 
               *)
                    pretty_red "Invalid option ${option}"
                    pretty_red "SYNTAX: " $0 "deploy <option: --all, --dkube-deps, --dkube, --dkube-ui, --kubeflow> [--client-id <git-app-client-id>] [--client-secret <git-app-client-secret>] --docker-username <docker-username> --docker-password <docker-password> --docker-email <docker-email>"
                    exit 1
                    ;;
            esac

            if [ -d $DKUBE_PATH ]; then
                rm -rf $DKUBE_PATH
            fi
            if [ -d $KUBEFLOW_PATH ]; then
                rm -rf $KUBEFLOW_PATH
            fi
            pretty_blue "Verifying installation ..."
            ;;

        delete)

            case ${option} in
                --all)

                    pretty_green "Deleting dkube-ui ..."
                    init_dkube
                    delete_dkube_ui
                    delete_ui_secret
                    pretty_green "Dkube-ui deletion is Done"
                    sleep 1

                    pretty_green "Deleting dkube ..."
                    delete_dkube
                    delete_dkube_secret
                    pretty_green "Dkube deletion is Done"
                    sleep 1

                    pretty_green "Deleting dkube-deps ..."
                    delete_dkube_deps
                    pretty_green "Dkube-deps deletion is Done"
                    sleep 1

                    pretty_green "Deleting kubeflow ..."
                    init_kubeflow
                    delete_kubeflow            
                    pretty_green "Kubeflow deletion is Done"
                   ;;

                --dkube-deps)
                    pretty_green "Deleting dkube-deps ..."
                    init_dkube
                    delete_dkube_deps
                    pretty_green "Dkube-deps deletion is Done"
                    ;;

                --kubeflow)
                    pretty_green "Deleting kubeflow ..."
                    init_kubeflow
                    delete_kubeflow            
                    pretty_green "Kubeflow deletion is Done"
                    ;;

                --dkube)
                    pretty_green "Deleting dkube ..."
                    init_dkube
                    delete_dkube
                    delete_dkube_secret
                    pretty_green "Dkube deletion is Done"
                    ;;

                --dkube-ui)
                    pretty_green "Deleting dkube-deps ..."
                    init_dkube
                    delete_dkube_ui
                    delete_ui_secret
                    pretty_green "Dkube-ui deletion is Done"
                    ;;

                *)
                    pretty_red "Invalid option ${option}"
                    pretty_red "SYNTAX: " $0 "delete <option: --all, --dkube-deps, --dkube, --dkube-ui, --kubeflow>"
                    exit 1
                    ;;
            esac

            if [ -d $DKUBE_PATH ]; then
                rm -rf $DKUBE_PATH
            fi
            if [ -d $KUBEFLOW_PATH ]; then
                rm -rf $KUBEFLOW_PATH
            fi
            pretty_blue "Verifying deletion ..."
            ;;

        onboard)
			echo $# $1 $2 $3
            if [ $# -ne 3 ] || [ "$2" != "--git-username" ]; then 
                pretty_red "SYNTAX: " $0 "onboard --git-username <git-usetname>"
                exit 1
            else
                export GIT_USERNAME=$3
            fi

            pretty_green "Onboarding user ..."
            init_dkube
            user_onbord
            pretty_green "User onboarding is Done ...!!!"
            if [ -d $DKUBE_PATH ]; then
                rm -rf $DKUBE_PATH
            fi
            ;;
        *)
            pretty_red "Invalid cmd ${cmd}"
            pretty_red "SYNTAX: " $0 "<cmd: deploy, delete, onboard> <option: --all, --dkube-deps, --dkube, --dkube-ui, --kubeflow> [--client-id <git-app-client-id>] [--client-secret <git-app-client-secret>] [--docker-username <docker-username>] [--docker-password <docker-password>] [--docker-email <docker-email>] [--git-username <git-username>]"
            exit 1
            ;;
    esac           

}

main_fun $@"""


def force_delete_pods():
	print("Some pods were not deleted. cleaning up forcefully ....")
	sp.run("kubectl get pod -n dkube | awk 'NR>1 {print $1}' | xargs kubectl delete pod --force --grace-period=0 -n dkube",shell=True)

def prettyTable(status):
    from prettytable import PrettyTable

    print("\n\n")
    print("\033[1;34m Dkube Components Status\033[0m")

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
    t.add_row(['pachyderm', status])
    t.add_row(['nfs', status])
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
        "Verifying [pachyderm]": BarDescriptor(value=leaf_values[0], **bd_defaults),
        "Verifying [nfs]": BarDescriptor(value=leaf_values[0], **bd_defaults),
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
            	status = monitor.monitorOnCreation()
            else:
                status = monitor.monitorOnDeletion()
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


def find_master_ip():
    file = open("/root/.kube/config")
    lines = file.readlines()
    line = ', '.join(lines)
    ip = re.findall( r'[0-9]+(?:\.[0-9]+){3}', line )
    ip_addr = ip[0]
    return ip_addr

def run():
    
    params = sys.argv[1:]
    default_dockerhub_creds = ["--docker-username", "lucifer001", "--docker-password", "lucifer@dkube", "--docker-email", "ocdlgit@oneconvergence.com"]
    if (("--docker-username" not in params) and ("--docker-password" not in params) and ("--docker-email" not in params) and ("onboard" not in params)):
        final_params = params + default_dockerhub_creds
    else:
        final_params = params

    proc = sp.run(['/bin/bash', '-c', dkubeScript, ""] + final_params)
    if (proc.returncode != 0):
        print (proc.stderr)
        sys.exit()

    master_ip = find_master_ip()
    if (sys.argv[1] == "deploy"):
        status = pretty()
        prettyTable(status)
        if status:
            print("\n")
            print("\033[1;32m ('\u2714') Dkube deployed and available @ http://%s:32222/dkube/ui/ \033[0m"%master_ip)
        else:
            print("\n")
            print("\033[1;31m ('\u274c') Dkube deploy failed. For reinstall, see below instructions \033[0m")
            print("\033[1;34m     dkubectl delete --all  \033[0m")
            print("\033[1;34m     dkubectl deploy --all [--client-id <git-app-client-id>] [--client-secret <git-app-client-secret>] [--docker-username <docker-username>] [--docker-password <docker-password>] [--docker-email <docker-email>]\033[0m")

    if (sys.argv[1] == "delete"):
        force_delete_pods()
        status = pretty(delete=True)
        prettyTable(status)
        if status:
            print("\n")
            print("\033[1;32m ('\u2714') Dkube deleted \033[0m")
        else:
            print("\033[1;31m ('\u274c') Dkube delete failed. Retry again with same command \033[0m")
