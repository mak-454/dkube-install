{
  all(params):: [
    {
      "apiVersion": "v1",
      "data": {
        "custom-sriov.conf": "{\n \"name\": \"multus-cni-sriov\",\n \"type\": \"multus\",\n \"delegates\": [\n    {\n      \"type\": \"flannel\",\n      \"name\": \"cbr0\",\n      \"delegate\": {\n        \"isDefaultGateway\": true,\n        \"hairpinMode\": true\n      }\n    },\n    {\n    \"type\": \"sriov\",\n    \"name\": \"sriov\",\n    \"if0\": \"ens3f1\",\n    \"ipam\": {\n      \"type\": \"host-local\",\n      \"subnet\": \"\",\n      \"rangeStart\": \"\",\n      \"rangeEnd\": \"\",\n      \"routes\": [\n        {\"dst\": \"0.0.0.0/0\"}\n      ],\n      \"gateway\": \"\"\n    }\n    }\n  ],\n \"kubeconfig\": \"/etc/cni/net.d/multus.d/multus.kubeconfig\"\n}\n"
      },
      "kind": "ConfigMap",
      "metadata": {
        "labels": {
          "app": "custom",
          "tier": "node"
        },
        "name": "custom-ipam-cfg",
        "namespace": "dkube"
      }
    },

    {
      "apiVersion": "extensions/v1beta1",
      "kind": "DaemonSet",
      "metadata": {
        "labels": {
          "app": "custom-ipam",
          "tier": "node"
        },
        "name": "kube-custom-ipam-requestor",
        "namespace": "dkube"
      },
      "spec": {
        "template": {
          "metadata": {
            "labels": {
              "app": "custom-ipam",
              "tier": "node"
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
                "args": [
                  "echo starting; cp -f /cfg/custom-sriov.conf /etc/cni/net.d/10-custom-sriov.conf; python /requestor.py; sleep infinity"
                ],
                "command": [
                  "/bin/sh",
                  "-c"
                ],
                "image": params.ipamRequestorImage,
                "name": "ipam-requestor",
                "resources": {
                  "limits": {
                    "cpu": "100m",
                    "memory": "50Mi"
                  },
                  "requests": {
                    "cpu": "10m",
                    "memory": "50Mi"
                  }
                },
                "securityContext": {
                  "privileged": true
                },
                "volumeMounts": [
                  {
                    "mountPath": "/etc/cni/net.d",
                    "name": "cni"
                  },
                  {
                    "mountPath": "/cfg",
                    "name": "custom-cfg"
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
            "nodeSelector": {
              "name": "d3-rdma-enabled"
            },
            "tolerations": [
              {
                "effect": "NoSchedule",
                "operator": "Exists",
                "key": "node-role.kubernetes.io/master"
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
                "configMap": {
                  "name": "custom-ipam-cfg"
                },
                "name": "custom-cfg"
              }
            ]
          }
        },
        "updateStrategy": {
          "type": "RollingUpdate"
        }
      }
    }
  ]
}

