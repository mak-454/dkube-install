{
  all(params):: [
    {
      "apiVersion": "v1",
      "kind": "Service",
      "metadata": {
        "name": "dkube-etcd-server",
        "namespace": "dkube"
      },
      "spec": {
        "ports": [
          {
            "port": 2379,
            "protocol": "TCP",
            "targetPort": 2379
          }
        ],
        "selector": {
          "app": "dkube-etcd-server"
        },
        "type": "ClusterIP"
      }
    },
    {
      "apiVersion": "extensions/v1beta1",
      "kind": "Deployment",
      "metadata": {
        "name": "dkube-etcd-server",
        "namespace": "dkube"
      },
      "spec": {
        "selector": {
          "matchLabels": {
            "app": "dkube-etcd-server"
          }
        },
        "template": {
          "metadata": {
            "labels": {
              "app": "dkube-etcd-server"
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
                "command": [
                  "etcd",
                  "--listen-client-urls=http://0.0.0.0:2379",
                  "--advertise-client-urls=http://0.0.0.0:2379",
                  "--data-dir=/var/lib/etcd"
                ],
                "image": "k8s.gcr.io/etcd-amd64:3.1.12",
                "imagePullPolicy": "IfNotPresent",
                "name": "etcd",
                "volumeMounts": [
                  {
                    "mountPath": "/var/lib/etcd",
                    "name": "etcd-data"
                  }
                ]
              }
            ],
            "volumes": [
              {
                "hostPath": {
                  "path": "/var/dkube/etcd"
                },
                "name": "etcd-data"
              }
            ]
          }
        }
      }
    }

  ],
}
