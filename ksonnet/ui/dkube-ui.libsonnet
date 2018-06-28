{
  all(params):: [
    $.parts(params.namespace).service(),
    $.parts(params.namespace).deploy(params.dkubeUIImage, params.restServerEndpoint),
  ],

  parts(namespace):: {
    service():: {
      apiVersion: "v1",
      kind: "Service",
      metadata: {
        labels: {
          service: "dkube-ui",
        },
        "annotations": {
          "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_ui\nprefix: /dkube/ui\nrewrite: /dkube/ui\nservice: dkube-ui:3000\ntimeout_ms: 60000"
        },
        name: "dkube-ui",
        namespace: namespace,
      },
      spec: {
        ports: [
          {
            name: "ui",
            port: 3000,
            targetPort: 3000,
          },
        ],
        selector: {
          app: "dkube-ui",
        },
        type: "ClusterIP",
      },
    },  // service

    deploy(dkubeUIImage, restServerEndpoint):: {
      "apiVersion": "extensions/v1beta1", 
      "kind": "Deployment", 
      "metadata": {
        "labels": {
          "app": "dkube-ui"
        }, 
        "name": "dkube-ui", 
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
            "imagePullSecrets": [
              {
                "name": "dkube-dockerhub-secret"
              }
            ],
            "containers": [
              {
                "env": [
                  {
                    "name": "REST_SERVER_ENDPOINT", 
                    "value": restServerEndpoint
                  }, 
                  {
                    "name": "GIT_CLIENT_ID", 
                    "valueFrom": {
                      "secretKeyRef": {
                        "key": "client-id", 
                        "name": "dkube-github-app-secret"
                      }
                    }
                  }, 
                  {
                    "name": "GIT_CLIENT_SECRET", 
                    "valueFrom": {
                      "secretKeyRef": {
                        "key": "client-secret", 
                        "name": "dkube-github-app-secret"
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
    },  // deploy
  },  // parts
}
