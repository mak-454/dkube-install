{
  all(params):: [
    {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "Role", 
      "metadata": {
        "labels": {
          "app": "dkube-prometheus-grafana"
        }, 
        "name": "dkube-prometheus-grafana", 
        "namespace": "dkube"
      }, 
      "rules": [
        {
          "apiGroups": [
            "extensions"
          ], 
          "resourceNames": [
            "dkube-prometheus-grafana"
          ], 
          "resources": [
            "podsecuritypolicies"
          ], 
          "verbs": [
            "use"
          ]
        }
      ]
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "RoleBinding", 
      "metadata": {
        "labels": {
          "app": "dkube-prometheus-grafana"
        }, 
        "name": "dkube-prometheus-grafana", 
        "namespace": "dkube"
      }, 
      "roleRef": {
        "apiGroup": "rbac.authorization.k8s.io", 
        "kind": "Role", 
        "name": "dkube-prometheus-grafana"
      }, 
      "subjects": [
        {
          "kind": "ServiceAccount", 
          "name": "dkube-prometheus-grafana", 
          "namespace": "dkube"
        }
      ]
    },
    {
      "apiVersion": "v1", 
      "kind": "ServiceAccount", 
      "metadata": {
        "labels": {
          "app": "dkube-prometheus-grafana"
        }, 
        "name": "dkube-prometheus-grafana", 
        "namespace": "dkube"
      }
    },
    {
      "apiVersion": "v1", 
      "data": {
        "password": "YWRtaW4=", 
        "user": "YWRtaW4="
      }, 
      "kind": "Secret", 
      "metadata": {
        "labels": {
          "app": "dkube-prometheus-grafana"
        }, 
        "name": "dkube-prometheus-grafana", 
        "namespace": "dkube"
      }, 
      "type": "Opaque"
    },
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
        "namespace": "dkube"
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
            "nodeSelector": {
              "d3.nodetype": "dkube"
            },
            "tolerations": [
              {
                "operator": "Exists"
              },
            ],
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
                        "name": "dkube-prometheus-grafana"
                      }
                    }
                  }, 
                  {
                    "name": "GF_SECURITY_ADMIN_PASSWORD", 
                    "valueFrom": {
                      "secretKeyRef": {
                        "key": "password", 
                        "name": "dkube-prometheus-grafana"
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
                        "name": "dkube-prometheus-grafana"
                      }
                    }
                  }, 
                  {
                    "name": "GRAFANA_PASSWORD", 
                    "valueFrom": {
                      "secretKeyRef": {
                        "key": "password", 
                        "name": "dkube-prometheus-grafana"
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
            "restartPolicy": "Always", 
            "schedulerName": "default-scheduler", 
            "securityContext": {}, 
            "serviceAccount": "dkube-prometheus-grafana", 
            "serviceAccountName": "dkube-prometheus-grafana", 
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
        "annotations": null, 
        "labels": {
          "app": "dkube-prometheus-grafana"
        }, 
        "name": "dkube-grafana", 
        "namespace": "dkube"
      }, 
      "spec": {
        "ports": [
          {
            "name": "http", 
            "port": 80, 
            "protocol": "TCP", 
            "targetPort": 3000
          }
        ], 
        "selector": {
          "app": "dkube-prometheus-grafana"
        }, 
        "sessionAffinity": "None", 
        "type": "ClusterIP"
      }
    },
    {
      "apiVersion": "monitoring.coreos.com/v1", 
      "kind": "ServiceMonitor", 
      "metadata": {
        "labels": {
          "app": "prometheus", 
          "k8s-app": "prometheus", 
          "prometheus": "kube-prometheus"
        }, 
        "name": "dkube-prometheus-exporter-gpu", 
        "namespace": "openshift-monitoring"
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
            "app": "dkube-gpu-exporter"
          }
        }
      }
    }
  ]
}

