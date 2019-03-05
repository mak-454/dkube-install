{
    all(params):: [
	$.parts(params.namespace).dkubeExt(params.tag, params.dkubeExtImage, params.dkubeDockerSecret, params.minioSecretKey),
	$.parts(params.namespace).filebeat(params.tag, params.filebeatImage, params.dkubeDockerSecret),
    ],
    parts(namespace):: {
	dkubeExt(tag, dkubeExtImage,dkubeDockerSecret, minioSecretKey):: {
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
			    "ports": [
			    {
				"containerPort": 9401, 
				"name": "http-metrics", 
				"protocol": "TCP"
			    }
			    ], 
			    "volumeMounts": [
			    {
				"mountPath": "/var/log/containerlogs", 
				"name": "logs"
			    }, 
			    {
				"mountPath": "/tmp/dkube/store", 
				"name": "dkube-data"
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
			    "flexVolume": {
				"driver": "oc/d3", 
				"options": {
				    "accessKey": "dkube", 
				    "bucket": "logs", 
				    "endpoint": "http://127.0.0.1:32223", 
				    "s3provider": "minio", 
				    "secretKey": minioSecretKey
				}
			    }, 
			    "name": "logs"
			}, 
			{
			    "flexVolume": {
				"driver": "oc/d3", 
				"options": {
				    "accessKey": "dkube", 
				    "bucket": "dkube", 
				    "endpoint": "http://127.0.0.1:32223", 
				    "s3provider": "minio", 
				    "secretKey": minioSecretKey
				}
			    }, 
			    "name": "dkube-data"
			}
			]
		    }
		}
	    }
	},
	filebeat(tag, filebeatImage, dkubeDockerSecret):: {
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
			"imagePullSecrets": [
			{
			    "name": dkubeDockerSecret
			}
			],
			"containers": [
			{
			    "command": [
				"bash",
			    "-c",
			    "while IFS='' read -r line || [[ -n \"$line\" ]]; \ndo\n  IFS='//' read -r -a array1 \u003c\u003c\u003c \"$line\";\n  a=\"/mnt/root\";\n  for i in ${!array1[@]};\n  do\n      if [ $i -ne 0 ];\n      then\n          a=\"$a/${array1[$i]}\";\n      fi;\n  done;\n  a=\"$a/containers\";\n  export DOCKERPATH=$a;\n  export NODENAME=${NODENAME}\n  sed -i -e 's@DOCKERPATH@'\"$DOCKERPATH\"'@' filebeat.yml;\n  sed -i -e 's@NODENAME@'\"$NODENAME\"'@' filebeat.yml;\ndone \u003c \"/tmp/dockerstorage/dockerpath.txt\";\nchown root:filebeat /usr/share/filebeat/filebeat.yml\n./filebeat -e;\n"
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
			    "image": filebeatImage,
			    "imagePullPolicy": "IfNotPresent",
			    "name": "filebeat",
			    "resources": {},
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
			}
			]
		    }
		},
		"templateGeneration": 1,
		"updateStrategy": {
		    "type": "OnDelete"
		}
	    },
	}

    },
}
