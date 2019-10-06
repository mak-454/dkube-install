{
  all(params):: [
    {
        "apiVersion": "monitoring.coreos.com/v1",
        "kind": "ServiceMonitor",
        "metadata": {
            "labels": {
                "app": "prometheus",
                "app.kubernetes.io/deploy-manager": "ksonnet",
                "ksonnet.io/component": "monitoring",
                "prometheus": "kube-prometheus"
            },
            "name": "dkube-log-metric-collector",
            "namespace": "monitoring"
        },
        "spec": {
            "endpoints": [
                {
                    "interval": "15s",
                    "port": "dkube-log-metrics"
                }
            ],
            "jobLabel": "k8s-app",
            "namespaceSelector": {
                "matchNames": [
                    "dkube"
                ]
            },
            "selector": {
                "matchLabels": {
                    "app": "dkube-metric-collector"
                }
            }
        }
    }

  ]
}
