{
  all(params):: [
    {
      "apiVersion": "v1",
      "kind": "Service",
      "metadata": {
        "name": "custom-sriov-ipam",
        "namespace": "dkube"
      },
      "spec": {
        "ports": [
          {
            "name": "ipam",
            "port": 8889,
            "protocol": "TCP",
            "targetPort": 8889
          }
        ],
        "selector": {
          "app": "custom-sriov-ipam"
        },
        "type": "ClusterIP"
      }
    },

    {
      "apiVersion": "apps/v1",
      "kind": "Deployment",
      "metadata": {
        "name": "custom-sriov-ipam",
        "namespace": "dkube"
      },
      "spec": {
        "replicas": 1,
        "selector": {
          "matchLabels": {
            "app": "custom-sriov-ipam"
          }
        },
        "template": {
          "metadata": {
            "labels": {
              "app": "custom-sriov-ipam"
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
                  "echo starting; ipam"
                ],
                "command": [
                  "/bin/sh",
                  "-c"
                ],
                "image": params.ipamImage,
                "imagePullPolicy": "IfNotPresent",
                "name": "ipam"
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
          }
        }
      }
    }
  ]
}

