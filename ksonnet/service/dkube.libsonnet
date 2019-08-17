{
  all(params):: [
    $.parts(params.namespace).katibServiceMapping(),
    $.parts(params.namespace).pipelineUIServiceMapping(),
    $.parts(params.namespace).kubeflowArgoUIServiceMapping(),
    $.parts(params.namespace).dkubeServiceAccount(),
    $.parts(params.namespace).dkubeClusterRoleBinding(params.dkubeClusterRole),
    $.parts(params.namespace).dkubeService(params.dkubeApiServerAddr),
    $.parts(params.namespace).dkubeHeadlessService(params.dkubeApiServerAddr),
    $.parts(params.namespace).dkubeAuthService(),
    $.parts(params.namespace).dkubeDexCM(),
    $.parts(params.namespace).dkubeDexClusterRole(),
    $.parts(params.namespace).dkubeDexClusterRoleBinding()
  ],

  parts(namespace):: {

    katibServiceMapping():: {
      "apiVersion": "v1",
      "kind": "Service",
      "metadata": {
        "annotations": {
          "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  \"katib\"\ntimeout_ms: 600000\nuse_websocket: true\nprefix: \"/katib\"\nrewrite: \"/katib\"\nservice: \"katib-ui.kubeflow:80\""
        },
        "name": "katib-maping-service",
        "namespace": "dkube"
      },
      "spec": {
        "clusterIP": "None",
        "sessionAffinity": "None",
        "type": "ClusterIP"
      }
    },
    pipelineUIServiceMapping():: {
        "apiVersion": "v1",
        "kind": "Service",
        "metadata": {
            "annotations": {
                "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname: pipelineui-mapping\nprefix: /pipeline\nrewrite: /pipeline\ntimeout_ms: 300000\nservice: ml-pipeline-ui.kubeflow\nuse_websocket: true"
            },
            "labels": {
                "app": "ml-pipeline-ui"
            },
            "name": "ml-pipeline-ui-mapping-service",
            "namespace": "dkube",
        },
        "spec": {
            "clusterIP": "None",
            "type": "ClusterIP"
        }
    },
    kubeflowArgoUIServiceMapping():: {
	  "apiVersion": "v1",
	  "kind": "Service",
	  "metadata": {
	  	"annotations": {
	  		"getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname: argoui-mapping\nprefix: \"/argo/logs/\"\nrewrite: \"/api/logs/\"\ntimeout_ms: 300000\nservice: \"argo-ui.kubeflow:80\"\nuse_websocket: true"
	  	},
	  	"name": "argo-ui-mapping-service",
	  	"namespace": "dkube"
	  },
	  "spec": {
	  	"clusterIP": "None",
	  	"sessionAffinity": "None",
	  	"type": "ClusterIP"
	  }
	},
    dkubeServiceAccount():: {
      "apiVersion": "v1", 
      "kind": "ServiceAccount",
      "metadata": {
        "name": "dkube", 
        "namespace": namespace
      }
    }, // service account
    dkubeClusterRoleBinding(dkubeClusterRole):: {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "ClusterRoleBinding", 
      "metadata": {
        "name": "dkube"
      }, 
      "roleRef": {
        "apiGroup": "rbac.authorization.k8s.io", 
        "kind": "ClusterRole", 
        "name": dkubeClusterRole
      }, 
      "subjects": [
        {
          "kind": "ServiceAccount", 
          "name": "dkube", 
          "namespace": namespace
        }
      ]
    },  // cluster role binding
    dkubeService(dkubeApiServerAddr):: {
      local dkubeApiServerAddrArray = std.split(dkubeApiServerAddr, ":"),
      local dkubeApiServerPort = std.parseInt(dkubeApiServerAddrArray[std.length(dkubeApiServerAddrArray)-1]),

      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "annotations": {
          "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_d3api\nprefix: /dkube/v2\nrewrite: /dkube/v2\ntimeout_ms: 600000\nservice: dkube-d3api:5000"
        }, 
        "labels": {
          "app": "dkube-d3api"
        }, 
        "name": "dkube-d3api", 
        "namespace": namespace
      }, 
      "spec": {
        "ports": [
          {
            "name": "dkube-d3api", 
            "port": dkubeApiServerPort, 
            "protocol": "TCP", 
            "targetPort": dkubeApiServerPort
          }
        ], 
        "selector": {
          "app": "dkube-d3api"
        }, 
        "type": "ClusterIP"
      }
    }, //service
    dkubeHeadlessService(dkubeApiServerAddr):: {
      local dkubeApiServerAddrArray = std.split(dkubeApiServerAddr, ":"),
      local dkubeApiServerPort = std.parseInt(dkubeApiServerAddrArray[std.length(dkubeApiServerAddrArray)-1]),

      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "labels": {
          "app": "dkube-d3api"
        }, 
        "name": "dkube-d3api-headless", 
        "namespace": namespace
      }, 
      "spec": {
        "clusterIP": "None",
        "ports": [
          {
            "name": "dkube-d3api", 
            "port": dkubeApiServerPort, 
            "protocol": "TCP", 
            "targetPort": dkubeApiServerPort
          }
        ], 
        "selector": {
          "app": "dkube-d3api"
        }, 
        "type": "ClusterIP"
      }
    }, //service
    dkubeAuthService():: {
        "apiVersion": "v1",
        "kind": "Service",
        "metadata": {
            "annotations": {
                "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  d3auth-login\nprefix: /dkube/v2/login\nrewrite: /login\ntimeout_ms: 600000\nservice: dkube-d3auth:3001\n---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  d3auth-logout\nprefix: /dkube/v2/logout\nrewrite: /logout\ntimeout_ms: 600000\nservice: dkube-d3auth:3001"
            },
            "labels": {
                "app": "d3auth"
            },
            "name": "dkube-d3auth",
            "namespace": "dkube",
        },
        "spec": {
            "ports": [
            {
                "name": "dex-s",
                "port": 5556,
                "protocol": "TCP",
                "targetPort": 5556
            },
            {
                "name": "authn",
                "port": 3001,
                "protocol": "TCP",
                "targetPort": 3001
            }
            ],
            "selector": {
                "app": "d3auth"
            },
            "type": "ClusterIP"
        },
    },
    dkubeDexCM():: {
        "apiVersion": "v1",
        "data": {
            "config.yaml": "issuer: http://127.0.0.1:5556/dex\nstorage:\n  type: kubernetes\n  config:\n    inCluster: true\nweb:\n  http: 0.0.0.0:5556\ntelemetry:\n  http: 0.0.0.0:5558\nexpiry:\n  idTokens: \"72h\"\nstaticClients:\n- id: dkube-app\n  redirectURIs:\n  - 'http://127.0.0.1:3001/cb'\n  name: 'Dkube App'\n  secret: ZXhhbXBsZS1hcHAtc2VjcmV0\nconnectors:\n- type: dkube\n  id: dkube\n  name: Dkube\n  config:\n    username: fake\n    password: fakeAgain\nenablePasswordDB: true\nstaticPasswords:\n- email: \"admin@example.com\"\n  # bcrypt hash of the string \"password\"\n  hash: \"$2a$10$2b2cU8CPhOTaGrs1HRQuAueS7JTT5ZHsHSzYiFPm1leZck7Mc8T4W\"\n  username: \"admin\"\n  userID: \"08a8684b-db88-4b73-90a9-3cd1661f5466\"\n"
        },
        "kind": "ConfigMap",
        "metadata": {
            "name": "dex",
            "namespace": "dkube",
        }
    },
    dkubeDexClusterRole():: {
        "apiVersion": "rbac.authorization.k8s.io/v1",
        "kind": "ClusterRole",
        "metadata": {
            "name": "dex",
        },
        "rules": [
        {
            "apiGroups": [
                "dex.coreos.com"
            ],
            "resources": [
                "*"
            ],
            "verbs": [
                "*"
            ]
        },
        {
            "apiGroups": [
                "apiextensions.k8s.io"
            ],
            "resources": [
                "customresourcedefinitions"
            ],
            "verbs": [
                "create"
            ]
        }
        ]
    },
    dkubeDexClusterRoleBinding():: {
        "apiVersion": "rbac.authorization.k8s.io/v1",
        "kind": "ClusterRoleBinding",
        "metadata": {
            "name": "dex",
        },
        "roleRef": {
            "apiGroup": "rbac.authorization.k8s.io",
            "kind": "ClusterRole",
            "name": "dex"
        },
        "subjects": [
        {
            "kind": "ServiceAccount",
            "name": "dkube",
            "namespace": "dkube"
        }
        ]
    },
  }, // parts
}

