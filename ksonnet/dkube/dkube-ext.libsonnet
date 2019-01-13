{
    all(params):: [
        $.parts(params.namespace).service(),
        $.parts(params.namespace).deploy(params.dkubeExtImage, params.dkubeDockerSecret, params.minioSecretKey),
    ],
    parts(namespace):: {
        service()::	{
            "apiVersion": "v1",
            "kind": "Service",
            "metadata": {
                "annotations": {
                   "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_ext\nuse_websocket: true\nprefix: /dkube/v2/ext\nrewrite: /dkube/v2\ntimeout_ms: 600000\nservice: dkube-ext:9401", 
                    "prometheus.io/port": "9401",
                    "prometheus.io/scrape": "true"
                },
                "labels": {
                    "app": "dkube-gpu-exporter"
                },
                "name": "dkube-ext",
                "namespace": "dkube"
            },
            "spec": {
                "ports": [
                {
                    "name": "http-metrics",
                    "port": 9401,
                    "protocol": "TCP",
                    "targetPort": 9401
                }
                ],
                "selector": {
                    "app": "dkube-ext"
                },
                "type": "ClusterIP"
            }
        },
        deploy(dkubeExtImage,dkubeDockerSecret, minioSecretKey):: {
            "apiVersion": "extensions/v1beta1", 
            "kind": "DaemonSet", 
            "metadata": {
                "labels": {
                    "app": "dkube-ext"
                }, 
                "name": "dkube-ext", 
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
                                "hostPort": 9401, 
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
        }
    }
}
