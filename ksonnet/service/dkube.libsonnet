{
  all(params):: [
    $.parts(params.namespace).katibServiceMapping(),
    $.parts(params.namespace).grafanaServiceMapping(),
    $.parts(params.namespace).prometheusServiceMapping(),
    $.parts(params.namespace).dkubeServiceAccount(),
    $.parts(params.namespace).dkubeClusterRoleBinding(params.dkubeClusterRole),
    $.parts(params.namespace).dkubeService(params.dkubeApiServerAddr),
    $.parts(params.namespace).dkubeHeadlessService(params.dkubeApiServerAddr),
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
    } //service
  }, // parts
}

