{
  all(params):: [
   {
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
       "clusterIP": "None",
       "sessionAffinity": "None",
       "type": "ClusterIP"
     }
   },
   { 
     "apiVersion": "v1",
     "kind": "Service",
     "metadata": {
       "annotations": {
         "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  \"prometheus\"\ntimeout_ms: 600000\nuse_websocket: true\nprefix: \"/dkube/v2/prometheus/api/v1\"\nrewrite: \"/api/v1\"\nservice: \"https://prometheus-k8s.openshift-monitoring:9091\"\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\"\n---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  \"prometheus-alert-manager\"\ntimeout_ms: 600000\nuse_websocket: true\nprefix: \"/dkube/v2/prometheus/alertmanager/api/v1\"\nrewrite: \"/api/v1\"\nservice: \"kube-prometheus-alertmanager.monitoring:9093\"\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\"\nadd_request_headers:\n Authorization: Basic " + params.promBasicAuth
       },
       "name": "prometheus-mapping-service",
       "namespace": "dkube"
     },
     "spec": {
       "clusterIP": "None",
       "sessionAffinity": "None",
       "type": "ClusterIP"
     }
  	}]
}
