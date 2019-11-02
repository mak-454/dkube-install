{
  all(params):: [
    $.parts(params.namespace).katibServiceMapping(),
    $.parts(params.namespace).pipelineUIServiceMapping(),
    $.parts(params.namespace).grafanaServiceMapping(),
    $.parts(params.namespace).prometheusServiceMapping(),
    $.parts(params.namespace).kubeflowArgoUIServiceMapping(),
    $.parts(params.namespace).dkubeServiceAccount(),
    $.parts(params.namespace).dkubeClusterRoleBinding(params.dkubeClusterRole),
    $.parts(params.namespace).dkubeServiceMaster(params.dkubeApiServerAddr),
    $.parts(params.namespace).dkubeServiceWorker(params.dkubeApiServerAddr),
    $.parts(params.namespace).dkubeHeadlessServiceMaster(params.dkubeApiServerAddr),
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
        "name": "kf-katib-mapping-service",
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
            "name": "kf-pipeline-ui-mapping-service",
            "namespace": "dkube",
        },
        "spec": {
            "clusterIP": "None",
            "type": "ClusterIP"
        }
    },
    grafanaServiceMapping():: {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "annotations": {
          "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_monitoring\nprefix: /dkube/grafana/\nrewrite: /\nservice: dkube-grafana.dkube:80\ntimeout_ms: 600000\nuse_websocket: true"
        }, 
        "labels": {
          "app": "dkube-prometheus-grafana"
        }, 
        "name": "dkube-prometheus-grafana-proxy", 
        "namespace": "dkube"
      }, 
      "spec": {
        "ports": [
          {
            "name": "http", 
            "port": 80, 
            "protocol": "TCP", 
            "targetPort": 3000
          }
        ], 
        "selector": {
          "app": "dkube-prometheus-grafana"
        }, 
        "sessionAffinity": "None", 
        "type": "ClusterIP"
      }
    },
    prometheusServiceMapping():: {

	  "apiVersion": "v1", 
	  "kind": "Service", 
	  "metadata": {
		"annotations": {
		  "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  \"prometheus\"\ntimeout_ms: 600000\nuse_websocket: true\nprefix: \"/dkube/v2/prometheus/api/v1\"\nrewrite: \"/api/v1\"\nservice: \"kube-prometheus.dkube:9090\"\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\"\n---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  \"prometheus-alert-manager\"\ntimeout_ms: 600000\nuse_websocket: true\nprefix: \"/dkube/v2/prometheus/alertmanager/api/v1\"\nrewrite: \"/api/v1\"\nservice: \"kube-prometheus-alertmanager.dkube:9093\"\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\""
		}, 
		"name": "dkube-prometheus-mapping-service",
		"namespace": "dkube"
	  }, 
	  "spec": {
		"clusterIP": "None", 
		"sessionAffinity": "None", 
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
	  	"name": "kf-argo-ui-mapping-service",
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
    dkubeServiceMaster(dkubeApiServerAddr):: {
      local dkubeApiServerAddrArray = std.split(dkubeApiServerAddr, ":"),
      local dkubeApiServerPort = std.parseInt(dkubeApiServerAddrArray[std.length(dkubeApiServerAddrArray)-1]),

      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "annotations": {
            "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_d3api\nprefix: /dkube/v2\nrewrite: /dkube/v2\nmethod_regex: true\nmethod: 'POST|PUT|DELETE|OPTIONS'\ntimeout_ms: 600000\nservice: dkube-controller-master:5000"
        }, 
        "labels": {
          "app": "dkube-controller-master"
        }, 
        "name": "dkube-controller-master", 
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
          "app": "dkube-controller-master"
        }, 
        "type": "ClusterIP"
      }
    }, //service master
    dkubeHeadlessServiceMaster(dkubeApiServerAddr):: {
      local dkubeApiServerAddrArray = std.split(dkubeApiServerAddr, ":"),
      local dkubeApiServerPort = std.parseInt(dkubeApiServerAddrArray[std.length(dkubeApiServerAddrArray)-1]),

      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "labels": {
          "app": "dkube-controller-master"
        }, 
        "name": "dkube-controller-headless-master", 
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
          "app": "dkube-controller-master"
        }, 
        "type": "ClusterIP"
      }
    }, //service
    dkubeServiceWorker(dkubeApiServerAddr):: {
      local dkubeApiServerAddrArray = std.split(dkubeApiServerAddr, ":"),
      local dkubeApiServerPort = std.parseInt(dkubeApiServerAddrArray[std.length(dkubeApiServerAddrArray)-1]),

      "apiVersion": "v1",
      "kind": "Service",
      "metadata": {
        "annotations": {
          "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_d3api_worker\nprefix: /dkube/v2\nrewrite: /dkube/v2\nmethod: GET\ntimeout_ms: 600000\nservice: dkube-controller-worker:5000"
        },
        "labels": {
          "app": "dkube-controller-worker"
        },
        "name": "dkube-controller-worker",
        "namespace": namespace
      },
      "spec": {
        "ports": [
          {
            "port": dkubeApiServerPort,
            "protocol": "TCP",
            "targetPort": dkubeApiServerPort
          }
        ],
        "selector": {
          "app": "dkube-controller-worker"
        },
        "type": "ClusterIP"
      }
    }, //service worker
    dkubeAuthService():: {
        "apiVersion": "v1",
        "kind": "Service",
        "metadata": {
            "annotations": {
                "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  d3auth-dex\nprefix: /dex\nrewrite: /dex\ntimeout_ms: 600000\nservice: dkube-auth-server:5556\n---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  d3auth-login\nprefix: /dkube/v2/login\nrewrite: /login\ntimeout_ms: 600000\nservice: dkube-auth-server:3001\n---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  d3auth-logout\nprefix: /dkube/v2/logout\nrewrite: /logout\ntimeout_ms: 600000\nservice: dkube-auth-server:3001"
            },
            "labels": {
                "app": "d3auth"
            },
            "name": "dkube-auth-server",
            "namespace": "dkube",
        },
        "spec": {
            "ports": [
            {
                "name": "dex-s",
                "port": 5556,
                "protocol": "TCP",
                "targetPort": 5556,
                "nodePort": 31534,
            },
            {
                "name": "authn",
                "port": 3001,
                "protocol": "TCP",
                "targetPort": 3001,
                "nodePort": 30049,
            }
            ],
            "selector": {
                "app": "dkube-auth"
            },
            "type": "NodePort"
        },
    },
    dkubeDexCM():: {
        "apiVersion": "v1",
        "data": {
            "config.yaml": "{\r\n   \"issuer\": \"http:\/\/PUB-IP:31534\/dex\",\r\n   \"storage\": {\r\n      \"type\": \"kubernetes\",\r\n      \"config\": {\r\n         \"inCluster\": true\r\n      }\r\n   },\r\n   \"frontend\": {\r\n      \"logoURL\": \"https:\/\/PUB-IP:32222\/dex\/\",\r\n      \"extra\": {\r\n         \"dkubeUrl\": \"https:\/\/PUB-IP:32222\/dex\/theme\/logo.png\",\r\n         \"favUrl\": \"https:\/\/PUB-IP:32222\/dex\/theme\/favicon.png\",\r\n         \"mainCss\": \"https:\/\/PUB-IP:32222\/dex\/static\/main.css\",\r\n         \"styleCss\": \"https:\/\/PUB-IP:32222\/dex\/theme\/styles.css\"\r\n      }\r\n   },\r\n   \"web\": {\r\n      \"http\": \"0.0.0.0:5556\"\r\n   },\r\n   \"telemetry\": {\r\n      \"http\": \"0.0.0.0:5558\"\r\n   },\r\n   \"expiry\": {\r\n      \"idTokens\": \"72h\"\r\n   },\r\n   \"staticClients\": [\r\n      {\r\n         \"id\": \"dkube\",\r\n         \"redirectURIs\": [\r\n            \"https:\/\/PUB-IP:32222\/callback\"\r\n         ],\r\n         \"name\": \"Dkube App\",\r\n         \"secret\": \"dkube-secret\"\r\n      },\r\n      {\r\n         \"id\": \"kubeflow-authservice-oidc\",\r\n         \"redirectURIs\": [\r\n            \"https:\/\/PUB-IP:31390\/login\/oidc\"\r\n         ],\r\n         \"name\": \"Kubeflow App\",\r\n         \"secret\": \"QKQ2ZN6SDavgTBR8JnVpy2a1beiWnLiO\"\r\n      }\r\n   ],\r\n   \"oauth2\": {\r\n      \"skipApprovalScreen\": true,\r\n      \"alwaysShowLoginScreen\": true\r\n   },\r\n   \"enablePasswordDB\": true,\r\n   \"staticPasswords\": [\r\n      {\r\n         \"email\": \"L-UNAME\",\r\n         \"hash\": \"L-PASSWD\",\r\n         \"username\": \"L-UNAME\",\r\n         \"userID\": \"L-UNAME\"\r\n      }\r\n   ]\r\n}"
        },
        "kind": "ConfigMap",
        "metadata": {
            "name": "dkube-auth-config",
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

