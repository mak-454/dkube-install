{
    all(params):: [
	$.parts(params.namespace, params.nodebind).dkubeD3apiMaster(params.tag, params.dkubeApiServerImage, params.dkubeApiServerAddr, params.dkubeMountPath, params.dkubeApiServerAddr, params.rdmaEnabled, params.dkubeDockerSecret, params.minioSecretKey, params.nfsServer, params.nfsBasePath, params.dkubeRegistry, params.dkubeRegistryUname, params.dkubeRegistryPasswd),
    ],

    parts(namespace, nodebind):: {
	dkubeD3apiMaster(tag, apiServerImage, apiServerAddr, mountPath, dkubeApiServerAddr, isRdmaEnabled, dkubeDockerSecret, minioSecretKey, nfsServer, nfsBasePath, dkubeRegistry, dkubeRegistryUname, dkubeRegistryPasswd):: {
	    local dkubeApiServerAddrArray = std.split(dkubeApiServerAddr, ":"),
	    local dkubeApiServerPort = std.parseInt(dkubeApiServerAddrArray[std.length(dkubeApiServerAddrArray)-1]),

    "apiVersion": "apps/v1",
    "kind": "StatefulSet",
    "metadata": {
        "labels": {
            "app": "dkube-master"
        },
        "name": "dkube-controller-master-" + tag,
        "namespace": namespace,
    },
    "spec": {
        "replicas": 1,
        "selector": {
            "matchLabels": {
                "app": "dkube-master"
            }
        },
        "serviceName": "dkube-controller-master-headless",
        "template": {
            "metadata": {
                "creationTimestamp": null,
                "labels": {
                    "app": "dkube-master"
                }
            },
            "spec": {
                "containers": [
                    {
                        "env": [
                            {
                                "name": "DKUBE_MOUNT_PATH",
                                "value": mountPath
                            },
                            {
                                "name": "DKUBE_REGISTRY",
                                "value": dkubeRegistry
                            },
                            {
                                "name": "DKUBE_REGISTRY_UNAME",
                                "value": dkubeRegistryUname
                            },
                            {
                                "name": "DKUBE_REGISTRY_PASSWD",
                                "value": dkubeRegistryPasswd
                            },
                            {
                                "name": "DKUBE_SERVICE_ACCOUNT",
                                "value": "dkube"
                            },
                            {
                                "name": "RDMA_ENABLED",
                                "value": std.toString(isRdmaEnabled)
                            },
                            {
                                "name": "NFS_SERVER",
                                "value": nfsServer
                            },
                            {
                                "name": "NFS_BASE_PATH",
                                "value": nfsBasePath
                            },
                            {
                                "name": "DKUBE_APISERVER_ROLE",
                                "value": "master"
                            },
                        ],
                        "image": apiServerImage,
                        "imagePullPolicy": "IfNotPresent",
                        "name": "main",
                        "ports": [
                            {
                                "containerPort": dkubeApiServerPort,
                                "name": "dkube-d3api",
                                "protocol": "TCP"
                            }
                        ],
                        "resources": {},
                        "securityContext": {
                            "procMount": "Default",
                            "runAsUser": 0
                        },
                        "terminationMessagePath": "/dev/termination-log",
                        "terminationMessagePolicy": "File",
                        "volumeMounts": [
                            {
                                "mountPath": mountPath,
                                "name": "store"
                            },
                            {
                                "mountPath": "/var/run/docker.sock",
                                "name": "docker"
                            },
                            {
                                "mountPath": "/var/log/dkube",
                                "name": "dkube-logs"
                            }
                        ]
                    }
                ],
                "dnsConfig": {
                    "options": [
                        {
                            "name": "single-request-reopen"
                        },
                        {
                            "name": "timeout",
                            "value": "30"
                        }
                    ]
                },
                "dnsPolicy": "ClusterFirst",
                "imagePullSecrets": [
                    {
                        "name": dkubeDockerSecret
                    }
                ],
                "nodeSelector": if nodebind == "yes" then {"d3.nodetype": "dkube"} else {},
                "restartPolicy": "Always",
                "serviceAccount": "dkube",
                "serviceAccountName": "dkube",
                "volumes": [
                    {
                        "nfs": {
                            "server": nfsServer,
                            "path": nfsBasePath + "/dkube"
                        },
                        "name": "store"
                    },
                    {
                        "nfs": {
                            "path": nfsBasePath + "/dkube/system/logs/dkube",
                            "server": nfsServer
                        },
                        "name": "dkube-logs"
                    },
                    {
                        "hostPath": {
                            "path": "/var/run/docker.sock",
                        },
                        "name": "docker"
                    }
                ]
            }
        },
    },
	}, 
    },
}
