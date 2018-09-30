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
        "namespace": "monitoring"
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
            "monitoring"
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
        "name": "pod-exporter",
        "namespace": "monitoring"
      },
      "spec": {
        "externalTrafficPolicy": "Cluster",
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
        "type": "NodePort"
      }
    },
    {
      "apiVersion": "apps/v1",
      "kind": "Deployment",
      "metadata": {
        "name": "cadvisor",
        "namespace": "monitoring"
      },
      "spec": {
        "replicas": 1,
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
                    "hostPort": 8080,
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
                    "mountPath": "/var/run:ro",
                    "name": "run"
                  },
                  {
                    "mountPath": "/sys:ro",
                    "name": "sys"
                  },
                  {
                    "mountPath": "/var/lib/docker:ro",
                    "name": "docker"
                  }
                ]
              }
            ],
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

