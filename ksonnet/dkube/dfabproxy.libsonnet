{
    all(params):: [
        $.parts(params.namespace).service(),
        $.parts(params.namespace).deploy(params.dfabProxyImage, params.dkubeDockerSecret),
    ],

    parts(namespace):: {
        service():: {
            "apiVersion": "v1",
            "kind": "Service",
            "metadata": {
                "annotations": {
                    "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dfabproxy\nuse_websocket: true\ntimeout_ms: 600000\nprefix: /dkube/v2/operator\nrewrite: /dkube/v2/operator\nservice: dfabproxy:8000"
                },
                "name": "dfabproxy",
                "namespace": "dkube",
            },
            "spec": {
                "clusterIP": "10.108.1.159",
                "ports": [
                {
                    "name": "dfabproxy",
                    "port": 8000,
                    "protocol": "TCP",
                    "targetPort": 8000
                }
                ],
                "selector": {
                    "app": "dfabproxy"
                },
                "sessionAffinity": "None",
                "type": "ClusterIP"
            },
        },
        deploy(dfabProxyImage, dkubeDockerSecret):: {
            "apiVersion": "extensions/v1beta1",
            "kind": "Deployment",
            "metadata": {
                "labels": {
                    "app": "dfabproxy"
                },
                "name": "dfabproxy",
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
        }
    }
}
