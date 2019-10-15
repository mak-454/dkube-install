{
    all(params):: [
        $.parts(params.namespace, params.nodebind).splunksvc(),
	    $.parts(params.namespace, params.nodebind).splunkDeploy(params.nfsServer),
    ],

    parts(namespace, nodebind):: {
        splunkDeploy(nfsServer):: {
            "apiVersion": "extensions/v1beta1",
            "kind": "Deployment",
            "metadata": {
                "labels": {
                    "app": "splunk",
                    "role": "splunk_cluster_master",
                    "tier": "management"
                },
                "name": "splunk-7.3.2",
                "namespace": namespace,
            },
            "spec": {
                "selector": {
                    "matchLabels": {
                        "app": "splunk",
                        "role": "splunk_cluster_master",
                        "tier": "management"
                    }
                },
                "template": {
                    "metadata": {
                        "labels": {
                            "app": "splunk",
                            "role": "splunk_cluster_master",
                            "tier": "management"
                        }
                    },
                    "spec": {
                        "nodeSelector": if nodebind == "yes" then {"d3.nodetype": "dkube"} else {},
                        "containers": [
                        {
                            "env": [
                            {
                                "name": "SPLUNK_PASSWORD",
                                "value": "thunberg007"
                            },
                            {
                                "name": "SPLUNK_START_ARGS",
                                "value": "--accept-license"
                            },
                            {
                                "name": "DEBUG",
                                "value": "true"
                            }
                            ],
                            "image": "splunk/splunk:7.3.2",
                            "imagePullPolicy": "IfNotPresent",
                            "name": "splunk",
                            "ports": [
                            {
                                "containerPort": 8088,
                                "name": "hec",
                                "protocol": "TCP"
                            },
                            {
                                "containerPort": 8000,
                                "name": "web",
                                "protocol": "TCP"
                            },
                            {
                                "containerPort": 8089,
                                "name": "mgmt",
                                "protocol": "TCP"
                            },
                            {
                                "containerPort": 8191,
                                "name": "kv",
                                "protocol": "TCP"
                            }
                            ],
                            "resources": {},
                            "volumeMounts": [
                            {
                                "mountPath": "/opt/splunk/var",
                                "name": "splunk-data"
                            },
                            {
                                "mountPath": "/opt/splunk/etc",
                                "name": "splunk-config"
                            }
                            ]
                        }
                        ],
                        "dnsPolicy": "ClusterFirst",
                        "restartPolicy": "Always",
                        "schedulerName": "default-scheduler",
                        "securityContext": {},
                        "volumes": [
                        {
                            "name": "splunk-config",
                            "nfs": {
                                "path": "/dkube/system/splunk/splunk-etc",
                                "server": nfsServer
                            }
                        },
                        {
                            "name": "splunk-data",
                            "nfs": {
                                "path": "/dkube/system/splunk/splunk-var",
                                "server": nfsServer
                            }
                        }
                        ]
                    }
                }
            }
        },
        splunksvc():: {
            "apiVersion": "v1",
            "kind": "Service",
            "metadata": {
                "annotations": {
                    "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube-splunk\nprefix: /splunk\nrewrite: /\ntimeout_ms: 600000\nservice: dkube-splunk.dkube:8000"
                },
                "labels": {
                    "app": "splunk",
                    "role": "splunk_cluster_master",
                    "tier": "management"
                },
                "name": "dkube-splunk",
                "namespace": "dkube",
            },
            "spec": {
                "ports": [
                {
                    "name": "hec",
                    "port": 8088,
                    "protocol": "TCP",
                    "targetPort": 8088
                },
                {
                    "name": "splunkweb",
                    "port": 8000,
                    "protocol": "TCP",
                    "targetPort": 8000
                },
                {
                    "name": "splunkd",
                    "port": 8089,
                    "protocol": "TCP",
                    "targetPort": 8089
                }
                ],
                "selector": {
                    "app": "splunk",
                    "role": "splunk_cluster_master",
                    "tier": "management"
                },
                "type": "ClusterIP"
            }
        }
    }
}
