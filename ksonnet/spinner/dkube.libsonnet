{
  all(params):: [
    $.parts(params.namespace).dkubeServiceAccount(),
    $.parts(params.namespace).dkubeClusterRole(),
    $.parts(params.namespace).dkubeClusterRoleBinding(),
    $.parts(params.namespace).dkubePersistentVolume(params.nfsServerAddr, params.nfsBasePath),
    $.parts(params.namespace).dkubePersistentVolumeClaim(),
    $.parts(params.namespace).dkubeService(params.dkubeApiServerAddr),
    $.parts(params.namespace).dkube(params.dkubeApiServerImage, params.dkubeApiServerAddr, params.dkubeMountPath, params.dkubeTFControllerImage, params.dkubePachydermClientImage, params.dkubeLogCollectorImage, params.pachydermAddr),
    $.parts(params.namespace).dkubeUserClusterRole(),
    $.parts(params.namespace).dkubeUserRole(),
  ],

  parts(namespace):: {
    dkubeServiceAccount():: {
      "apiVersion": "v1", 
      "kind": "ServiceAccount",
      "imagePullSecrets": [
        {
          "name": "dkube-dockerhub-secret"
        }
      ],
      "metadata": {
        "name": "dkube-spinner", 
        "namespace": namespace
      }
    }, // service account
    dkubeClusterRole():: {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "ClusterRole", 
      "metadata": {
        "name": "dkube-spinner"
      }, 
      "rules": [
        {
          "apiGroups": [
            ""
          ], 
          "resources": [
            "pods", 
            "pods/exec"
          ], 
          "verbs": [
            "create", 
            "get", 
            "list", 
            "watch", 
            "update", 
            "patch",
            "delete"
          ]
        }, 
        {
          "apiGroups": [
            ""
          ], 
          "resources": [
            "persistentvolumeclaims", 
            "persistentvolumes"
          ], 
          "verbs": [
            "*" 
          ]
        }, 
        {
          "apiGroups": [
            "argoproj.io"
          ], 
          "resources": [
            "workflows"
          ], 
          "verbs": [
            "get", 
            "list", 
            "watch", 
            "update", 
            "patch", 
            "create",
            "delete"
          ]
        }, 
        {
          "apiGroups": [
            "kubeflow.org"
          ], 
          "resources": [
            "tfjobs"
          ], 
          "verbs": [
            "*"
          ]
        }, 
        {
          "apiGroups": [
            "*"
          ], 
          "resources": [
            "replicasets"
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
            "services", 
            "endpoints",
            "configmaps"
          ], 
          "verbs": [
            "*"
          ]
        }, 
        {
          "apiGroups": [
            "apps", 
            "extensions"
          ], 
          "resources": [
            "deployments"
          ], 
          "verbs": [
            "*"
          ]
        }
      ]
    },  // cluster role
    dkubeClusterRoleBinding():: {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "ClusterRoleBinding", 
      "metadata": {
        "name": "dkube-spinner"
      }, 
      "roleRef": {
        "apiGroup": "rbac.authorization.k8s.io", 
        "kind": "ClusterRole", 
        "name": "dkube-spinner"
      }, 
      "subjects": [
        {
          "kind": "ServiceAccount", 
          "name": "dkube-spinner", 
          "namespace": namespace
        }
      ]
    },  // cluster role binding
    dkubePersistentVolume(nfsServerAddr, nfsBasePath):: {
      "apiVersion": "v1", 
      "kind": "PersistentVolume", 
      "metadata": {
        "labels": {
          "app": "dkube-spinner"
        }, 
        "name": "dkube-spinner",
        "namespace": namespace
      }, 
      "spec": {
        "accessModes": [
          "ReadWriteMany"
        ], 
        "capacity": {
          "storage": "10Gi"
        }, 
        "nfs": {
          "path": nfsBasePath, 
          "server": nfsServerAddr
        }, 
        "persistentVolumeReclaimPolicy": "Delete"
      },
    }, //pv
    dkubePersistentVolumeClaim():: {
      "apiVersion": "v1", 
      "kind": "PersistentVolumeClaim", 
      "metadata": {
        "name": "dkube-spinner", 
        "namespace": namespace
      }, 
      "spec": {
        "accessModes": [
          "ReadWriteMany"
        ], 
        "resources": {
          "requests": {
            "storage": "10Gi"
          }
        }, 
        "selector": {
          "matchLabels": {
            "app": "dkube-spinner"
          }
        }, 
        "storageClassName": "", 
        "volumeName": "dkube-spinner"
      }
    }, // pvc
    dkubeService(dkubeApiServerAddr):: {
      local dkubeApiServerAddrArray = std.split(dkubeApiServerAddr, ":"),
      local dkubeApiServerPort = std.parseInt(dkubeApiServerAddrArray[std.length(dkubeApiServerAddrArray)-1]),
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "annotations": {
          "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_spinner_apiserver\nprefix: /GPUaaS/\nrewrite: /GPUaaS/\ntimeout_ms: 60000\nservice: dkube-spinner:" + dkubeApiServerPort
        }, 
        "labels": {
          "app": "dkube-spinner"
        }, 
        "name": "dkube-spinner", 
        "namespace": namespace
      }, 
      "spec": {
        "clusterIP": "None", 
        "ports": [
          {
            "name": "api-server", 
            "port": dkubeApiServerPort, 
            "protocol": "TCP", 
            "targetPort": dkubeApiServerPort
          }
        ], 
        "selector": {
          "app": "dkube-spinner"
        }, 
        "type": "ClusterIP"
      }
    },  // service
    dkube(apiServerImage, apiServerAddr, mountPath, tfcontrollerImage, dkubePachdClientImage, logCollectorImage, pachdAddr):: {
      "apiVersion": "extensions/v1beta1", 
      "kind": "Deployment", 
      "metadata": {
        "name": "dkube-spinner", 
        "namespace": namespace
      }, 
      "spec": {
        "selector": {
          "matchLabels": {
            "app": "dkube-spinner"
          }
        }, 
        "template": {
          "metadata": {
            "labels": {
              "app": "dkube-spinner"
            }
          }, 
          "spec": {
            "nodeSelector": {
              "node-role.kubernetes.io/master": ""
            },
            "tolerations": [
              {
                key: "node-role.kubernetes.io/master",
                operator: "Equal",
                value: "",
                effect: "NoSchedule"
              }
            ],
            "containers": [
              {
                "env": [
                  {
                    "name": "DKUBE_MOUNT_PATH", 
                    "value": mountPath
                  },
                  {
                    "name": "ADDRESS",
                    "value": pachdAddr
                  },
                  {
                    "name": "DKUBE_SERVER",
                    "value": apiServerAddr
                  }
                ], 
                "image": dkubePachdClientImage, 
                "imagePullPolicy": "IfNotPresent", 
                "name": "pachd-client", 
                "ports": [
                  {
                    "containerPort": 7007, 
                    "name": "server", 
                    "protocol": "TCP"
                  }
                ], 
                "volumeMounts": [
                  {
                    "mountPath": "/var/lib/tf-operator", 
                    "name": "shared-dir"
                  }, 
                  {
                    "mountPath": mountPath, 
                    "name": "store"
                  }
                ]
              }, 
              {
                "command": [
                  "gunicorn", 
                  "--workers=2", 
                  "-k", 
                  "gthread", 
                  "--threads", 
                  "4", 
                  "server:APP", 
                  "--bind", 
                  "0.0.0.0:5000"
                ], 
                "env": [
                  {
                    "name": "DKUBE_MOUNT_PATH", 
                    "value": mountPath
                  }
                ], 
                "image": apiServerImage, 
                "imagePullPolicy": "IfNotPresent", 
                "name": "api-server", 
                "ports": [
                  {
                    "containerPort": 5000, 
                    "name": "api-server", 
                    "protocol": "TCP"
                  }
                ], 
                "volumeMounts": [
                  {
                    "mountPath": "/var/lib/tf-operator", 
                    "name": "shared-dir"
                  }, 
                  {
                    "mountPath": mountPath, 
                    "name": "store"
                  },
                  {
                    "mountPath": "/tmp/dkube/dkube.db",
                    "name": "db-file"
                  }
                ]
              }, 
              {
                "env": [
                  {
                    "name": "DKUBE_SERVER", 
                    "value": apiServerAddr
                  }, 
                  {
                    "name": "DKUBE_MOUNT_PATH", 
                    "value": mountPath
                  },
                  {
                    "name": "DKUBE_NAMESPACE",
                    "valueFrom": {
                      "fieldRef": {
                        "apiVersion": "v1", 
                        "fieldPath": "metadata.namespace"
                      }
                    }
                  }
                ], 
                "image": tfcontrollerImage, 
                "imagePullPolicy": "IfNotPresent", 
                "name": "tf-controller",
                "command": [
                  "/tf-controller"
                ],
                "volumeMounts": [
                  {
                    "mountPath": "/var/lib/tf-operator", 
                    "name": "shared-dir"
                  }, 
                  {
                    "mountPath": mountPath, 
                    "name": "store"
                  }
                ]
              },
              {
                "name": "log-collector",
                "image": logCollectorImage,
                "imagePullPolicy": "IfNotPresent",
              }
            ], 
            "serviceAccount": "dkube-spinner", 
            "volumes": [
              {
                "emptyDir": {}, 
                "name": "shared-dir"
              }, 
              {
                "name": "store", 
                "persistentVolumeClaim": {
                  "claimName": "dkube-spinner"
                }
              },
              {
                "name": "db-file",
                "hostPath": {
                  "path": "/root/dkube/dkube.db"
                }
              }
            ]
          }
        }
      }
    }, // deployment
    dkubeUserClusterRole():: {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "ClusterRole", 
      "metadata": {
        "name": "dkube-spinner-user-clusterrole"
      }, 
      "rules": [
        {
          "apiGroups": [
            "*"
          ], 
          "resources": [
            "persistentvolumes"
          ], 
          "verbs": [
            "*"
          ]
        }
      ]
    }, // clusterrole
    dkubeUserRole():: {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "ClusterRole", 
      "metadata": {
        "name": "dkube-spinner-user-role"
      }, 
      "rules": [
        {
          "apiGroups": [
            "*"
          ], 
          "resources": [
            "*"
          ], 
          "verbs": [
            "*"
          ]
        }, 
        {
          "nonResourceURLs": [
            "*"
          ], 
          "verbs": [
            "*"
          ]
        }
      ]
    }, // role
  }, // parts
}

