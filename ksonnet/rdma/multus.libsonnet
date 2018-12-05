{
  all(params):: [
    {
      "apiVersion": "apiextensions.k8s.io/v1beta1",
      "kind": "CustomResourceDefinition",
      "metadata": {
        "name": "network-attachment-definitions.k8s.cni.cncf.io"
      },
      "spec": {
        "group": "k8s.cni.cncf.io",
        "names": {
          "kind": "NetworkAttachmentDefinition",
          "plural": "network-attachment-definitions",
          "shortNames": [
            "net-attach-def"
          ],
          "singular": "network-attachment-definition"
        },
        "scope": "Namespaced",
        "validation": {
          "openAPIV3Schema": {
            "properties": {
              "spec": {
                "properties": {
                  "config": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "version": "v1"
      }
    },

    {
      "apiVersion": "rbac.authorization.k8s.io/v1beta1",
      "kind": "ClusterRole",
      "metadata": {
        "name": "multus"
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
    },

    {
      "apiVersion": "rbac.authorization.k8s.io/v1beta1",
      "kind": "ClusterRoleBinding",
      "metadata": {
        "name": "multus"
      },
      "roleRef": {
        "apiGroup": "rbac.authorization.k8s.io",
        "kind": "ClusterRole",
        "name": "multus"
      },
      "subjects": [
        {
          "kind": "ServiceAccount",
          "name": "multus",
          "namespace": "kube-system"
        }
      ]
    },

    {
      "apiVersion": "v1",
      "kind": "ServiceAccount",
      "metadata": {
        "name": "multus",
        "namespace": "kube-system"
      }
    },

    {
      "apiVersion": "v1",
      "data": {
        "cni-conf.json": "{\n  \"name\": \"multus-cni-sriov\",\n  \"type\": \"multus\",\n  \"delegates\": [\n    {\n      \"type\": \"flannel\",\n      \"name\": \"cbr0\",\n      \"delegate\": {\n        \"isDefaultGateway\": true\n      }\n    }\n  ],\n  \"kubeconfig\": \"/etc/cni/net.d/multus.d/multus.kubeconfig\"\n}\n"
      },
      "kind": "ConfigMap",
      "metadata": {
        "labels": {
          "app": "multus",
          "tier": "node"
        },
        "name": "multus-cni-config",
        "namespace": "kube-system"
      }
    },

    {
      "apiVersion": "extensions/v1beta1",
      "kind": "DaemonSet",
      "metadata": {
        "labels": {
          "app": "multus",
          "tier": "node"
        },
        "name": "kube-multus-ds-amd64",
        "namespace": "kube-system"
      },
      "spec": {
        "template": {
          "metadata": {
            "labels": {
              "app": "multus",
              "tier": "node"
            }
          },
          "spec": {
            "containers": [
              {
                "args": [
                  "echo starting; cp -f /multus-cfg/cni-conf.json /10-dhcp.conf; /entrypoint.sh --multus-conf-file=\"/10-dhcp.conf\"; echo done;"
                ],
                "command": [
                  "/bin/sh",
                  "-c"
                ],
                "image": params.multusImage,
                "name": "kube-multus",
                "resources": {
                  "limits": {
                    "cpu": "100m",
                    "memory": "50Mi"
                  },
                  "requests": {
                    "cpu": "100m",
                    "memory": "50Mi"
                  }
                },
                "securityContext": {
                  "privileged": true
                },
                "volumeMounts": [
                  {
                    "mountPath": "/multus-cfg",
                    "name": "multus-cfg"
                  },
                  {
                    "mountPath": "/host/etc/cni/net.d",
                    "name": "cni"
                  },
                  {
                    "mountPath": "/host/opt/cni/bin",
                    "name": "cnibin"
                  }
                ]
              }
            ],
            "hostNetwork": true,
            "nodeSelector": {
              "name": "d3-rdma-enabled"
            },
            "serviceAccountName": "multus",
            "tolerations": [
              {
                "effect": "NoSchedule",
                "key": "node-role.kubernetes.io/master",
                "operator": "Exists"
              }
            ],
            "volumes": [
              {
                "hostPath": {
                  "path": "/etc/cni/net.d"
                },
                "name": "cni"
              },
              {
                "hostPath": {
                  "path": "/opt/cni/bin"
                },
                "name": "cnibin"
              },
              {
                "configMap": {
                  "name": "multus-cni-config"
                },
                "name": "multus-cfg"
              }
            ]
          }
        }
      }
    }
  ]
}

