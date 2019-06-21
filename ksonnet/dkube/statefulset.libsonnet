{
    all(params):: [
	$.parts(params.namespace).dkubeD3api(params.tag, params.dkubeApiServerImage, params.dkubeApiServerAddr, params.dkubeMountPath, params.dkubeApiServerAddr, params.rdmaEnabled, params.dkubeDockerSecret, params.minioSecretKey, params.nfsServer, params.dkubeRegistry, params.dkubeRegistryUname, params.dkubeRegistryPasswd),
    ],

    parts(namespace):: {
	dkubeD3api(tag, apiServerImage, apiServerAddr, mountPath, dkubeApiServerAddr, isRdmaEnabled, dkubeDockerSecret, minioSecretKey, nfsServer, dkubeRegistry, dkubeRegistryUname, dkubeRegistryPasswd):: {
	    local dkubeApiServerAddrArray = std.split(dkubeApiServerAddr, ":"),
	    local dkubeApiServerPort = std.parseInt(dkubeApiServerAddrArray[std.length(dkubeApiServerAddrArray)-1]),

    "apiVersion": "apps/v1",
    "kind": "StatefulSet",
    "metadata": {
        "labels": {
            "app": "dkube-d3api"
        },
        "name": "dkube-d3api-" + tag,
        "namespace": namespace,
    },
    "spec": {
        "replicas": 2,
        "selector": {
            "matchLabels": {
                "app": "dkube-d3api"
            }
        },
        "serviceName": "dkube-d3api-headless",
        "template": {
            "metadata": {
                "creationTimestamp": null,
                "labels": {
                    "app": "dkube-d3api"
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
                            }
                        ],
                        "image": apiServerImage,
                        "imagePullPolicy": "IfNotPresent",
                        "name": "dkube-d3api",
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
                                "name": "dkube-logs-host"
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
                "nodeSelector": {
                    "d3.nodetype": "dkube"
                },
                "restartPolicy": "Always",
                "serviceAccount": "dkube",
                "serviceAccountName": "dkube",
                "tolerations": [
                    {
                        "operator": "Exists"
                    }
                ],
                "volumes": [
                    {
                        "nfs": {
                            "server": nfsServer,
                            "path": "/dkube"
                        },
                        "name": "store"
                    },
                    {
                        "hostPath": {
                            "path": "/var/log/dkube",
                            "type": "DirectoryOrCreate"
                        },
                        "name": "dkube-logs-host"
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
