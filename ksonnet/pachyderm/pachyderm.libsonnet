{
  all(params):: [
   
    {
      "apiVersion": "v1", 
      "kind": "ServiceAccount", 
      "metadata": {
        "creationTimestamp": null, 
        "labels": {
          "app": "", 
          "suite": "pachyderm"
        }, 
        "name": "pachyderm", 
        "namespace": "dkube"
      }
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "ClusterRole", 
      "metadata": {
        "creationTimestamp": null, 
        "labels": {
          "app": "", 
          "suite": "pachyderm"
        }, 
        "name": "pachyderm", 
        "namespace": "dkube"
      }, 
      "rules": [
        {
          "apiGroups": [
            ""
          ], 
          "resources": [
            "nodes", 
            "pods", 
            "pods/log", 
            "endpoints"
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
            "replicationcontrollers", 
            "services"
          ], 
          "verbs": [
            "get", 
            "list", 
            "watch", 
            "create", 
            "update", 
            "delete"
          ]
        }, 
        {
          "apiGroups": [
            ""
          ], 
          "resourceNames": [
            "pachyderm-storage-secret"
          ], 
          "resources": [
            "secrets"
          ], 
          "verbs": [
            "get", 
            "list", 
            "watch", 
            "create", 
            "update", 
            "delete"
          ]
        }
      ]
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "ClusterRoleBinding", 
      "metadata": {
        "creationTimestamp": null, 
        "labels": {
          "app": "", 
          "suite": "pachyderm"
        }, 
        "name": "pachyderm", 
        "namespace": "dkube"
      }, 
      "roleRef": {
        "apiGroup": "", 
        "kind": "ClusterRole", 
        "name": "pachyderm"
      }, 
      "subjects": [
        {
          "kind": "ServiceAccount", 
          "name": "pachyderm", 
          "namespace": "dkube"
        }
      ]
    },
    {
      "apiVersion": "apps/v1beta1", 
      "kind": "Deployment", 
      "metadata": {
        "creationTimestamp": null, 
        "labels": {
          "app": "etcd", 
          "suite": "pachyderm"
        }, 
        "name": "etcd", 
        "namespace": "dkube"
      }, 
      "spec": {
        "replicas": 1, 
        "selector": {
          "matchLabels": {
            "app": "etcd", 
            "suite": "pachyderm"
          }
        }, 
        "strategy": {}, 
        "template": {
          "metadata": {
            "creationTimestamp": null, 
            "labels": {
              "app": "etcd", 
              "suite": "pachyderm"
            }, 
            "name": "etcd", 
            "namespace": "dkube"
          }, 
          "spec": {
            "containers": [
              {
                "command": [
                  "/usr/local/bin/etcd", 
                  "--listen-client-urls=http://0.0.0.0:2379", 
                  "--advertise-client-urls=http://0.0.0.0:2379", 
                  "--data-dir=/var/data/etcd", 
                  "--auto-compaction-retention=1"
                ], 
                "image": "pachyderm/etcd:v3.2.7", 
                "imagePullPolicy": "IfNotPresent", 
                "name": "etcd", 
                "ports": [
                  {
                    "containerPort": 2379, 
                    "name": "client-port"
                  }, 
                  {
                    "containerPort": 2380, 
                    "name": "peer-port"
                  }
                ], 
                "resources": {
                  "limits": {
                    "cpu": "250m", 
                    "memory": "256M"
                  }, 
                  "requests": {
                    "cpu": "250m", 
                    "memory": "256M"
                  }
                }, 
                "volumeMounts": [
                  {
                    "mountPath": "/var/data/etcd", 
                    "name": "etcd-storage"
                  }
                ]
              }
            ], 
            "nodeSelector": {
              "node-role.kubernetes.io/master": ""
            }, 
            "tolerations": [
              {
                "effect": "NoSchedule", 
                "key": "node-role.kubernetes.io/master", 
                "operator": "Equal"
              }
            ], 
            "volumes": [
              {
                "hostPath": {
                  "path": "/var/dkube/pachyderm/etcd"
                }, 
                "name": "etcd-storage"
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
        "creationTimestamp": null, 
        "labels": {
          "app": "etcd", 
          "suite": "pachyderm"
        }, 
        "name": "etcd", 
        "namespace": "dkube"
      }, 
      "spec": {
        "ports": [
          {
            "name": "client-port", 
            "nodePort": 32379, 
            "port": 2379, 
            "targetPort": 0
          }
        ], 
        "selector": {
          "app": "etcd"
        }, 
        "type": "NodePort"
      }
    },
    {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "creationTimestamp": null, 
        "labels": {
          "app": "pachd", 
          "suite": "pachyderm"
        }, 
        "name": "pachd", 
        "namespace": "dkube"
      }, 
      "spec": {
        "ports": [
          {
            "name": "api-grpc-port", 
            "nodePort": 30650, 
            "port": 650, 
            "targetPort": 0
          }, 
          {
            "name": "trace-port", 
            "nodePort": 30651, 
            "port": 651, 
            "targetPort": 0
          }, 
          {
            "name": "api-http-port", 
            "nodePort": 30652, 
            "port": 652, 
            "targetPort": 0
          }, 
          {
            "name": "api-git-port", 
            "nodePort": 30999, 
            "port": 999, 
            "targetPort": 0
          }
        ], 
        "selector": {
          "app": "pachd"
        }, 
        "type": "NodePort"
      }
    },
    {
      "apiVersion": "apps/v1beta1", 
      "kind": "Deployment", 
      "metadata": {
        "creationTimestamp": null, 
        "labels": {
          "app": "pachd", 
          "suite": "pachyderm"
        }, 
        "name": "pachd", 
        "namespace": "dkube"
      }, 
      "spec": {
        "replicas": 1, 
        "selector": {
          "matchLabels": {
            "app": "pachd", 
            "suite": "pachyderm"
          }
        }, 
        "strategy": {}, 
        "template": {
          "metadata": {
            "annotations": {
              "iam.amazonaws.com/role": ""
            }, 
            "creationTimestamp": null, 
            "labels": {
              "app": "pachd", 
              "suite": "pachyderm"
            }, 
            "name": "pachd", 
            "namespace": "dkube"
          }, 
          "spec": {
            "containers": [
              {
                "env": [
                  {
                    "name": "PACH_ROOT", 
                    "value": "/pach"
                  }, 
                  {
                    "name": "ETCD_PREFIX"
                  }, 
                  {
                    "name": "NUM_SHARDS", 
                    "value": "16"
                  }, 
                  {
                    "name": "STORAGE_BACKEND", 
                    "value": "LOCAL"
                  }, 
                  {
                    "name": "STORAGE_HOST_PATH", 
                    "value": "/var/pachyderm/pachd"
                  }, 
                  {
                    "name": "WORKER_IMAGE", 
                    "value": "pachyderm/worker:1.7.1"
                  }, 
                  {
                    "name": "IMAGE_PULL_SECRET"
                  }, 
                  {
                    "name": "WORKER_SIDECAR_IMAGE", 
                    "value": "pachyderm/pachd:1.7.1"
                  }, 
                  {
                    "name": "WORKER_IMAGE_PULL_POLICY", 
                    "value": "IfNotPresent"
                  }, 
                  {
                    "name": "PACHD_VERSION", 
                    "value": "1.7.1"
                  }, 
                  {
                    "name": "METRICS", 
                    "value": "true"
                  }, 
                  {
                    "name": "LOG_LEVEL", 
                    "value": "info"
                  }, 
                  {
                    "name": "BLOCK_CACHE_BYTES", 
                    "value": "256M"
                  }, 
                  {
                    "name": "IAM_ROLE"
                  }, 
                  {
                    "name": "NO_EXPOSE_DOCKER_SOCKET", 
                    "value": "false"
                  }, 
                  {
                    "name": "PACHYDERM_AUTHENTICATION_DISABLED_FOR_TESTING", 
                    "value": "false"
                  }, 
                  {
                    "name": "PACHD_POD_NAMESPACE", 
                    "valueFrom": {
                      "fieldRef": {
                        "apiVersion": "v1", 
                        "fieldPath": "metadata.namespace"
                      }
                    }
                  }
                ], 
                "image": "pachyderm/pachd:1.7.1", 
                "imagePullPolicy": "IfNotPresent", 
                "name": "pachd", 
                "ports": [
                  {
                    "containerPort": 650, 
                    "name": "api-grpc-port", 
                    "protocol": "TCP"
                  }, 
                  {
                    "containerPort": 651, 
                    "name": "trace-port"
                  }, 
                  {
                    "containerPort": 652, 
                    "name": "api-http-port", 
                    "protocol": "TCP"
                  }, 
                  {
                    "containerPort": 999, 
                    "name": "api-git-port", 
                    "protocol": "TCP"
                  }
                ], 
                "readinessProbe": {
                  "exec": {
                    "command": [
                      "/pachd", 
                      "--readiness"
                    ]
                  }
                }, 
                "resources": {
                  "limits": {
                    "cpu": "250m", 
                    "memory": "512M"
                  }, 
                  "requests": {
                    "cpu": "250m", 
                    "memory": "512M"
                  }
                }, 
                "securityContext": {
                  "privileged": true
                }, 
                "volumeMounts": [
                  {
                    "mountPath": "/pach", 
                    "name": "pach-disk"
                  }, 
                  {
                    "mountPath": "/pachyderm-storage-secret", 
                    "name": "pachyderm-storage-secret"
                  }
                ]
              }
            ], 
            "nodeSelector": {
              "node-role.kubernetes.io/master": ""
            }, 
            "serviceAccountName": "pachyderm", 
            "tolerations": [
              {
                "effect": "NoSchedule", 
                "key": "node-role.kubernetes.io/master", 
                "operator": "Equal"
              }
            ], 
            "volumes": [
              {
                "hostPath": {
                  "path": "/var/dkube/pachyderm/pachd"
                }, 
                "name": "pach-disk"
              }, 
              {
                "name": "pachyderm-storage-secret", 
                "secret": {
                  "secretName": "pachyderm-storage-secret"
                }
              }
            ]
          }
        }
      }
    },
    {
      "apiVersion": "v1", 
      "kind": "Secret", 
      "metadata": {
        "creationTimestamp": null, 
        "labels": {
          "app": "pachyderm-storage-secret", 
          "suite": "pachyderm"
        }, 
        "name": "pachyderm-storage-secret", 
        "namespace": "dkube"
      }
    }
  ]
}

