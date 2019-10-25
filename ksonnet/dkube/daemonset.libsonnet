{
    all(params):: [
	$.parts(params.namespace).dkubeExt(params.tag, params.dkubeExtImage, params.dkubeDockerSecret, params.minioSecretKey, params.nfsServer),
	$.parts(params.namespace).fluentd(params.tag, params.fluentdImage),
	$.parts(params.namespace).dkubeD3apiWorker(params.tag, params.dkubeApiServerImage, params.dkubeApiServerAddr, params.dkubeMountPath, params.dkubeApiServerAddr, params.rdmaEnabled, params.dkubeDockerSecret, params.minioSecretKey, params.nfsServer, params.nfsBasePath, params.dkubeRegistry, params.dkubeRegistryUname, params.dkubeRegistryPasswd, params.dkubeDownloaderImage)
    ],
    parts(namespace):: {
	dkubeExt(tag, dkubeExtImage,dkubeDockerSecret, minioSecretKey, nfsServer):: {
	    "apiVersion": "extensions/v1beta1", 
	    "kind": "DaemonSet", 
	    "metadata": {
		"labels": {
		    "app": "dkube-ext"
		}, 
		"name": "dkube-exporter-" + tag, 
		"namespace": "dkube"
	    }, 
	    "spec": {
		"imagePullSecrets": [
		{
		    "name": dkubeDockerSecret
		}
		],
		"selector": {
		    "matchLabels": {
			"app": "dkube-ext"
		    }
		}, 
		"template": {
		    "metadata": {
			"labels": {
			    "app": "dkube-ext"
			}
		    }, 
		    "spec": {
                "affinity": {
                    "nodeAffinity": {
                        "requiredDuringSchedulingIgnoredDuringExecution": {
                            "nodeSelectorTerms": [
                            {
                                "matchExpressions": [
                                {
                                    "key": "Accelerator",
                                    "operator": "Exists"
                                }
                                ]
                            }
                            ]
                        }
                    }
                },
			"containers": [
			{
			    "env": [
			    {
				"name": "MYNODENAME", 
				"valueFrom": {
				    "fieldRef": {
					"apiVersion": "v1", 
					"fieldPath": "spec.nodeName"
				    }
				}
			    }
			    ], 
			    "image": dkubeExtImage, 
			    "imagePullPolicy": "IfNotPresent", 
			    "name": "dkube-ext",
			    "securityContext": {
			        "privileged": true
			    },
			    "ports": [
			    {
				"containerPort": 9401, 
				"name": "http-metrics", 
				"protocol": "TCP"
			    }
			    ], 
			    "volumeMounts": [
			    {
			    "mountPath": "/usr/local/nvidia/lib64",
			    "name": "nvidia-lib"
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
			"imagePullSecrets": [
			{
			    "name": dkubeDockerSecret
			}
			], 
			"volumes": [
			{
			    "hostPath": {
			        "path": "/usr/lib64/nvidia"
			    },
			    "name": "nvidia-lib"
			}
			]
		    }
		}
	    }
	},
	fluentd(tag, fluentdImage):: {
	    "apiVersion": "extensions/v1beta1",
	    "kind": "DaemonSet",
	    "metadata": {
		"labels": {
		    "k8s-app": "dkube-metric-collector",
		},
		"name": "dkube-log-processor-" + tag,
		"namespace": "dkube",
	    },
	    "spec": {
		"selector": {
		    "matchLabels": {
			"k8s-app": "dkube-metric-collector",
		    }
		},
		"template": {
		    "metadata": {
			"labels": {
			    "k8s-app": "dkube-metric-collector",
			}
		    },
		    "spec": {
			"containers": [
			{
			    "image": fluentdImage,
			    "imagePullPolicy": "IfNotPresent",
			    "name": "metric-collector",
			    "resources": {},
			    "securityContext": {
                    "runAsUser": 0,
                    "procMount": "Default"
                },
			    "volumeMounts": [
			    {
				    "mountPath": "/var/lib/docker/containers",
				    "name": "varlibdockercontainers",
				    "readOnly": true
			    },
			    {
                    "mountPath": "/fluentd/etc/",
                    "name": "dkube-metric-collector",
                    "readOnly": true
                },
                {
                    "mountPath": "/var/log",
                    "name": "varlog"
                }
			    ]
			},
			{
                "image": fluentdImage,
                "imagePullPolicy": "IfNotPresent",
                "name": "log-collector",
                "resources": {},
                "securityContext": {
                    "runAsUser": 0,
                    "procMount": "Default"
                },
                "volumeMounts": [
                {
                    "mountPath": "/var/lib/docker/containers",
                    "name": "varlibdockercontainers",
                    "readOnly": true
                },
                {
                    "mountPath": "/fluentd/etc/",
                    "name": "dkube-log-collector",
                    "readOnly": true
                },
                {
                    "mountPath": "/var/log",
                    "name": "varlog"
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
			"restartPolicy": "Always",
			"schedulerName": "default-scheduler",
			"serviceAccount": "dkube",
			"volumes": [
			{
			    "hostPath": {
				"path": "/var/log",
			    },
			    "name": "varlog"
			},
			{
                "configMap": {
                    "defaultMode": 420,
                    "name": "dkube-log-collector"
                },
                "name": "dkube-log-collector"
            },
            {
                "hostPath": {
                    "path": "/var/lib/docker/containers",
                },
                "name": "varlibdockercontainers"
            },
            {
                 "configMap": {
                    "defaultMode": 420,
                    "name": "dkube-metric-collector"
                },
                "name": "dkube-metric-collector"
            
            }
			]
		    }
		},
	    },
	},
	 dkubeD3apiWorker(tag, apiServerImage, apiServerAddr, mountPath, dkubeApiServerAddr, isRdmaEnabled, dkubeDockerSecret, minioSecretKey, nfsServer, nfsBasePath, dkubeRegistry, dkubeRegistryUname, dkubeRegistryPasswd,dkubeDownloaderImage):: {
	    local dkubeApiServerAddrArray = std.split(dkubeApiServerAddr, ":"),
	    local dkubeApiServerPort = std.parseInt(dkubeApiServerAddrArray[std.length(dkubeApiServerAddrArray)-1]),

    "apiVersion": "extensions/v1beta1",
    "kind": "DaemonSet",
    "metadata": {
        "labels": {
            "app": "dkube-controller-worker"
        },
        "name": "dkube-controller-worker-" + tag,
        "namespace": namespace,
    },
    "spec": {
        "selector": {
            "matchLabels": {
                "app": "dkube-controller-worker"
            }
        },
        "template": {
            "metadata": {
                "labels": {
                    "app": "dkube-controller-worker"
                }
            },
            "spec": {
                 "affinity": {
                    "nodeAffinity": {
                        "requiredDuringSchedulingIgnoredDuringExecution": {
                            "nodeSelectorTerms": [
                            {
                                "matchExpressions": [
                                {
                                    "key": "Accelerator",
                                    "operator": "Exists"
                                }
                                ]
                            }
                            ]
                        }
                    }
                },
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
                                "value": "worker"
                            },
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
                    },
                    {
                        "image": dkubeDownloaderImage,
                        "imagePullPolicy": "IfNotPresent",
                        "name": "downloader",
                        "resources": {},
                        "securityContext": {
                            "procMount": "Default",
                            "runAsUser": 0
                        }
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
                    },
                ]
            }
        },
    },
	},

    },
}
