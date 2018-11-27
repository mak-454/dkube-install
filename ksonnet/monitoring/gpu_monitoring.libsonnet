{
  all(params):: [

    {
      "apiVersion": "extensions/v1beta1", 
      "kind": "Deployment", 
      "metadata": {
        "annotations": null, 
        "labels": {
          "app": "dkube-prometheus-grafana", 
          "chart": "grafana-0.0.37", 
          "heritage": "Tiller", 
          "release": "kube-prometheus"
        }, 
        "name": "dkube-grafana", 
        "namespace": "monitoring"
      }, 
      "spec": {
        "progressDeadlineSeconds": 600, 
        "replicas": 1, 
        "revisionHistoryLimit": 10, 
        "selector": {
          "matchLabels": {
            "app": "dkube-prometheus-grafana"
          }
        }, 
        "strategy": {
          "rollingUpdate": {
            "maxSurge": 1, 
            "maxUnavailable": 1
          }, 
          "type": "RollingUpdate"
        }, 
        "template": {
          "metadata": {
            "creationTimestamp": null, 
            "labels": {
              "app": "dkube-prometheus-grafana", 
              "release": "kube-prometheus"
            }
          }, 
          "spec": {
            "containers": [
              {
                "env": [
                  {
                    "name": "GF_AUTH_BASIC_ENABLED", 
                    "value": "true"
                  }, 
                  {
                    "name": "GF_AUTH_ANONYMOUS_ENABLED", 
                    "value": "true"
                  }, 
                  {
                    "name": "GF_SECURITY_ADMIN_USER", 
                    "valueFrom": {
                      "secretKeyRef": {
                        "key": "user", 
                        "name": "kube-prometheus-grafana"
                      }
                    }
                  }, 
                  {
                    "name": "GF_SECURITY_ADMIN_PASSWORD", 
                    "valueFrom": {
                      "secretKeyRef": {
                        "key": "password", 
                        "name": "kube-prometheus-grafana"
                      }
                    }
                  }
                ], 
                "image": "grafana/grafana:5.0.0", 
                "imagePullPolicy": "IfNotPresent", 
                "name": "grafana", 
                "ports": [
                  {
                    "containerPort": 3000, 
                    "name": "web", 
                    "protocol": "TCP"
                  }
                ], 
                "readinessProbe": {
                  "failureThreshold": 10, 
                  "httpGet": {
                    "path": "/api/health", 
                    "port": 3000, 
                    "scheme": "HTTP"
                  }, 
                  "periodSeconds": 1, 
                  "successThreshold": 1, 
                  "timeoutSeconds": 1
                }, 
                "resources": {}, 
                "terminationMessagePath": "/dev/termination-log", 
                "terminationMessagePolicy": "File", 
                "volumeMounts": [
                  {
                    "mountPath": "/var/lib/grafana", 
                    "name": "grafana-storage"
                  }, 
                  {
                    "mountPath": "/etc/grafana/grafana.ini", 
                    "name": "grafana-config", 
                    "subPath": "grafana.ini"
                  }
                ]
              }, 
              {
                "args": [
                  "--watch-dir=/var/grafana-dashboards", 
                  "--grafana-url=http://127.0.0.1:3000"
                ], 
                "env": [
                  {
                    "name": "GRAFANA_USER", 
                    "valueFrom": {
                      "secretKeyRef": {
                        "key": "user", 
                        "name": "kube-prometheus-grafana"
                      }
                    }
                  }, 
                  {
                    "name": "GRAFANA_PASSWORD", 
                    "valueFrom": {
                      "secretKeyRef": {
                        "key": "password", 
                        "name": "kube-prometheus-grafana"
                      }
                    }
                  }
                ], 
                "image": "quay.io/coreos/grafana-watcher:v0.0.8", 
                "imagePullPolicy": "IfNotPresent", 
                "name": "grafana-watcher", 
                "resources": {}, 
                "terminationMessagePath": "/dev/termination-log", 
                "terminationMessagePolicy": "File", 
                "volumeMounts": [
                  {
                    "mountPath": "/var/grafana-dashboards", 
                    "name": "grafana-dashboards"
                  }
                ]
              }
            ], 
            "dnsPolicy": "ClusterFirst", 
            "restartPolicy": "Always", 
            "schedulerName": "default-scheduler", 
            "securityContext": {}, 
            "serviceAccount": "kube-prometheus-grafana", 
            "serviceAccountName": "kube-prometheus-grafana", 
            "terminationGracePeriodSeconds": 30, 
            "volumes": [
              {
                "emptyDir": {}, 
                "name": "grafana-storage"
              }, 
              {
                "configMap": {
                  "defaultMode": 420, 
                  "name": "dkube-grafana-dashboard"
                }, 
                "name": "grafana-dashboards"
              }, 
              {
                "configMap": {
                  "defaultMode": 420, 
                  "name": "dkube-grafana-init"
                }, 
                "name": "grafana-config"
              }
            ]
          }
        }
      }
    },
    {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "annotations": {
          "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_monitoring\nprefix: /dkube/grafana/\nrewrite: /\nservice: dkube-grafana.monitoring:80\ntimeout_ms: 60000\nuse_websocket: true"
        }, 
        "labels": {
          "app": "dkube-prometheus-grafana"
        }, 
        "name": "dkube-prometheus-grafana-proxy", 
        "namespace": "dkube"
      }, 
      "spec": {
        "externalTrafficPolicy": "Cluster", 
        "ports": [
          {
            "name": "http", 
            "nodePort": 31227, 
            "port": 80, 
            "protocol": "TCP", 
            "targetPort": 3000
          }
        ], 
        "selector": {
          "app": "dkube-prometheus-grafana"
        }, 
        "sessionAffinity": "None", 
        "type": "NodePort"
      }
    },
    {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "annotations": null, 
        "labels": {
          "app": "dkube-prometheus-grafana"
        }, 
        "name": "dkube-grafana", 
        "namespace": "monitoring"
      }, 
      "spec": {
        "externalTrafficPolicy": "Cluster", 
        "ports": [
          {
            "name": "http", 
            "nodePort": 30990, 
            "port": 80, 
            "protocol": "TCP", 
            "targetPort": 3000
          }
        ], 
        "selector": {
          "app": "dkube-prometheus-grafana"
        }, 
        "sessionAffinity": "None", 
        "type": "NodePort"
      }
    },
    {
      "apiVersion": "monitoring.coreos.com/v1", 
      "kind": "ServiceMonitor", 
      "metadata": {
        "labels": {
          "app": "prometheus", 
          "prometheus": "kube-prometheus"
        }, 
        "name": "dkube-prometheus-exporter-gpu", 
        "namespace": "monitoring"
      }, 
      "spec": {
        "endpoints": [
          {
            "interval": "15s", 
            "port": "http-metrics"
          }
        ], 
        "jobLabel": "k8s-app", 
        "namespaceSelector": {
          "matchNames": [
            "monitoring"
          ]
        }, 
        "selector": {
          "matchLabels": {
            "app": "dkube-gpu-exporter"
          }
        }
      }
    },
	{
	  "apiVersion": "v1", 
	  "kind": "Service", 
	  "metadata": {
		"annotations": {
		  "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_ext\nuse_websocket: true\nprefix: /dkube/v2/ext\nrewrite: /dkube/v2\ntimeout_ms: 6000\nservice: dkube-ext.monitoring:9401"
		}, 
		"labels": {
		  "app": "dkube-ext"
		}, 
		"name": "dkube-ext", 
		"namespace": "dkube"
	  }, 
	  "spec": {
		"clusterIP": "None", 
		"type": "ClusterIP"
	  }
	},
	{
	  "apiVersion": "v1", 
	  "kind": "Service", 
	  "metadata": {
		"annotations": {
		  "prometheus.io/port": "9401", 
		  "prometheus.io/scrape": "true"
		}, 
		"labels": {
		  "app": "dkube-gpu-exporter"
		}, 
		"name": "dkube-ext", 
		"namespace": "monitoring"
	  }, 
	  "spec": {
		"ports": [
		  {
			"name": "http-metrics", 
			"nodePort": 30001, 
			"port": 9401, 
			"protocol": "TCP", 
			"targetPort": 9401
		  }
		], 
		"selector": {
		  "app": "dkube-ext"
		}, 
		"type": "ClusterIP"
	  }
	},
	{
	  "apiVersion": "extensions/v1beta1", 
	  "kind": "DaemonSet", 
	  "metadata": {
		"labels": {
		  "app": "dkube-ext"
		}, 
		"name": "dkube-ext", 
		"namespace": "monitoring"
	  }, 
	  "spec": {
		"selector": {
		  "matchLabels": {
			"app": "dkube-ext"
		  }
		}, 
		"template": {
		  "metadata": {
			"labels": {
			  "app": "dkube-ext"
			}
		  }, 
		  "spec": {
			"containers": [
			  {
				"env": [
				  {
					"name": "MYNODENAME", 
					"valueFrom": {
					  "fieldRef": {
						"apiVersion": "v1", 
						"fieldPath": "spec.nodeName"
					  }
					}
				  }
				], 
				"image": "ocdr/dkube-ext:alpha3", 
				"imagePullPolicy": "IfNotPresent", 
				"name": "dkube-ext", 
				"ports": [
				  {
					"containerPort": 9401, 
					"hostPort": 9401, 
					"name": "http-metrics", 
					"protocol": "TCP"
				  }
				], 
				"volumeMounts": [
				  {
					"mountPath": "/var/log/containerlogs", 
					"name": "logs"
				  }, 
				  {
					"mountPath": "/tmp/dkube/store", 
					"name": "dkube-data"
				  }
				]
			  }
			], 
			"imagePullSecrets": [
			  {
				"name": "dkube-dockerhub-secret"
			  }
			], 
			"volumes": [
			  {
				"flexVolume": {
				  "driver": "oc/d3", 
				  "options": {
					"accessKey": "dkube", 
					"bucket": "logs", 
					"endpoint": "http://10.96.0.22:9000", 
					"s3provider": "minio", 
					"secretKey": "dkube123"
				  }
				}, 
				"name": "logs"
			  }, 
			  {
				"flexVolume": {
				  "driver": "oc/d3", 
				  "options": {
					"accessKey": "dkube", 
					"bucket": "dkube", 
					"endpoint": "http://10.96.0.22:9000", 
					"s3provider": "minio", 
					"secretKey": "dkube123"
				  }
				}, 
				"name": "dkube-data"
			  }
			]
		  }
		}
	  }
	},
	{
	  "apiVersion": "v1", 
	  "kind": "Service", 
	  "metadata": {
		"annotations": {
		  "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  \"prometheus\"\nuse_websocket: true\nprefix: \"/dkube/v2/prometheus/api/v1\"\nrewrite: \"/api/v1\"\nservice: \"kube-prometheus.monitoring:9090\"\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\"\n---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  \"prometheus-alert-manager\"\nuse_websocket: true\nprefix: \"/dkube/v2/prometheus/alertmanager/api/v1\"\nrewrite: \"/api/v1\"\nservice: \"kube-prometheus-alertmanager.monitoring:9093\"\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\""
		}, 
		"name": "prometheus-maping-service", 
		"namespace": "dkube"
	  }, 
	  "spec": {
		"clusterIP": "None", 
		"sessionAffinity": "None", 
		"type": "ClusterIP"
	  }
	}
  ]
}

