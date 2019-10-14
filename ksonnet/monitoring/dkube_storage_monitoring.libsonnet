{
  all(params):: [

    {
      "apiVersion": "monitoring.coreos.com/v1",
      "kind": "ServiceMonitor",
      "metadata": {
        "labels": {
          "app": "prometheus",
          "prometheus": "kube-prometheus"
        },
        "name": "dkube-storage-exporter",
        "namespace": "dkube"
      },
      "spec": {
        "endpoints": [
          {
            "interval": "60s",
            "port": "http-metrics"
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
            "app": "dkube-storage-exporter"
          }
        }
      }
    }
  ]
}

