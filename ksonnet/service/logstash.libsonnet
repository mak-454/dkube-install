{
  all(params):: [
    $.parts(params.namespace).service(),
  ],

  parts(namespace):: {
    service():: {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "name": "dkube-log-mixer", 
        "namespace": "dkube"
      }, 
      "spec": {
        "ports": [
          {
            "port": 5044, 
            "protocol": "TCP", 
            "targetPort": 5044
          }
        ], 
        "selector": {
          "app": "dkube-log-mixer"
        }, 
        "type": "ClusterIP"
      }
    }
  },
}
