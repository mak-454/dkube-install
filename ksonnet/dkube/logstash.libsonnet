{
  all(params):: [
    $.parts(params.namespace).service(),
    $.parts(params.namespace).deploy(params.logstashImage,),
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
    },
    deploy(logstashImage):: {
      "apiVersion": "apps/v1", 
      "kind": "Deployment", 
      "metadata": {
        "name": "logstash", 
        "namespace": "dkube"
      }, 
      "spec": {
        "replicas": 1, 
        "selector": {
          "matchLabels": {
            "app": "logstash"
          }
        }, 
        "template": {
          "metadata": {
            "labels": {
              "app": "logstash"
            }
          }, 
          "spec": {
            "containers": [
              {
                "command": [
                  "/logstash"
                ], 
                "image": logstashImage, 
                "imagePullPolicy": "IfNotPresent", 
                "name": "logstash"
              }
            ]
          }
        }
      }
    }
  }
}