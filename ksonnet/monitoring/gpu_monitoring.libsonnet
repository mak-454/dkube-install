{
  all(params):: [

    {
      "apiVersion": "extensions/v1beta1", 
      "kind": "Deployment", 
      "metadata": {
        "annotations": null, 
        "labels": {
          "app": "dkube-prometheus-grafana", 
          "chart": "grafana-0.0.37", 
          "heritage": "Tiller", 
          "release": "kube-prometheus"
        }, 
        "name": "dkube-grafana", 
        "namespace": "monitoring"
      }, 
      "spec": {
        "progressDeadlineSeconds": 600, 
        "replicas": 1, 
        "revisionHistoryLimit": 10, 
        "selector": {
          "matchLabels": {
            "app": "dkube-prometheus-grafana"
          }
        }, 
        "strategy": {
          "rollingUpdate": {
            "maxSurge": 1, 
            "maxUnavailable": 1
          }, 
          "type": "RollingUpdate"
        }, 
        "template": {
          "metadata": {
            "creationTimestamp": null, 
            "labels": {
              "app": "dkube-prometheus-grafana", 
              "release": "kube-prometheus"
            }
          }, 
          "spec": {
            "containers": [
              {
                "env": [
                  {
                    "name": "GF_AUTH_BASIC_ENABLED", 
                    "value": "true"
                  }, 
                  {
                    "name": "GF_AUTH_ANONYMOUS_ENABLED", 
                    "value": "true"
                  }, 
                  {
                    "name": "GF_SECURITY_ADMIN_USER", 
                    "valueFrom": {
                      "secretKeyRef": {
                        "key": "user", 
                        "name": "kube-prometheus-grafana"
                      }
                    }
                  }, 
                  {
                    "name": "GF_SECURITY_ADMIN_PASSWORD", 
                    "valueFrom": {
                      "secretKeyRef": {
                        "key": "password", 
                        "name": "kube-prometheus-grafana"
                      }
                    }
                  }
                ], 
                "image": "grafana/grafana:5.0.0", 
                "imagePullPolicy": "IfNotPresent", 
                "name": "grafana", 
                "ports": [
                  {
                    "containerPort": 3000, 
                    "name": "web", 
                    "protocol": "TCP"
                  }
                ], 
                "readinessProbe": {
                  "failureThreshold": 10, 
                  "httpGet": {
                    "path": "/api/health", 
                    "port": 3000, 
                    "scheme": "HTTP"
                  }, 
                  "periodSeconds": 1, 
                  "successThreshold": 1, 
                  "timeoutSeconds": 1
                }, 
                "resources": {}, 
                "terminationMessagePath": "/dev/termination-log", 
                "terminationMessagePolicy": "File", 
                "volumeMounts": [
                  {
                    "mountPath": "/var/lib/grafana", 
                    "name": "grafana-storage"
                  }, 
                  {
                    "mountPath": "/etc/grafana/grafana.ini", 
                    "name": "grafana-config", 
                    "subPath": "grafana.ini"
                  }
                ]
              }, 
              {
                "args": [
                  "--watch-dir=/var/grafana-dashboards", 
                  "--grafana-url=http://127.0.0.1:3000"
                ], 
                "env": [
                  {
                    "name": "GRAFANA_USER", 
                    "valueFrom": {
                      "secretKeyRef": {
                        "key": "user", 
                        "name": "kube-prometheus-grafana"
                      }
                    }
                  }, 
                  {
                    "name": "GRAFANA_PASSWORD", 
                    "valueFrom": {
                      "secretKeyRef": {
                        "key": "password", 
                        "name": "kube-prometheus-grafana"
                      }
                    }
                  }
                ], 
                "image": "quay.io/coreos/grafana-watcher:v0.0.8", 
                "imagePullPolicy": "IfNotPresent", 
                "name": "grafana-watcher", 
                "resources": {}, 
                "terminationMessagePath": "/dev/termination-log", 
                "terminationMessagePolicy": "File", 
                "volumeMounts": [
                  {
                    "mountPath": "/var/grafana-dashboards", 
                    "name": "grafana-dashboards"
                  }
                ]
              }
            ], 
            "dnsPolicy": "ClusterFirst", 
            "restartPolicy": "Always", 
            "schedulerName": "default-scheduler", 
            "securityContext": {}, 
            "serviceAccount": "kube-prometheus-grafana", 
            "serviceAccountName": "kube-prometheus-grafana", 
            "terminationGracePeriodSeconds": 30, 
            "volumes": [
              {
                "emptyDir": {}, 
                "name": "grafana-storage"
              }, 
              {
                "configMap": {
                  "defaultMode": 420, 
                  "name": "dkube-grafana-dashboard"
                }, 
                "name": "grafana-dashboards"
              }, 
              {
                "configMap": {
                  "defaultMode": 420, 
                  "name": "dkube-grafana-init"
                }, 
                "name": "grafana-config"
              }
            ]
          }
        }
      }
    },
    {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "annotations": {
          "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_monitoring\nprefix: /dkube/grafana/\nrewrite: /\nservice: dkube-grafana.monitoring:80\ntimeout_ms: 60000\nuse_websocket: true"
        }, 
        "labels": {
          "app": "dkube-prometheus-grafana"
        }, 
        "name": "dkube-prometheus-grafana-proxy", 
        "namespace": "dkube"
      }, 
      "spec": {
        "externalTrafficPolicy": "Cluster", 
        "ports": [
          {
            "name": "http", 
            "nodePort": 31227, 
            "port": 80, 
            "protocol": "TCP", 
            "targetPort": 3000
          }
        ], 
        "selector": {
          "app": "dkube-prometheus-grafana"
        }, 
        "sessionAffinity": "None", 
        "type": "NodePort"
      }
    },
    {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "annotations": null, 
        "labels": {
          "app": "dkube-prometheus-grafana"
        }, 
        "name": "dkube-grafana", 
        "namespace": "monitoring"
      }, 
      "spec": {
        "externalTrafficPolicy": "Cluster", 
        "ports": [
          {
            "name": "http", 
            "nodePort": 30990, 
            "port": 80, 
            "protocol": "TCP", 
            "targetPort": 3000
          }
        ], 
        "selector": {
          "app": "dkube-prometheus-grafana"
        }, 
        "sessionAffinity": "None", 
        "type": "NodePort"
      }
    },
    {
      "apiVersion": "monitoring.coreos.com/v1", 
      "kind": "ServiceMonitor", 
      "metadata": {
        "labels": {
          "app": "prometheus", 
          "prometheus": "kube-prometheus"
        }, 
        "name": "dkube-prometheus-exporter-gpu", 
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
            "app": "dkube-gpu-exporter"
          }
        }
      }
    },
    {
      "apiVersion": "extensions/v1beta1", 
      "kind": "DaemonSet", 
      "metadata": {
        "name": "nvidia-exporter", 
        "namespace": "monitoring"
      }, 
      "spec": {
        "template": {
          "metadata": {
            "labels": {
              "app": "nvidia-exporter"
            }
          }, 
          "spec": {
            "containers": [
              {
                "image": "ocdr/dkube-gpu-exporter:v3", 
                "name": "nvidia-exporter", 
                "ports": [
                  {
                    "containerPort": 9401, 
                    "name": "http-metrics"
                  }
                ], 
                "securityContext": {
                  "privileged": true
                }, 
                "volumeMounts": [
                  {
                    "mountPath": "/usr/local/nvidia", 
                    "name": "nvidia"
                  }, 
                  {
                    "mountPath": "/usr/lib", 
                    "name": "nvml"
                  }, 
                  {
                    "mountPath": "/usr/lib64", 
                    "name": "lib64"
                  }
                ]
              }
            ], 
            "hostNetwork": true, 
            "imagePullSecrets": [
              {
                "name": "dkube-dockerhub-secret"
              }
            ], 
            "volumes": [
              {
                "hostPath": {
                  "path": "/opt/nvidia/current"
                }, 
                "name": "nvidia"
              }, 
              {
                "hostPath": {
                  "path": "/usr/lib"
                }, 
                "name": "nvml"
              }, 
              {
                "hostPath": {
                  "path": "/usr/lib64"
                }, 
                "name": "lib64"
              }
            ]
          }
        }
      }
    },
    {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "annotations": {
          "prometheus.io/port": "9401", 
          "prometheus.io/scrape": "true"
        }, 
        "labels": {
          "app": "dkube-gpu-exporter"
        }, 
        "name": "nvidia-exporter", 
        "namespace": "monitoring"
      }, 
      "spec": {
        "ports": [
          {
            "name": "http-metrics", 
            "nodePort": 30001, 
            "port": 9401, 
            "protocol": "TCP", 
            "targetPort": 9401
          }
        ], 
        "selector": {
          "app": "nvidia-exporter"
        }, 
        "type": "NodePort"
      }
    }
  ]
}

