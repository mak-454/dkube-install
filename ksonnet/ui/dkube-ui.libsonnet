{
  all(params):: [
    $.parts(params.namespace).deploy(params.tag , params.dkubeUIImage, params.dkubeDockerSecret, params.dkubeGithubAppSecret),
  ],

  parts(namespace):: {
    deploy(tag,dkubeUIImage, dkubeDockerSecret, dkubeGithubAppSecret):: {
      "apiVersion": "extensions/v1beta1", 
      "kind": "Deployment", 
      "metadata": {
        "labels": {
          "app": "dkube-ui"
        }, 
        "name": "dkube-ui-" + tag, 
        "namespace": namespace
      }, 
      "spec": {
        "selector": {
          "matchLabels": {
            "app": "dkube-ui"
          }
        }, 
        "template": {
          "metadata": {
            "labels": {
              "app": "dkube-ui"
            }
          }, 
          "spec": {
            "imagePullSecrets": [
              {
                "name": dkubeDockerSecret
              }
            ],
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
                "env": [
                  {
                    "name": "GIT_CLIENT_ID", 
                    "valueFrom": {
                      "secretKeyRef": {
                        "key": "client-id", 
                        "name": dkubeGithubAppSecret
                      }
                    }
                  }, 
                  {
                    "name": "GIT_CLIENT_SECRET", 
                    "valueFrom": {
                      "secretKeyRef": {
                        "key": "client-secret", 
                        "name": dkubeGithubAppSecret
                      }
                    }
                  }
                ], 
                "image": dkubeUIImage, 
                "imagePullPolicy": "IfNotPresent", 
                "name": "ui", 
                "ports": [
                  {
                    "containerPort": 3000, 
                    "name": "ui", 
                    "protocol": "TCP"
                  }
                ]
              }
            ]
          }
        }
      }
    }  // deploy
  },  // parts
}
