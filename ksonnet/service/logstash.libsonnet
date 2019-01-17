{
  all(params):: [
    $.parts(params.namespace).service(),
  ],

  parts(namespace):: {
    service():: {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "name": "logstash", 
        "namespace": "dkube"
      }, 
      "spec": {
        "ports": [
          {
            "name": "logstash", 
            "port": 5044, 
            "protocol": "TCP", 
            "targetPort": 5044
          }
        ], 
        "selector": {
          "app": "logstash"
        }, 
        "type": "ClusterIP"
      }
    }
  },
}
