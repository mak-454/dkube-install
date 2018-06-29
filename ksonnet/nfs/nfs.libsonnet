{
  all(params):: [
    {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "name": "nfs-provisioner", 
        "namespace": "dkube"
      }, 
      "spec": {
        "clusterIP": "10.96.0.20", 
        "ports": [
          {
            "name": "nfs", 
            "port": 2049, 
            "protocol": "TCP", 
            "targetPort": 2049
          }, 
          {
            "name": "mountd", 
            "port": 20048, 
            "protocol": "TCP", 
            "targetPort": 20048
          }, 
          {
            "name": "rpcbind", 
            "port": 111, 
            "protocol": "TCP", 
            "targetPort": 111
          }
        ], 
        "selector": {
          "app": "nfs-provisioner"
        }
      }
    },
    {
      "apiVersion": "extensions/v1beta1", 
      "kind": "Deployment", 
      "metadata": {
        "labels": {
          "app": "nfs-provisioner"
        }, 
        "name": "nfs-provisioner", 
        "namespace": "dkube"
      }, 
      "spec": {
        "replicas": 1, 
        "selector": {
          "matchLabels": {
            "app": "nfs-provisioner"
          }
        }, 
        "template": {
          "metadata": {
            "labels": {
              "app": "nfs-provisioner"
            }
          }, 
          "spec": {
            "containers": [
              {
                "image": "gcr.io/google-samples/nfs-server:1.1", 
                "imagePullPolicy": "IfNotPresent", 
                "name": "nfs-server", 
                "ports": [
                  {
                    "containerPort": 2049, 
                    "name": "nfs", 
                    "protocol": "TCP"
                  }, 
                  {
                    "containerPort": 20048, 
                    "name": "mountd", 
                    "protocol": "TCP"
                  }, 
                  {
                    "containerPort": 111, 
                    "name": "rpcbind", 
                    "protocol": "TCP"
                  }
                ], 
                "resources": {}, 
                "securityContext": {
                  "privileged": true
                }, 
                "volumeMounts": [
                  {
                    "mountPath": "/exports", 
                    "name": "export-volume"
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
                "operator": "Equal", 
                "value": ""
              }
            ], 
            "volumes": [
              {
                "hostPath": {
                  "path": "/var/dkube/store", 
                  "type": ""
                }, 
                "name": "export-volume"
              }
            ]
          }
        }
      }
    }
  ]
}

