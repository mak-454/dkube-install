{
  all(params):: [
    $.parts(params.namespace).dkubeServiceAccount(),
    $.parts(params.namespace).dkubeClusterRole(),
    $.parts(params.namespace).dkubeClusterRoleBinding(),
    $.parts(params.namespace).dkubeService(params.dkubeApiServerAddr),
    $.parts(params.namespace).dkube(params.dkubeApiServerImage, params.dkubeApiServerAddr, params.dkubeMountPath, params.dkubeApiServerAddr),
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
        "name": "dkube", 
        "namespace": namespace
      }
    }, // service account
    dkubeClusterRole():: {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "ClusterRole", 
      "metadata": {
        "name": "dkube"
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
        },
        {
            "apiGroups": [
                ""
            ],
            "resources": [
                "namespaces",
                "nodes"
            ],
            "verbs": [
                "*"
            ]
        },
        {
            "apiGroups": [
                "rbac.authorization.k8s.io"
            ],
            "resources": [
                "roles",
                "rolebindings"
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
                "serviceaccounts",
                "secrets"
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
        "name": "dkube"
      }, 
      "roleRef": {
        "apiGroup": "rbac.authorization.k8s.io", 
        "kind": "ClusterRole", 
        "name": "dkube"
      }, 
      "subjects": [
        {
          "kind": "ServiceAccount", 
          "name": "dkube", 
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
          "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_d3api\nprefix: /dkube/v2\nrewrite: /dkube/v2\ntimeout_ms: 60000\nservice: dkube-d3api:5000"
        }, 
        "labels": {
          "app": "dkube-d3api"
        }, 
        "name": "dkube-d3api", 
        "namespace": namespace
      }, 
      "spec": {
        "clusterIP": "None", 
        "ports": [
          {
            "name": "dkube-d3api", 
            "port": dkubeApiServerPort, 
            "protocol": "TCP", 
            "targetPort": dkubeApiServerPort
          }
        ], 
        "selector": {
          "app": "dkube-d3api"
        }, 
        "type": "ClusterIP"
      }
    },  // service
    dkube(apiServerImage, apiServerAddr, mountPath, dkubeApiServerAddr):: {
      local dkubeApiServerAddrArray = std.split(dkubeApiServerAddr, ":"),
      local dkubeApiServerPort = std.parseInt(dkubeApiServerAddrArray[std.length(dkubeApiServerAddrArray)-1]),

      "apiVersion": "extensions/v1beta1", 
      "kind": "Deployment", 
      "metadata": {
        "labels": {
          "app": "dkube-d3api"
        }, 
        "name": "dkube-d3api", 
        "namespace": namespace
      }, 
      "spec": {
        "selector": {
          "matchLabels": {
            "app": "dkube-d3api"
          }
        }, 
        "template": {
          "metadata": {
            "labels": {
              "app": "dkube-d3api"
            }
          }, 
          "spec": {
            "imagePullSecrets": [
              {
                "name": "dkube-dockerhub-secret"
              }
            ],
            "containers": [
              {
                "image": apiServerImage, 
                "imagePullPolicy": "IfNotPresent", 
                "name": "dkube-d3api", 
                "ports": [
                  {
                    "containerPort": dkubeApiServerPort, 
                    "name": "dkube-d3api", 
                    "protocol": "TCP"
                  }
                ], 
                "env": [
                  {
                    "name": "DKUBE_MOUNT_PATH", 
                    "value": mountPath
                  },
                  {
                      "name": "WORKFLOW_DIR",
                      "value": "/etc/dkube/workflows"
                  },
                  {
                      "name": "DKUBE_SERVICE_ACCOUNT",
                      "value": "dkube"
                  }
                ], 
                "volumeMounts": [
                  {
                    "mountPath": mountPath, 
                    "name": "store"
                  }
                ]
              }
            ], 
            "serviceAccount": "dkube", 
            "volumes": [
              {
                "flexVolume": {
                  "driver": "oc/d3", 
                  "options": {
                    "accessKey": "dkube", 
                    "bucket": "dkube", 
                    "endpoint": "http://10.96.0.22:9000", 
                    "s3provider": "minio", 
                    "secretKey": "dkube123"
                  }
                }, 
                "name": "store"
              }
            ]
          }
        }
      }
    }, // deployment
  }, // parts
}

