{
  all(params):: [

    {
      "apiVersion": "monitoring.coreos.com/v1", 
      "kind": "ServiceMonitor", 
      "metadata": {
        "labels": {
          "app": "prometheus-operator", 
          "prometheus": "prometheus-opr"
        }, 
        "name": "prometheus-operator", 
        "namespace": "monitoring"
      }, 
      "spec": {
        "endpoints": [
          {
            "honorLabels": true, 
            "interval": "30s", 
            "port": "http"
          }
        ], 
        "jobLabel": "prometheus-operator", 
        "namespaceSelector": {
          "matchNames": [
            "monitoring"
          ]
        }, 
        "selector": {
          "matchLabels": {
            "operated-prometheus": "true"
          }
        }
      }
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1beta1", 
      "kind": "ClusterRoleBinding", 
      "metadata": {
        "labels": {
          "app": "prometheus-operator"
        }, 
        "name": "prometheus-opr-prometheus-operator", 
        "namespace": "monitoring"
      }, 
      "roleRef": {
        "apiGroup": "rbac.authorization.k8s.io", 
        "kind": "ClusterRole", 
        "name": "prometheus-opr-prometheus-operator"
      }, 
      "subjects": [
        {
          "kind": "ServiceAccount", 
          "name": "prometheus-opr-prometheus-operator", 
          "namespace": "monitoring"
        }
      ]
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1beta1", 
      "kind": "ClusterRoleBinding", 
      "metadata": {
        "labels": {
          "app": "prometheus-operator"
        }, 
        "name": "psp-prometheus-opr-prometheus-operator", 
        "namespace": "monitoring"
      }, 
      "roleRef": {
        "apiGroup": "rbac.authorization.k8s.io", 
        "kind": "ClusterRole", 
        "name": "psp-prometheus-opr-prometheus-operator"
      }, 
      "subjects": [
        {
          "kind": "ServiceAccount", 
          "name": "prometheus-opr-prometheus-operator", 
          "namespace": "monitoring"
        }
      ]
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1beta1", 
      "kind": "ClusterRole", 
      "metadata": {
        "labels": {
          "app": "prometheus-operator"
        }, 
        "name": "prometheus-opr-prometheus-operator", 
        "namespace": "monitoring"
      }, 
      "rules": [
        {
          "apiGroups": [
            "extensions"
          ], 
          "resources": [
            "thirdpartyresources"
          ], 
          "verbs": [
            "*"
          ]
        }, 
        {
          "apiGroups": [
            "apiextensions.k8s.io"
          ], 
          "resources": [
            "customresourcedefinitions"
          ], 
          "verbs": [
            "*"
          ]
        }, 
        {
          "apiGroups": [
            "monitoring.coreos.com"
          ], 
          "resources": [
            "alertmanager", 
            "alertmanagers", 
            "prometheus", 
            "prometheuses", 
            "service-monitor", 
            "servicemonitors", 
            "prometheusrules"
          ], 
          "verbs": [
            "*"
          ]
        }, 
        {
          "apiGroups": [
            "apps"
          ], 
          "resources": [
            "statefulsets"
          ], 
          "verbs": [
            "*"
          ]
        }, 
        {
          "apiGroups": [
            ""
          ], 
          "resources": [
            "configmaps", 
            "secrets"
          ], 
          "verbs": [
            "*"
          ]
        }, 
        {
          "apiGroups": [
            ""
          ], 
          "resources": [
            "pods"
          ], 
          "verbs": [
            "list", 
            "delete"
          ]
        }, 
        {
          "apiGroups": [
            ""
          ], 
          "resources": [
            "services", 
            "endpoints"
          ], 
          "verbs": [
            "get", 
            "create", 
            "update"
          ]
        }, 
        {
          "apiGroups": [
            ""
          ], 
          "resources": [
            "nodes"
          ], 
          "verbs": [
            "list", 
            "watch"
          ]
        }, 
        {
          "apiGroups": [
            ""
          ], 
          "resources": [
            "namespaces"
          ], 
          "verbs": [
            "list", 
            "watch"
          ]
        }
      ]
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1beta1", 
      "kind": "ClusterRole", 
      "metadata": {
        "labels": {
          "app": "prometheus-operator"
        }, 
        "name": "psp-prometheus-opr-prometheus-operator", 
        "namespace": "monitoring"
      }, 
      "rules": [
        {
          "apiGroups": [
            "extensions"
          ], 
          "resourceNames": [
            "prometheus-opr-prometheus-operator"
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
      "apiVersion": "v1", 
      "imagePullSecrets": [], 
      "kind": "ServiceAccount", 
      "metadata": {
        "labels": {
          "app": "prometheus-operator"
        }, 
        "name": "prometheus-opr-prometheus-operator", 
        "namespace": "monitoring"
      }
    },
    {
      "apiVersion": "apps/v1beta1", 
      "kind": "Deployment", 
      "metadata": {
        "labels": {
          "app": "prometheus-operator", 
          "operator": "prometheus"
        }, 
        "name": "prometheus-opr-prometheus-operator", 
        "namespace": "monitoring"
      }, 
      "spec": {
        "replicas": 1, 
        "template": {
          "metadata": {
            "labels": {
              "app": "prometheus-operator", 
              "operator": "prometheus"
            }
          }, 
          "spec": {
            "containers": [
              {
                "args": [
                  "--kubelet-service=kube-system/kubelet", 
                  "--prometheus-config-reloader=quay.io/coreos/prometheus-config-reloader:v0.20.0", 
                  "--config-reloader-image=quay.io/coreos/configmap-reload:v0.0.1"
                ], 
                "image": "quay.io/coreos/prometheus-operator:v0.20.0", 
                "imagePullPolicy": "IfNotPresent", 
                "name": "prometheus-operator", 
                "ports": [
                  {
                    "containerPort": 8080, 
                    "name": "http"
                  }
                ], 
                "resources": {}
              }
            ], 
            "serviceAccountName": "prometheus-opr-prometheus-operator"
          }
        }
      }
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1beta1", 
      "kind": "ClusterRoleBinding", 
      "metadata": {
        "labels": {
          "app": "prometheus"
        }, 
        "name": "kube-prometheus", 
        "namespace": "monitoring"
      }, 
      "roleRef": {
        "apiGroup": "rbac.authorization.k8s.io", 
        "kind": "ClusterRole", 
        "name": "kube-prometheus"
      }, 
      "subjects": [
        {
          "kind": "ServiceAccount", 
          "name": "kube-prometheus", 
          "namespace": "monitoring"
        }
      ]
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1beta1", 
      "kind": "ClusterRole", 
      "metadata": {
        "labels": {
          "app": "prometheus"
        }, 
        "name": "kube-prometheus", 
        "namespace": "monitoring"
      }, 
      "rules": [
        {
          "apiGroups": [
            ""
          ], 
          "resources": [
            "nodes", 
            "services", 
            "endpoints", 
            "pods"
          ], 
          "verbs": [
            "get", 
            "list", 
            "watch"
          ]
        }, 
        {
          "apiGroups": [
            ""
          ], 
          "resources": [
            "configmaps"
          ], 
          "verbs": [
            "get"
          ]
        }, 
        {
          "apiGroups": [
            ""
          ], 
          "resources": [
            "nodes/metrics"
          ], 
          "verbs": [
            "get"
          ]
        }, 
        {
          "nonResourceURLs": [
            "/metrics"
          ], 
          "verbs": [
            "get"
          ]
        }
      ]
    },
    {
      "apiVersion": "v1", 
      "imagePullSecrets": [], 
      "kind": "ServiceAccount", 
      "metadata": {
        "labels": {
          "app": "prometheus"
        }, 
        "name": "kube-prometheus", 
        "namespace": "monitoring"
      }
    },
    {
      "apiVersion": "monitoring.coreos.com/v1", 
      "kind": "Prometheus", 
      "metadata": {
        "labels": {
          "app": "prometheus", 
          "prometheus": "kube-prometheus"
        }, 
        "name": "kube-prometheus", 
        "namespace": "monitoring"
      }, 
      "spec": {
        "affinity": {
          "podAntiAffinity": {
            "preferredDuringSchedulingIgnoredDuringExecution": [
              {
                "podAffinityTerm": {
                  "labelSelector": {
                    "matchLabels": {
                      "app": "prometheus", 
                      "prometheus": "kube-prometheus"
                    }
                  }, 
                  "topologyKey": "kubernetes.io/hostname"
                }, 
                "weight": 100
              }
            ]
          }
        }, 
        "alerting": {
          "alertmanagers": [
            {
              "name": "kube-prometheus-alertmanager", 
              "namespace": "monitoring", 
              "port": "http"
            }
          ]
        }, 
        "baseImage": "quay.io/prometheus/prometheus", 
        "externalUrl": "http://kube-prometheus.monitoring:9090", 
        "imagePullSecrets": [], 
        "logLevel": "info", 
        "paused": false, 
        "replicas": 1, 
        "resources": {}, 
        "retention": "24h", 
        "routePrefix": "/", 
        "ruleSelector": {
          "matchLabels": {
            "prometheus": "kube-prometheus"
          }
        }, 
        "serviceAccountName": "kube-prometheus", 
        "serviceMonitorSelector": {
          "matchLabels": {
            "prometheus": "kube-prometheus"
          }
        }, 
        "version": "v2.2.1"
      }
    },
    {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "labels": {
          "app": "prometheus", 
          "prometheus": "kube-prometheus"
        }, 
        "name": "kube-prometheus", 
        "namespace": "monitoring"
      }, 
      "spec": {
        "clusterIP": "", 
        "ports": [
          {
            "name": "http", 
            "port": 9090, 
            "protocol": "TCP", 
            "targetPort": 9090
          }
        ], 
        "selector": {
          "app": "prometheus", 
          "prometheus": "kube-prometheus"
        }, 
        "sessionAffinity": "None", 
        "type": "NodePort"
      }
    },
    {
      "apiVersion": "v1", 
      "data": {
        "alertmanager.yaml": "Z2xvYmFsOgogIHJlc29sdmVfdGltZW91dDogNW0KcmVjZWl2ZXJzOgotIG5hbWU6ICJudWxsIgpyb3V0ZToKICBncm91cF9ieToKICAtIGpvYgogIGdyb3VwX2ludGVydmFsOiA1bQogIGdyb3VwX3dhaXQ6IDMwcwogIHJlY2VpdmVyOiAibnVsbCIKICByZXBlYXRfaW50ZXJ2YWw6IDEyaAogIHJvdXRlczoKICAtIG1hdGNoOgogICAgICBhbGVydG5hbWU6IERlYWRNYW5zU3dpdGNoCiAgICByZWNlaXZlcjogIm51bGwiCg=="
      }, 
      "kind": "Secret", 
      "metadata": {
        "labels": {
          "alertmanager": "kube-prometheus", 
          "app": "alertmanager"
        }, 
        "name": "alertmanager-kube-prometheus", 
        "namespace": "monitoring"
      }, 
      "type": "Opaque"
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1beta1", 
      "kind": "ClusterRoleBinding", 
      "metadata": {
        "labels": {
          "app": "alertmanager"
        }, 
        "name": "psp-kube-prometheus-alertmanager", 
        "namespace": "monitoring"
      }, 
      "roleRef": {
        "apiGroup": "rbac.authorization.k8s.io", 
        "kind": "ClusterRole", 
        "name": "psp-kube-prometheus-alertmanager"
      }, 
      "subjects": [
        {
          "kind": "ServiceAccount", 
          "name": "default", 
          "namespace": "monitoring"
        }
      ]
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1beta1", 
      "kind": "ClusterRole", 
      "metadata": {
        "labels": {
          "app": "alertmanager"
        }, 
        "name": "psp-kube-prometheus-alertmanager", 
        "namespace": "monitoring"
      }, 
      "rules": [
        {
          "apiGroups": [
            "extensions"
          ], 
          "resourceNames": [
            "kube-prometheus-alertmanager"
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
      "apiVersion": "monitoring.coreos.com/v1", 
      "kind": "Alertmanager", 
      "metadata": {
        "labels": {
          "alertmanager": "kube-prometheus", 
          "app": "alertmanager"
        }, 
        "name": "kube-prometheus", 
        "namespace": "monitoring"
      }, 
      "spec": {
        "affinity": {
          "podAntiAffinity": {
            "preferredDuringSchedulingIgnoredDuringExecution": [
              {
                "podAffinityTerm": {
                  "labelSelector": {
                    "matchLabels": {
                      "alertmanager": "kube-prometheus", 
                      "app": "alertmanager"
                    }
                  }, 
                  "topologyKey": "kubernetes.io/hostname"
                }, 
                "weight": 100
              }
            ]
          }
        }, 
        "baseImage": "quay.io/prometheus/alertmanager", 
        "externalUrl": "http://kube-prometheus-alertmanager.monitoring:9093", 
        "imagePullSecrets": [], 
        "paused": false, 
        "replicas": 1, 
        "resources": {}, 
        "version": "v0.15.1"
      }
    },
    {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "labels": {
          "alertmanager": "kube-prometheus", 
          "app": "alertmanager"
        }, 
        "name": "kube-prometheus-alertmanager", 
        "namespace": "monitoring"
      }, 
      "spec": {
        "clusterIP": "", 
        "ports": [
          {
            "name": "http", 
            "port": 9093, 
            "protocol": "TCP", 
            "targetPort": 9093
          }
        ], 
        "selector": {
          "alertmanager": "kube-prometheus", 
          "app": "alertmanager"
        }, 
        "type": "ClusterIP"
      }
    }
  ]
}

