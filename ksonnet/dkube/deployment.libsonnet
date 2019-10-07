{
    all(params):: [
	$.parts(params.namespace, params.nodebind).logstash(params.tag, params.nfsServer, params.nfsBasePath),
	$.parts(params.namespace, params.nodebind).dkubeEtcd(params.tag, params.etcdPVC),
	$.parts(params.namespace, params.nodebind).dfabProxy(params.tag,params.dfabProxyImage, params.dkubeDockerSecret),
	$.parts(params.namespace, params.nodebind).dkubeWatcher(params.tag, params.dkubeWatcherImage, params.dkubeDockerSecret),
	$.parts(params.namespace, params.nodebind).dkubeAuth(params.tag, params.dkubeAuthImage, params.dkubeDockerSecret, params.nfsServer, params.nfsBasePath),
	$.parts(params.namespace, params.nodebind).ambassdor(params.tag),
	$.parts(params.namespace, params.nodebind).dkubeServingDocs(params.tag, params.dkubeInferenceImage, params.dkubeDockerSecret, params.dkubeDocsImage),
    ],

    parts(namespace, nodebind):: {
        local ambassadorImage = "quay.io/datawire/ambassador:0.53.1",
    dkubeServingDocs(tag, dkubeInferenceImage, dkubeDockerSecret, dkubeDocsImage):: {
        "apiVersion": "extensions/v1beta1",
        "kind": "Deployment",
        "metadata": {
            "labels": {
                "app": "dkube-tools",
            },
            "name": "dkube-inf-doc-server-" + tag,
            "namespace": namespace
        },
        "spec": {
            "replicas": 1,
            "selector": {
                "matchLabels": {
                    "app": "dkube-tools",
                }
            },
            "template": {
                "metadata": {
                    "labels": {
                        "app": "dkube-tools",
                    }
                },
                "spec": {
                    "nodeSelector": if nodebind == "yes" then {"d3.nodetype": "dkube"} else {},
                    "containers": [
                        {
                            "image": dkubeInferenceImage,
                            "imagePullPolicy": "IfNotPresent",
                            "name": "inference",
                            "resources": {}
                        },
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
		    "name": "dkube-log-mixer-" + tag, 
		    "namespace": "dkube"
	    }, 
	    "spec": {
		"replicas": 1, 
		"selector": {
		    "matchLabels": {
			"app": "dkube-log-mixer"
		    }
		}, 
		"template": {
		    "metadata": {
			"labels": {
			    "app": "dkube-log-mixer"
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
                        "name": "dkube-log-mixer-config",
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
                        "name": "dkube-log-mixer-config"
                    },
                    "name": "dkube-log-mixer-config"
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
		"name": "dkube-db-server-" + tag ,
		"namespace": "dkube"
	    },
	    "spec": {
		"selector": {
		    "matchLabels": {
			"app": "dkube-db-server"
		    }
		},
		"template": {
		    "metadata": {
			"labels": {
			    "app": "dkube-db-server"
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
		    "app": "dkube-operator-proxy"
		},
		"name": "dkube-operator-api-proxy-" + tag ,
		"namespace": "dkube",
	    },
	    "spec": {
		"progressDeadlineSeconds": 600,
		"replicas": 1,
		"revisionHistoryLimit": 10,
		"selector": {
		    "matchLabels": {
			"app": "dkube-operator-proxy"
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
			"labels": {
			    "app": "dkube-operator-proxy"
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
    dkubeAuth(tag, dkubeAuthImage, dkubeDockerSecret, nfsServer, nfsBasePath):: {
        "apiVersion": "extensions/v1beta1",
        "kind": "Deployment",
        "metadata": {
            "labels": {
                "app": "dkube-auth"
            },
            "name": "dkube-auth-server-" + tag,
            "namespace": "dkube",
        },
        "spec": {
            "replicas": 1,
            "selector": {
                "matchLabels": {
                    "app": "dkube-auth"
                }
            },
            "template": {
                "metadata": {
                    "labels": {
                        "app": "dkube-auth"
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
                            "name": "dkube-auth-config"
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
        "name": "dkube-watcher-" + tag,
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
          name: "dkube-proxy-"+ tag ,
          namespace: namespace,
        },
        spec: {
          replicas: 1,
          template: {
            metadata: {
              labels: {
                service: "dkube-proxy",
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
              serviceAccountName: "dkube-proxy",
             },
            },
          },
        },
    },
}
