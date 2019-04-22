{
  all(params):: [
    {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "annotations": {
            "getambassador.io/config": "---\n  apiVersion: ambassador/v0\n  kind: Mapping\n  name: dkube_minio\n  prefix: /minio/\n  rewrite: /\n  timeout_ms: 600000\n  service: minio-service:9000\n"},
        "name": "minio-service",
        "namespace": "dkube"
      }, 
      "spec": {
        "ports": [
          {
            "port": 9000, 
            "nodePort": 32223,
            "protocol": "TCP", 
            "targetPort": 9000
          }
        ], 
        "selector": {
          "app": "minio"
        },
        "type": "NodePort"
      }
    },

    {
      "kind": "PersistentVolumeClaim",
      "apiVersion": "v1",
      "metadata": {
        "name": "minio-pvc",
        "namespace": "dkube"
      },
      "spec": {
        "accessModes": [
          "ReadWriteMany"
        ],
        "storageClassName": params.storageClass,
        "resources": {
          "requests": {
            "storage": "100Gi"
          }
        },
        [if params.storageClass=="" then "volumeName"]: params.minioStoragePV
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
                "d3.nodetype": "dkube"
            },
            "tolerations": [
              {
                "operator": "Exists"
              },
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
                    "value": params.minioSecretKey
                  }
                ], 
                "image": "minio/minio:RELEASE.2018-12-13T02-04-19Z",
                "imagePullPolicy": "IfNotPresent", 
                "name": "minio", 
                "ports": [
                  {
                    "containerPort": 9000, 
                    "protocol": "TCP"
                  }
                ], 
                "resources": {
                  "limits": {
                    "memory": "5Gi"
                  }
                },
                "volumeMounts": [
                  {
                    "mountPath": "/storage", 
                    "name": "storage"
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
            "volumes": [
              {
                "persistentVolumeClaim": {
                  "claimName": "minio-pvc",
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

