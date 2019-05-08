{
  all(params):: [
{
    "apiVersion": "v1",
    "kind": "Service",
    "metadata": {
        "labels": {
            "app": "billing-agent"
        },
        "name": "billing-agent-svc",
        "namespace": "dkube",
    },
    "spec": {
        "ports": [
            {
                "name": "metrics",
                "port": 9402,
                "protocol": "TCP",
                "targetPort": 9402
            }
        ],
        "selector": {
            "app": "billing-agent"
        },
        "sessionAffinity": "None",
        "type": "ClusterIP"
    },
},
{
    "apiVersion": "monitoring.coreos.com/v1",
    "kind": "ServiceMonitor",
    "metadata": {
        "labels": {
            "prometheus": "kube-prometheus"
        },
        "name": "billing-agent-sm",
        "namespace": "monitoring",
    },
    "spec": {
        "endpoints": [
            {
                "interval": "30s",
                "port": "metrics"
            }
        ],
        "namespaceSelector": {
            "matchNames": [
                "dkube"
            ]
        },
        "selector": {
            "matchLabels": {
                "app": "billing-agent"
            }
        }
    }
},
{
    "apiVersion": "extensions/v1beta1",
    "kind": "Deployment",
    "metadata": {
        "labels": {
            "app.kubernetes.io/name": "exporter"
        },
        "name": "metering",
        "namespace": "dkube",
    },
    "spec": {
        "selector": {
            "matchLabels": {
                "app": "billing-agent"
            }
        },
        "template": {
            "metadata": {
                "labels": {
                    "app": "billing-agent",
                    "app.kubernetes.io/name": "exporter"
                }
            },
            "spec": {
                "containers": [
                    {
                        "image": params.heartBeatImage,
                        "imagePullPolicy": "IfNotPresent",
                        "name": "exporter",
                    },
                    {
                        "env": [
                            {
                                "name": "AGENT_CONFIG_FILE",
                                "value": "/etc/ubbagent/config.yaml"
                            },
                            {
                                "name": "AGENT_STATE_DIR",
                                "value": "/var/lib/ubbagent"
                            },
                            {
                                "name": "AGENT_LOCAL_PORT",
                                "value": "3456"
                            }
                        ],
                        "image": params.billingAgentImage,
                        "imagePullPolicy": "IfNotPresent",
                        "name": "ubbagent",
                    }
                ],
                "imagePullSecrets": [
                    {
                        "name": params.dkubeDockerSecret
                    }
                ],
                "restartPolicy": "Always",
            }
        }
    },
}
]
}
