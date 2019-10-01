{
    all(params):: [
	$.parts(params.namespace, params.nodebind).logstash(params.tag, params.nfsServer, params.nfsBasePath),
	$.parts(params.namespace, params.nodebind).dkubeEtcd(params.tag, params.etcdPVC),
	$.parts(params.namespace, params.nodebind).dfabProxy(params.tag,params.dfabProxyImage, params.dkubeDockerSecret),
	$.parts(params.namespace, params.nodebind).dkubeWatcher(params.tag, params.dkubeWatcherImage, params.dkubeDockerSecret),
	$.parts(params.namespace, params.nodebind).dkubeAuth(params.tag, params.dkubeAuthImage, params.dkubeDockerSecret, params.nfsServer, params.nfsBasePath, params.dkubePubIP),
	$.parts(params.namespace, params.nodebind).ambassdor(params.tag),
	$.parts(params.namespace, params.nodebind).dkubeDownloader(params.tag, params.dkubeDownloaderImage, params.dkubeDockerSecret, params.nfsServer, params.nfsBasePath),
	$.parts(params.namespace, params.nodebind).dkubeServing(params.tag, params.dkubeInferenceImage, params.dkubeDockerSecret),
	$.parts(params.namespace, params.nodebind).dkubeDocs(params.tag, params.dkubeDocsImage, params.dkubeDockerSecret),
    ],

    parts(namespace, nodebind):: {
        local ambassadorImage = "quay.io/datawire/ambassador:0.53.1",
    dkubeServing(tag, dkubeInferenceImage, dkubeDockerSecret):: {
        "apiVersion": "extensions/v1beta1",
        "kind": "Deployment",
        "metadata": {
            "labels": {
                "app": "inference",
            },
            "name": "dkube-serving-" + tag,
            "namespace": namespace
        },
        "spec": {
            "replicas": 1,
            "selector": {
                "matchLabels": {
                    "app": "inference",
                }
            },
            "template": {
                "metadata": {
                    "labels": {
                        "app": "inference",
                    }
                },
                "spec": {
                    "nodeSelector": if nodebind == "yes" then {"d3.nodetype": "dkube"} else {},
                    "containers": [
                        {
                            "image": dkubeInferenceImage,
                            "imagePullPolicy": "IfNotPresent",
                            "name": "inference",
                            "ports": [
                                {
                                    "containerPort": 8000,
                                    "protocol": "TCP"
                                }
                            ],
                            "resources": {}
                        }
                    ],
                    "dnsPolicy": "ClusterFirst",
                    "imagePullSecrets": [
                        {
                            "name": dkubeDockerSecret,
                        }
                    ],
                }
            }
        }
    },
    dkubeDocs(tag, dkubeDocsImage, dkubeDockerSecret):: {
        "apiVersion": "extensions/v1beta1",
        "kind": "Deployment",
        "metadata": {
            "labels": {
                "app": "docs",
            },
            "name": "dkube-docs-" + tag,
            "namespace": namespace
        },
        "spec": {
            "replicas": 1,
            "selector": {
                "matchLabels": {
                    "app": "docs",
                }
            },
            "template": {
                "metadata": {
                    "labels": {
                        "app": "docs",
                    }
                },
                "spec": {
                    "nodeSelector": if nodebind == "yes" then {"d3.nodetype": "dkube"} else {},
                    "containers": [
                        {
                            "image": dkubeDocsImage,
                            "imagePullPolicy": "IfNotPresent",
                            "name": "docs",
                            "resources": {}
                        }
                    ],
                    "dnsPolicy": "ClusterFirst",
                    "imagePullSecrets": [
                        {
                            "name": dkubeDockerSecret,
                        }
                    ],
                }
            }
        }
    },
	logstash(tag, nfsServer, nfsBasePath):: {
	    "apiVersion": "apps/v1", 
	    "kind": "Deployment", 
	    "metadata": {
		"name": "logstash-" + tag, 
		"namespace": "dkube"
	    }, 
	    "spec": {
		"replicas": 1, 
		"selector": {
		    "matchLabels": {
			"app": "logstash"
		    }
		}, 
		"template": {
		    "metadata": {
			"labels": {
			    "app": "logstash"
			}
		    }, 
		    "spec": {
            "nodeSelector": if nodebind == "yes" then {"d3.nodetype": "dkube"} else {},
			"containers": [
			{
			    "command": [
                    "bash",
                    "-c",
                    "\u003e config/logstash.yml;\n\u003e pipeline/logstash.conf;\ncat /tmp/config_data/logstash.conf \u003e\u003e pipeline/logstash.conf;\nlogstash -f pipeline/logstash.conf\n"
                ],
			    "image": "docker.elastic.co/logstash/logstash:7.3.0",  
			    "imagePullPolicy": "IfNotPresent", 
			    "name": "logstash",
			    "resources": {},
			    "securityContext": {
                    "runAsUser": 0
                },
                "volumeMounts": [
                   {
                      "mountPath": "/var/log/dkube",
                      "name": "logs"
                    },
                    {
                        "mountPath": "/tmp/config_data",
                        "name": "logstash-config",
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
            "volumes": [
	              {
	                "nfs": {
	                   "path": nfsBasePath + "/dkube/system/logs",
	                   "server": nfsServer
	                 },
	                  "name": "logs"
	                },
	                {
                    "configMap": {
                        "defaultMode": 384,
                        "name": "logstash-config"
                    },
                    "name": "logstash-config"
                    },
	              ]
		    }
		}
	    }
	},
	dkubeEtcd(tag, etcdPVC):: {
	    "apiVersion": "extensions/v1beta1",
	    "kind": "Deployment",
	    "metadata": {
		"name": "dkube-etcd-server-" + tag ,
		"namespace": "dkube"
	    },
	    "spec": {
		"selector": {
		    "matchLabels": {
			"app": "dkube-etcd-server"
		    }
		},
		"template": {
		    "metadata": {
			"labels": {
			    "app": "dkube-etcd-server"
			}
		    },
		    "spec": {
            "nodeSelector": if nodebind == "yes" then {"d3.nodetype": "dkube"} else {},
			"containers": [
			{
			    "command": [
				"etcd",
			    "--listen-client-urls=http://0.0.0.0:2379",
			    "--advertise-client-urls=http://0.0.0.0:2379",
			    "--data-dir=/var/lib/etcd"
			    ],
			    "image": "k8s.gcr.io/etcd-amd64:3.1.12",
			    "imagePullPolicy": "IfNotPresent",
			    "name": "etcd",
			    "volumeMounts": [
			    {
				"mountPath": "/var/lib/etcd",
				"name": "etcd-data"
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
			"volumes": [
			{
			    "persistentVolumeClaim": {
				"claimName": etcdPVC
			    },
			    "name": "etcd-data"
			}
			]
		    }
		}
	    }
	},
	dfabProxy(tag , dfabProxyImage, dkubeDockerSecret):: {
	    "apiVersion": "extensions/v1beta1",
	    "kind": "Deployment",
	    "metadata": {
		"labels": {
		    "app": "dfabproxy"
		},
		"name": "dfabproxy-" + tag ,
		"namespace": "dkube",
	    },
	    "spec": {
		"progressDeadlineSeconds": 600,
		"replicas": 1,
		"revisionHistoryLimit": 10,
		"selector": {
		    "matchLabels": {
			"app": "dfabproxy"
		    }
		},
		"strategy": {
		    "rollingUpdate": {
			"maxSurge": "25%",
			"maxUnavailable": "25%"
		    },
		    "type": "RollingUpdate"
		},
		"template": {
		    "metadata": {
			"creationTimestamp": null,
			"labels": {
			    "app": "dfabproxy"
			}
		    },
		    "spec": {
            "nodeSelector": if nodebind == "yes" then {"d3.nodetype": "dkube"} else {},
			"containers": [
			{
			    "image": dfabProxyImage,
			    "imagePullPolicy": "IfNotPresent",
			    "name": "dfabproxy",
			    "resources": {},
			    "terminationMessagePath": "/dev/termination-log",
			    "terminationMessagePolicy": "File"
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
			"schedulerName": "default-scheduler",
			"securityContext": {},
			"terminationGracePeriodSeconds": 30
		    }
		}
	    },
	},
    dkubeAuth(tag, dkubeAuthImage, dkubeDockerSecret, nfsServer, nfsBasePath, dkubePubIP):: {
        "apiVersion": "extensions/v1beta1",
        "kind": "Deployment",
        "metadata": {
            "labels": {
                "app": "d3auth"
            },
            "name": "dkube-d3auth-" + tag,
            "namespace": "dkube",
        },
        "spec": {
            "replicas": 1,
            "selector": {
                "matchLabels": {
                    "app": "d3auth"
                }
            },
            "template": {
                "metadata": {
                    "labels": {
                        "app": "d3auth"
                    },
                    "name": "d3auth",
                    "namespace": "dkube"
                },
                "spec": {
                    "containers": [
                    {
                        "image": dkubeAuthImage,
                        "imagePullPolicy": "IfNotPresent",
                        "name": "dex-server",
                        "command": [
                            "/opt/dkube/dex",
                            "serve",
                            "/etc/dex/cfg/config.yaml"
                        ],
                        "ports": [
                        {
                            "containerPort": 5556,
                            "name": "dex-s",
                            "protocol": "TCP"
                        }
                        ],
                        "resources": {},
                        "securityContext": {
                            "procMount": "Default",
                            "runAsUser": 0
                        },
                        "volumeMounts": [
                        {
                            "mountPath": "/etc/dex/cfg",
                            "name": "dex-cm"
                        }
                        ],
                    env: [
                            {
                                "name": "PUBLIC_IP",
                                "value": dkubePubIP,
                            },
                    ]
                    },
                    {
                        "image": dkubeAuthImage,
                        "imagePullPolicy": "IfNotPresent",
                        "name": "authn",
                        "ports": [
                        {
                            "containerPort": 3001,
                            "name": "authn",
                            "protocol": "TCP"
                        }
                        ],
                        "volumeMounts": [
                        {
                            "mountPath": "/var/log/dkube",
                            "name": "dkube-logs"
                        }
                        ],
                    env: [
                            {
                                "name": "PUBLIC_IP",
                                "value": dkubePubIP,
                            },
                    ]
                    }
                    ],
                    "dnsPolicy": "ClusterFirst",
                    "restartPolicy": "Always",
                    "serviceAccount": "dkube",
                    "serviceAccountName": "dkube",
                    "imagePullSecrets": [
                    {
                        "name": dkubeDockerSecret
                    }
                    ],
                    "nodeSelector": if nodebind == "yes" then {"d3.nodetype": "dkube"} else {},
                    "volumes": [
                    {
                        "configMap": {
                            "defaultMode": 420,
                            "name": "dex"
                        },
                        "name": "dex-cm"
                    },
                    {
                        "nfs": {
                            "path": nfsBasePath + "/dkube/system/logs/dkube",
                            "server": nfsServer
                        },
                        "name": "dkube-logs"
                    }
                    ]
                }
            }
        },
    },
	dkubeWatcher(tag , dkubeWatcherImage, dkubeDockerSecret):: {
	        "apiVersion": "extensions/v1beta1",
    "kind": "Deployment",
    "metadata": {
        "labels": {
            "app": "dkube-d3watcher"
        },
        "name": "dkube-d3watcher-" + tag,
        "namespace": "dkube",
    },
    "spec": {
        "replicas": 1,
        "selector": {
            "matchLabels": {
                "app": "dkube-d3watcher"
            }
        },
        "template": {
            "metadata": {
                "labels": {
                    "app": "dkube-d3watcher"
                }
            },
            "spec": {
                "containers": [
                    {
                        "env": [
                            {
                                "name": "DKUBE_SERVICE_ACCOUNT",
                                "value": "dkube"
                            }
                        ],
                        "image": dkubeWatcherImage,
                        "imagePullPolicy": "IfNotPresent",
                        "name": "dkube-d3watcher",
                        "resources": {},
                        "securityContext": {
                            "procMount": "Default",
                            "runAsUser": 0
                        },
                        "terminationMessagePath": "/dev/termination-log",
                        "terminationMessagePolicy": "File",
                        "volumeMounts": [
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
                "nodeSelector": if nodebind == "yes" then {"d3.nodetype": "dkube"} else {},
                "restartPolicy": "Always",
                "schedulerName": "default-scheduler",
                "securityContext": {},
                "serviceAccount": "dkube",
                "serviceAccountName": "dkube",
                "volumes": [
                    {
                        "hostPath": {
                            "path": "/var/log/dkube",
                            "type": "DirectoryOrCreate"
                        },
                        "name": "dkube-logs-host"
                    }
                ]
            }
        }
    },
    },
      ambassdor(tag):: {
        apiVersion: "extensions/v1beta1",
        kind: "Deployment",
        metadata: {
          name: "ambassador-"+ tag ,
          namespace: namespace,
        },
        spec: {
          replicas: 1,
          template: {
            metadata: {
              labels: {
                service: "ambassador",
              },
              namespace: namespace,
            },
            spec: {
              "nodeSelector": if nodebind == "yes" then {"d3.nodetype": "dkube"} else {},
              containers: [
                {
                  env: [
                    {
                      name: "AMBASSADOR_NAMESPACE",
                      valueFrom: {
                        fieldRef: {
                          fieldPath: "metadata.namespace",
                        },
                      },
                    },
                    {
                      name: "AMBASSADOR_SINGLE_NAMESPACE",
                      value: "false",
                    },
                  ],
                  image: ambassadorImage,
                  livenessProbe: {
                    httpGet: {
                      path: "/ambassador/v0/check_alive",
                      port: 8877,
                    },
                    initialDelaySeconds: 30,
                    periodSeconds: 30,
                  },
                  name: "ambassador",
                  readinessProbe: {
                    httpGet: {
                      path: "/ambassador/v0/check_ready",
                      port: 8877,
                    },
                    initialDelaySeconds: 30,
                    periodSeconds: 30,
                  },
                  resources: {
                    limits: {
                      cpu: 1,
                      memory: "400Mi",
                    },
                    requests: {
                      cpu: "200m",
                      memory: "100Mi",
                    },
                  },
                },
                //{
                //  image: "quay.io/datawire/statsd:0.30.1",
                //  name: "statsd",
                //},
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
              restartPolicy: "Always",
              serviceAccountName: "ambassador",
             },
            },
          },
        },
    dkubeDownloader(tag,dkubeDownloaderImage, dkubeDockerSecret, nfsServer, nfsBasePath):: {
	    "apiVersion": "apps/v1",
	    "kind": "Deployment",
	    "metadata": {
		"name": "dkube-d3downloader-" + tag,
		"namespace": "dkube"
	    },
	    "spec": {
		"replicas": 1,
		"selector": {
		    "matchLabels": {
			"app": "dkube-d3downloader"
		    }
		},
		"template": {
		    "metadata": {
			"labels": {
			    "app": "dkube-d3downloader"
			}
		    },
		    "spec": {
			"imagePullSecrets": [
			{
			    "name": dkubeDockerSecret
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
            "nodeSelector": if nodebind == "yes" then {"d3.nodetype": "dkube"} else {},
			"serviceAccount": "dkube",
            "serviceAccountName": "dkube",
			"containers": [
			{
			    "image": dkubeDownloaderImage,
			    "imagePullPolicy": "IfNotPresent",
			    "name": "d3downloader",
			    "resources": {},
			    "securityContext": {
                    "procMount": "Default",
                    "runAsUser": 0
                },
                "volumeMounts": [
                   {
                      "mountPath": "/var/log/containerlogs",
                      "name": "logs"
                    }
                 ]
			}
			],
            "volumes": [
	              {
	                "nfs": {
	                   "path": nfsBasePath + "/dkube/system/logs",
	                   "server": nfsServer
	                 },
	                  "name": "logs"
	                }
	              ]
		    }
		}
	    }
	}
    },
}
