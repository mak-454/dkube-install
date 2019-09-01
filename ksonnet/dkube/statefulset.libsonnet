{
    all(params):: [
	$.parts(params.namespace, params.nodebind).dkubeD3api(params.tag, params.dkubeApiServerImage, params.dkubeApiServerAddr, params.dkubeMountPath, params.dkubeApiServerAddr, params.rdmaEnabled, params.dkubeDockerSecret, params.minioSecretKey, params.nfsServer, params.dkubeRegistry, params.dkubeRegistryUname, params.dkubeRegistryPasswd),
    ],

    parts(namespace, nodebind):: {
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
        "replicas": 1,
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
                        "command": [
                              "bash",
                              "-c",
                              "while true;\ndo  \n    nc dkube-etcd-server.dkube 2379 -zv -w 5\n    ret1=$?\n    nc minio-service.dkube 9000 -zv -w 5\n    ret2=$?\n    if (( ret1 == 0 && ret2 == 0 )); then\n        break\n    fi\n    sleep 30\ndone\nd3\n"
                           ],
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
                            "path": "/dkube"
                        },
                        "name": "store"
                    },
                    {
                        "nfs": {
                            "path": "/dkube/system/logs/dkube",
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
