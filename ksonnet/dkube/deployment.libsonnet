{
    all(params):: [
	$.parts(params.namespace).logstash(params.tag, params.logstashImage, params.dkubeDockerSecret),
	$.parts(params.namespace).dkubeEtcd(params.tag, params.dkubePVC),
	$.parts(params.namespace).dfabProxy(params.tag,params.dfabProxyImage, params.dkubeDockerSecret),
	$.parts(params.namespace).dkubeWatcher(params.tag, params.dkubeWatcherImage, params.dkubeDockerSecret),
	$.parts(params.namespace).ambassdor(params.tag, params.ambassadorImage),
    ],

    parts(namespace):: {
	logstash(tag,logstashImage, dkubeDockerSecret):: {
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
			"imagePullSecrets": [
			{
			    "name": dkubeDockerSecret
			}
			],
			"nodeSelector": {
				"d3.nodetype": "dkube"
			},
			"tolerations": [
				{
					"operator": "Exists"
				},
			],
			"containers": [
			{
			    "command": [
				"logstash",
			    "-f",
			    "config/logstash-sample.conf"
			    ], 
			    "image": logstashImage, 
			    "imagePullPolicy": "IfNotPresent", 
			    "name": "logstash"
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
		    }
		}
	    }
	},
	dkubeEtcd(tag, dkubePVC):: {
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
			"nodeSelector": {
				"d3.nodetype": "dkube"
			},
			"tolerations": [
				{
					"operator": "Exists"
				},
			],
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
				"claimName": dkubePVC
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
			"nodeSelector": {
				"d3.nodetype": "dkube"
			},
			"tolerations": [
				{
					"operator": "Exists"
				},
			],
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
                "nodeSelector": {
                    "d3.nodetype": "dkube"
                },
                "restartPolicy": "Always",
                "schedulerName": "default-scheduler",
                "securityContext": {},
                "serviceAccount": "dkube",
                "serviceAccountName": "dkube",
                "tolerations": [
                    {
                        "operator": "Exists"
                    }
                ],
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
      ambassdor(tag, ambassadorImage):: {
   "apiVersion": "extensions/v1beta1",
   "kind": "Deployment",
   "metadata": {
      "name": "ambassador-" + tag,
      "namespace": "dkube"
   },
   "spec": {
      "replicas": 3,
      "template": {
         "metadata": {
            "annotations": {
               "sidecar.istio.io/inject": "false",
               "consul.hashicorp.com/connect-inject": "false"
            },
            "labels": {
               "service": "ambassador"
            }
         },
         "spec": {
            "affinity": {
               "podAntiAffinity": {
                  "preferredDuringSchedulingIgnoredDuringExecution": [
                     {
                        "weight": 100,
                        "podAffinityTerm": {
                           "labelSelector": {
                              "matchLabels": {
                                 "service": "ambassador"
                              }
                           },
                           "topologyKey": "kubernetes.io/hostname"
                        }
                     }
                  ]
               }
            },
            "serviceAccountName": "ambassador",
            "containers": [
               {
                  "name": "ambassador",
                  "image": ambassadorImage,
                  "resources": {
                     "limits": {
                        "cpu": 1,
                        "memory": "400Mi"
                     },
                     "requests": {
                        "cpu": "200m",
                        "memory": "100Mi"
                     }
                  },
                  "env": [
                     {
                        "name": "AMBASSADOR_NAMESPACE",
                        "valueFrom": {
                           "fieldRef": {
                              "fieldPath": "metadata.namespace"
                           }
                        }
                     }
                  ],
                  "ports": [
                     {
                        "name": "http",
                        "containerPort": 8080
                     },
                     {
                        "name": "https",
                        "containerPort": 8443
                     },
                     {
                        "name": "admin",
                        "containerPort": 8877
                     }
                  ],
                  "livenessProbe": {
                     "httpGet": {
                        "path": "/ambassador/v0/check_alive",
                        "port": 8877
                     },
                     "initialDelaySeconds": 30,
                     "periodSeconds": 3
                  },
                  "readinessProbe": {
                     "httpGet": {
                        "path": "/ambassador/v0/check_ready",
                        "port": 8877
                     },
                     "initialDelaySeconds": 30,
                     "periodSeconds": 3
                  }
               }
            ],
            "restartPolicy": "Always",
            "securityContext": {
               "runAsUser": 8888
            }
         }
      }
   }
        }
    },
}
