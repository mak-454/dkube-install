{
  all(params):: [
    $.parts(params.namespace).katibServiceMapping(),
    $.parts(params.namespace).pipelineUIServiceMapping(),
    $.parts(params.namespace).grafanaServiceMapping(),
    $.parts(params.namespace).prometheusServiceMapping(),
    $.parts(params.namespace).kubeflowArgoUIServiceMapping(),
    $.parts(params.namespace).dkubeServiceAccount(),
    $.parts(params.namespace).dkubeClusterRoleBinding(params.dkubeClusterRole),
    $.parts(params.namespace).dkubeService(params.dkubeApiServerAddr),
    $.parts(params.namespace).dkubeHeadlessService(params.dkubeApiServerAddr),
    $.parts(params.namespace).dkubeAuthService(),
    $.parts(params.namespace).dkubeDexCM(),
    $.parts(params.namespace).filebeatCM(),
    $.parts(params.namespace).logstashCM(),
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
    grafanaServiceMapping():: {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "annotations": {
          "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_monitoring\nprefix: /dkube/grafana/\nrewrite: /\nservice: dkube-grafana.monitoring:80\ntimeout_ms: 600000\nuse_websocket: true"
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
		  "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  \"prometheus\"\ntimeout_ms: 600000\nuse_websocket: true\nprefix: \"/dkube/v2/prometheus/api/v1\"\nrewrite: \"/api/v1\"\nservice: \"kube-prometheus.monitoring:9090\"\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\"\n---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  \"prometheus-alert-manager\"\ntimeout_ms: 600000\nuse_websocket: true\nprefix: \"/dkube/v2/prometheus/alertmanager/api/v1\"\nrewrite: \"/api/v1\"\nservice: \"kube-prometheus-alertmanager.monitoring:9093\"\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\""
		}, 
		"name": "prometheus-maping-service", 
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
                "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  d3auth-dex\nprefix: /dex\nrewrite: /dex\ntimeout_ms: 600000\nservice: dkube-d3auth:5556\n---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  d3auth-login\nprefix: /dkube/v2/login\nrewrite: /login\ntimeout_ms: 600000\nservice: dkube-d3auth:3001\n---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  d3auth-logout\nprefix: /dkube/v2/logout\nrewrite: /logout\ntimeout_ms: 600000\nservice: dkube-d3auth:3001"
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
                "app": "d3auth"
            },
            "type": "NodePort"
        },
    },
    dkubeDexCM():: {
        "apiVersion": "v1",
        "data": {
            "config.yaml": "{\r\n   \"issuer\": \"http:\/\/PUB-IP:31534\/dex\",\r\n   \"storage\": {\r\n      \"type\": \"kubernetes\",\r\n      \"config\": {\r\n         \"inCluster\": true\r\n      }\r\n   },\r\n   \"frontend\": {\r\n      \"logoURL\": \"https:\/\/PUB-IP:32222\/dex\/\",\r\n      \"extra\": {\r\n         \"dkubeUrl\": \"https:\/\/PUB-IP:32222\/dex\/theme\/logo.png\",\r\n         \"favUrl\": \"https:\/\/PUB-IP:32222\/dex\/theme\/favicon.png\",\r\n         \"mainCss\": \"https:\/\/PUB-IP:32222\/dex\/static\/main.css\",\r\n         \"styleCss\": \"https:\/\/PUB-IP:32222\/dex\/theme\/styles.css\"\r\n      }\r\n   },\r\n   \"web\": {\r\n      \"http\": \"0.0.0.0:5556\"\r\n   },\r\n   \"telemetry\": {\r\n      \"http\": \"0.0.0.0:5558\"\r\n   },\r\n   \"expiry\": {\r\n      \"idTokens\": \"72h\"\r\n   },\r\n   \"staticClients\": [\r\n      {\r\n         \"id\": \"dkube\",\r\n         \"redirectURIs\": [\r\n            \"https:\/\/PUB-IP:32222\/callback\"\r\n         ],\r\n         \"name\": \"Dkube App\",\r\n         \"secret\": \"dkube-secret\"\r\n      },\r\n      {\r\n         \"id\": \"kubeflow-authservice-oidc\",\r\n         \"redirectURIs\": [\r\n            \"https:\/\/PUB-IP:31390\/login\/oidc\"\r\n         ],\r\n         \"name\": \"Kubeflow App\",\r\n         \"secret\": \"QKQ2ZN6SDavgTBR8JnVpy2a1beiWnLiO\"\r\n      }\r\n   ],\r\n   \"oauth2\": {\r\n      \"skipApprovalScreen\": true\r\n   },\r\n   \"connectors\": [\r\n      {\r\n         \"type\": \"github\",\r\n         \"id\": \"github\",\r\n         \"name\": \"GitHub\",\r\n         \"config\": {\r\n            \"clientID\": \"GIT-ID\",\r\n            \"clientSecret\": \"GIT-SECRET\",\r\n            \"redirectURI\": \"http:\/\/PUB-IP:31534\/dex\/callback\",\r\n            \"orgs\": [\r\n               {\r\n                  \"name\": \"GIT-ORG\"\r\n               }\r\n            ],\r\n            \"loadAllGroups\": false,\r\n            \"useLoginAsID\": true\r\n         }\r\n      },\r\n      {\r\n         \"type\": \"ldap\",\r\n         \"id\": \"ad\",\r\n         \"name\": \"ActiveDirectory\",\r\n         \"config\": {\r\n            \"host\": \"AD-EP\",\r\n            \"insecureNoSSL\": true,\r\n            \"insecureSkipVerify\": true,\r\n            \"bindDN\": \"AD-BINDDN\",\r\n            \"bindPW\": \"$ADBINDPW\",\r\n            \"userSearch\": {\r\n               \"baseDN\": \"AD-BASEDN\",\r\n               \"filter\": \"AD-FILTER\",\r\n               \"username\": \"sAMAccountName\",\r\n               \"idAttr\": \"sAMAccountName\",\r\n               \"emailAttr\": \"sAMAccountName\",\r\n               \"nameAttr\": \"sAMAccountName\"\r\n            }\r\n         }\r\n      }\r\n   ],\r\n   \"enablePasswordDB\": true,\r\n   \"staticPasswords\": [\r\n      {\r\n         \"email\": \"L-UNAME\",\r\n         \"hash\": \"L-PASSWD\",\r\n         \"username\": \"L-UNAME\",\r\n         \"userID\": \"L-UNAME\"\r\n      }\r\n   ]\r\n}"
        },
        "kind": "ConfigMap",
        "metadata": {
            "name": "dex",
            "namespace": "dkube",
        }
    },
    filebeatCM()::  {
        "apiVersion": "v1",
        "data": {
            "filebeat.yml": "# To enable hints based autodiscover, remove `filebeat.config.inputs` configuration and uncomment this:\nfilebeat.autodiscover:\n  providers:\n    - type: kubernetes\n      templates:\n        - condition:\n           and:\n             - or:\n                 - equals:\n                      kubernetes.container.name: tensorflow\n                 - equals:\n                      kubernetes.container.name: datajob\n             - and:\n                 - equals:\n                     kubernetes.labels.logger: filebeat\n                 - equals:\n                     kubernetes.node.name: ${NODENAME}\n          config:\n            - type: docker\n              containers:\n                  path: \"DOCKERPATH\"\n                  ids:\n                   - \"${data.kubernetes.container.id}\"\n              fields:\n                 jobname: ${data.kubernetes.labels.jobname}\n                 tfrole: ${data.kubernetes.labels.tf-replica-type:SINGLETON}\n                 username: ${data.kubernetes.labels.username}\n                 tfindex: ${data.kubernetes.labels.tf-replica-index:0}\n              fields_under_root: true\n\nprocessors:\n  - drop_fields:\n       fields: [\"beat\", \"input\", \"prospector\", \"offset\", \"source\", \"labels\", \"host\", \"kubernetes\", \"pod\", \"container\", \"node\", \"tags\", \"@version\",\"log\",\"ecs\",\"agent\"]\n        \noutput.logstash:\n  hosts: [\"logstash.dkube:5044\"]"
        },
        "kind": "ConfigMap",
        "metadata": {
            "labels": {
                "k8s-app": "filebeat"
            },
            "name": "filebeat-config",
            "namespace": "dkube"
        }
    },
   logstashCM():: {
        "apiVersion": "v1",
        "data": {
            "logstash.conf": "input{\n  beats {\n   port =\u003e 5044\n  }\n}\n\nfilter {\n   mutate {\n     add_field =\u003e {\n        \"[@metadata][jobname]\"=\u003e \"%{[jobname]}\"\n        \"[@metadata][role]\"=\u003e \"%{[tfrole]}\"\n        \"[@metadata][index]\" =\u003e \"%{[tfindex]}\"\n        \"[@metadata][username]\" =\u003e \"%{[username]}\"\n      }\n   }\n}\n\noutput {\n    file{\n       path =\u003e \"/var/log/dkube/%{[@metadata][username]}/%{[@metadata][jobname]}/logs.txt\"\n       codec =\u003e line{format =\u003e \"%{@timestamp}  %{[@metadata][role]}-%{[@metadata][index]}  %{message}\"}\n     }\n}"
        },
        "kind": "ConfigMap",
        "metadata": {
            "labels": {
                "app": "logstash"
            },
            "name": "logstash-config",
            "namespace": "dkube"
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

