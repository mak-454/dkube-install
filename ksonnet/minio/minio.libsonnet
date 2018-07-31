{
  all(params):: [
    {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "name": "minio-service", 
        "namespace": "dkube"
      }, 
      "spec": {
        "clusterIP": "10.96.0.22",
        "ports": [
          {
            "port": 9000, 
            "protocol": "TCP", 
            "targetPort": 9000
          }
        ], 
        "selector": {
          "app": "minio"
        }
      }
    },
    {
      "apiVersion": "extensions/v1beta1", 
      "kind": "Deployment", 
      "metadata": {
        "labels": {
          "app": "minio"
        }, 
        "name": "minio-deployment", 
        "namespace": "dkube"
      }, 
      "spec": {
        "replicas": 1, 
        "selector": {
          "matchLabels": {
            "app": "minio"
          }
        }, 
        "template": {
          "metadata": {
            "labels": {
              "app": "minio"
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
                "args": [
                  "server", 
                  "/storage"
                ], 
                "env": [
                  {
                    "name": "MINIO_ACCESS_KEY", 
                    "value": "dkube"
                  }, 
                  {
                    "name": "MINIO_SECRET_KEY", 
                    "value": "dkube123"
                  }
                ], 
                "image": "minio/minio:RELEASE.2018-05-04T23-13-12Z", 
                "imagePullPolicy": "IfNotPresent", 
                "name": "minio", 
                "ports": [
                  {
                    "containerPort": 9000, 
                    "protocol": "TCP"
                  }
                ], 
                "resources": {}, 
                "volumeMounts": [
                  {
                    "mountPath": "/storage", 
                    "name": "storage"
                  }
                ]
              }
            ], 
            "volumes": [
              {
                "hostPath": {
                  "path": "/var/dkube/minio", 
                  "type": ""
                }, 
                "name": "storage"
              }
            ]
          }
        }
      }
    }
  ]
}

