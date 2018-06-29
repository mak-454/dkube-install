from __future__ import print_function
from kubernetes.client.rest import ApiException
from pprint import pprint
from kubernetes import config , client


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

    deploymentList = ['ambassador','dkube-spinner','dkube-ui','etcd','kibana-logging','nfs-provisioner','pachd','workflow-controller']
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

    deploymentList = ['ambassador','dkube-spinner','dkube-ui','etcd','kibana-logging','nfs-provisioner','pachd','workflow-controller']
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

