{
    all(params):: [
	$.parts(params.namespace).dkubeExt(params.tag, params.dkubeExtImage, params.dkubeDockerSecret, params.minioSecretKey, params.nfsServer),
	$.parts(params.namespace).filebeat(params.tag),
    ],
    parts(namespace):: {
	dkubeExt(tag, dkubeExtImage,dkubeDockerSecret, minioSecretKey, nfsServer):: {
	    "apiVersion": "extensions/v1beta1", 
	    "kind": "DaemonSet", 
	    "metadata": {
		"labels": {
		    "app": "dkube-ext"
		}, 
		"name": "dkube-ext-" + tag, 
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
	filebeat(tag):: {
	    "apiVersion": "extensions/v1beta1",
	    "kind": "DaemonSet",
	    "metadata": {
		"labels": {
		    "k8s-app": "filebeat-logging",
		    "kubernetes.io/cluster-service": "true",
		    "version": "v1"
		},
		"name": "filebeat-" + tag,
		"namespace": "dkube",
	    },
	    "spec": {
		"revisionHistoryLimit": 10,
		"selector": {
		    "matchLabels": {
			"k8s-app": "filebeat-logging",
			"kubernetes.io/cluster-service": "true",
			"version": "v1"
		    }
		},
		"template": {
		    "metadata": {
			"creationTimestamp": null,
			"labels": {
			    "k8s-app": "filebeat-logging",
			    "kubernetes.io/cluster-service": "true",
			    "version": "v1"
			}
		    },
		    "spec": {
			"containers": [
			{
			    "command": [
				"bash",
			    "-c",
			    " \u003e filebeat.yml;\n  cat /etc/config_data/filebeat.yml \u003e\u003e /usr/share/filebeat/filebeat.yml;\n  while IFS='' read -r line || [[ -n \"$line\" ]]; \ndo\n  IFS='//' read -r -a array1 \u003c\u003c\u003c \"$line\";\n  a=\"/mnt/root\";\n  for i in ${!array1[@]};\n  do\n      if [ $i -ne 0 ];\n      then\n          a=\"$a/${array1[$i]}\";\n      fi;\n  done;\n  a=\"$a/containers\";\n  export DOCKERPATH=$a;\n  sed -i -e 's@DOCKERPATH@'\"$DOCKERPATH\"'@' filebeat.yml;\n  done \u003c \"/tmp/dockerstorage/dockerpath.txt\";\nchown root:filebeat /usr/share/filebeat/filebeat.yml\n./filebeat -e;\n"
			    ],
			    "env": [
			    {
				"name": "NODENAME",
				"valueFrom": {
				    "fieldRef": {
					"fieldPath": "spec.nodeName"
				    }
				}
			    }
			    ],
			    "image": "docker.elastic.co/beats/filebeat:7.3.0",
			    "imagePullPolicy": "IfNotPresent",
			    "name": "filebeat",
			    "resources": {},
			    "securityContext": {
                    "runAsUser": 0
                },
			    "terminationMessagePath": "/dev/termination-log",
			    "terminationMessagePolicy": "File",
			    "volumeMounts": [
			    {
				"mountPath": "/mnt/root",
				"name": "varlibdockercontainers",
				"readOnly": true
			    },
			    {
				"mountPath": "/tmp/dockerstorage",
				"name": "tmp"
			    },
			    {
                    "mountPath": "/etc/config_data",
                    "name": "filebeat-config",
                    "readOnly": true
                },
                {
                    "mountPath": "/usr/share/filebeat/data",
                    "name": "data"
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
			"initContainers": [
			{
			    "command": [
				"sh",
			    "-c",
			    "dockvol=$(docker info | grep Docker);\necho $dockvol \u003e /tmp/dockerstorage/dockerpath.txt;\n"
			    ],
			    "image": "docker:18.09",
			    "imagePullPolicy": "IfNotPresent",
			    "name": "logpath",
			    "resources": {},
			    "terminationMessagePath": "/dev/termination-log",
			    "terminationMessagePolicy": "File",
			    "volumeMounts": [
			    {
				"mountPath": "/tmp/dockerstorage",
				"name": "tmp"
			    },
			    {
				"mountPath": "/var/run/docker.sock",
				"name": "dockersock"
			    }
			    ]
			}
			],
			"restartPolicy": "Always",
			"schedulerName": "default-scheduler",
			"serviceAccount": "dkube",
			"volumes": [
			{
			    "hostPath": {
				"path": "/",
				"type": ""
			    },
			    "name": "varlibdockercontainers"
			},
			{
			    "emptyDir": {},
			    "name": "tmp"
			},
			{
			    "hostPath": {
				"path": "/var/run/docker.sock",
				"type": ""
			    },
			    "name": "dockersock"
			},
			{
                "configMap": {
                    "defaultMode": 384,
                    "name": "filebeat-config"
                },
                "name": "filebeat-config"
            },
            {
                "hostPath": {
                    "path": "/var/lib/filebeat-data",
                    "type": "DirectoryOrCreate"
                },
                "name": "data"
            },
			]
		    }
		},
	    },
	}

    },
}
