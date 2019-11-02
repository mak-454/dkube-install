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
        "name": "dkube-prometheus-exporter-pod",
        "namespace": "dkube"
      },
      "spec": {
        "endpoints": [
          {
            "interval": "15s",
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
            "app": "dkube-pod-exporter"
          }
        }
      }
    },
    {
      "apiVersion": "v1",
      "kind": "Service",
      "metadata": {
        "annotations": {
          "prometheus.io/port": "8080",
          "prometheus.io/scrape": "true"
        },
        "labels": {
          "app": "dkube-pod-exporter"
        },
        "name": "dkube-cpu-exporter-service",
        "namespace": "dkube"
      },
      "spec": {
        "ports": [
          {
            "name": "http-metrics",
            "port": 8080,
            "protocol": "TCP",
            "targetPort": 8080
          }
        ],
        "selector": {
          "app": "pod-exporter"
        },
        "sessionAffinity": "None",
        "type": "ClusterIP"
      }
    },
    {
      "apiVersion": "extensions/v1beta1",
      "kind": "DaemonSet",
      "metadata": {
        "name": "dkube-cpu-exporter",
        "namespace": "dkube"
      },
      "spec": {
        "selector": {
          "matchLabels": {
            "app": "pod-exporter"
          }
        },
        "template": {
          "metadata": {
            "labels": {
              "app": "pod-exporter"
            }
          },
          "spec": {
            "containers": [
              {
                "image": "google/cadvisor:latest",
                "imagePullPolicy": "IfNotPresent",
                "name": "cadvisor",
                "ports": [
                  {
                    "containerPort": 8080,
                    "name": "http-metrics",
                    "protocol": "TCP"
                  }
                ],
                "volumeMounts": [
                  {
                    "mountPath": "/rootfs:ro",
                    "name": "rootfs"
                  },
                  {
                    "mountPath": "/var/run:rw",
                    "name": "run"
                  },
                  {
                    "mountPath": "/sys:ro",
                    "name": "sys"
                  },
                  {
                    "mountPath": "/var/lib/docker:rw",
                    "name": "docker"
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
                "hostPath": {
                  "path": "/",
                  "type": ""
                },
                "name": "rootfs"
              },
              {
                "hostPath": {
                  "path": "/var/run",
                  "type": ""
                },
                "name": "run"
              },
              {
                "hostPath": {
                  "path": "/sys",
                  "type": ""
                },
                "name": "sys"
              },
              {
                "hostPath": {
                  "path": "/var/lib/docker/",
                  "type": ""
                },
                "name": "docker"
              }
            ]
          }
        }
      }
    }
  ]
}

