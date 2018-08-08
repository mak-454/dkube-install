{
  all(params):: [
    $.parts(params.namespace).dkubeServiceAccount(),
    $.parts(params.namespace).dkubeClusterRole(),
    $.parts(params.namespace).dkubeClusterRoleBinding(),
    $.parts(params.namespace).dkubeService(params.dkubeApiServerAddr),
    $.parts(params.namespace).dkube(params.dkubeApiServerImage, params.dkubeApiServerAddr, params.dkubeMountPath, params.dkubeTFControllerImage, params.dkubeLogCollectorImage, params.dkubeDownloadManagerImage, params.dkubeVersionManagerImage, params.dkubeStorageImage, params.dkubeInitImage),
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
    dkube(apiServerImage, apiServerAddr, mountPath, tfcontrollerImage, logCollectorImage, dkubeDownloadManagerImage, dkubeVersionManagerImage, dkubeStorageImage, dkubeInitImage):: {
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
                "command": ["/tmp/shared_dir/entrypoint.sh"],
                "args": [
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
                  },
                  {
                      "name": "DKUBE_DB_PATH",
                      "value": "/tmp/dkube/dkube.db"
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
                    "mountPath": "/tmp/shared_dir", 
                    "name": "shared-dir"
                  }, 
                  {
                    "mountPath": mountPath + ":shared", 
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
                "command": ["/tmp/shared_dir/entrypoint.sh"],
                "args": [
                  "/tf-controller"
                ],
                "volumeMounts": [
                  {
                    "mountPath": "/tmp/shared_dir", 
                    "name": "shared-dir"
                  }, 
                  {
                    "mountPath": mountPath + ":shared", 
                    "name": "store"
                  }
                ]
              },
              //{
              //  "name": "log-collector",
              //  "image": logCollectorImage,
              //  "imagePullPolicy": "IfNotPresent",
              //},
              {
                "args": [
                  "download-manager"
                ], 
                "command": [
                  "/tmp/shared_dir/entrypoint.sh"
                ], 
                "env": [
                  {
                    "name": "MOUNTPATH", 
                    "value": "/tmp/store"
                  }, 
                  {
                    "name": "DKUBE_SERVER", 
                    "value": apiServerAddr
                  }
                ], 
                "image": dkubeDownloadManagerImage, 
                "imagePullPolicy": "IfNotPresent", 
                "name": "download-manager", 
                "volumeMounts": [
                  {
                    "mountPath": "/tmp/store:shared", 
                    "name": "store"
                  }, 
                  {
                    "mountPath": "/tmp/shared_dir", 
                    "name": "shared-dir"
                  }
                ]
              },
              {
                "args": [
                  "python", 
                  "/opt/dkube/version-manager/server.py"
                ], 
                "command": [
                  "/tmp/shared_dir/entrypoint.sh"
                ], 
                "env": [
                  {
                    "name": "MOUNTPATH", 
                    "value": "/tmp/store"
                  }
                ], 
                "image": dkubeVersionManagerImage, 
                "imagePullPolicy": "IfNotPresent", 
                "name": "version-manager", 
                "volumeMounts": [
                  {
                    "mountPath": "/tmp/store:shared", 
                    "name": "store"
                  }, 
                  {
                    "mountPath": "/tmp/shared_dir", 
                    "name": "shared-dir"
                  }
                ]
              },
              {
                "command": [
                  "/s3fsmount", 
                  "MOUNT"
                ], 
                "env": [
                  {
                    "name": "ACCESS_KEY", 
                    "value": "dkube"
                  }, 
                  {
                    "name": "SECRET_KEY", 
                    "value": "dkube123"
                  }, 
                  {
                    "name": "S3_BUCKET", 
                    "value": "dkube"
                  }, 
                  {
                    "name": "S3_URL", 
                    "value": "http://minio-service:9000"
                  }, 
                  {  
                    "name": "S3_TYPE",
                    "value": "minio"
                  },  
                  {
                    "name": "MODE", 
                    "value": "controller"
                  },
                  {  
                    "name": "DATUMS_PATH_PREFIX", 
                    "value": "/tmp/store"
                  }
                ], 
                "image": dkubeStorageImage, 
                "imagePullPolicy": "IfNotPresent", 
                "lifecycle": {
                  "preStop": {
                    "exec": {
                      "command": [
                        "/bin/sh", 
                        "-c", 
                        "/s3fsmount UNMOUNT"
                      ]
                    }
                  }
                }, 
                "name": "sidecar", 
                "securityContext": {
                  "privileged": true
                }, 
                "volumeMounts": [
                  {
                    "mountPath": "/tmp/store:shared", 
                    "name": "store"
                  }, 
                  {
                    "mountPath": "/tmp/shared_dir", 
                    "name": "shared-dir"
                  }
                ]
              }
            ],
            "initContainers": [
              {
                "image": dkubeInitImage, 
                "imagePullPolicy": "IfNotPresent", 
                "name": "init", 
                "volumeMounts": [
                  {
                    "mountPath": "/tmp/shared_dir", 
                    "name": "shared-dir"
                  }
                ]
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
                "hostPath": {
                  "path": "/var/dkube/spinner",
                  "type": "DirectoryOrCreate"
                }
              },
              {
                "name": "db-file",
                "hostPath": {
                  "path": "/var/dkube/dkube.db",
                  "type": "FileOrCreate"
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

