{
  all(params):: [
    $.parts(params.namespace, params.nodebind).deploy(params.tag , params.dkubeUIImage, params.dkubeDockerSecret),
  ],

  parts(namespace, nodebind):: {
    deploy(tag,dkubeUIImage, dkubeDockerSecret):: {
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
            "nodeSelector": if nodebind == "yes" then {"d3.nodetype": "dkube"} else {},
            "containers": [
              {
                 "command": [
                   "bash",
                   "-c",
                   "while true;\ndo\n    nc dfabproxy.dkube 8000 -zv -w 5\n    ret1=$? \n    nc dkube-d3api.dkube 5000 -zv -w 5\n    ret2=$? \n    if (( ret1 == 0 && ret2 == 0 )); then\n        break   \n    fi      \n    sleep 5\ndone\nbash /entrypoint.sh\n"
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
    }  // deploy
  },  // parts
}
