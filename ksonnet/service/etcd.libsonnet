{
    all(params):: [
    {
      "kind": "PersistentVolumeClaim",
      "apiVersion": "v1",
      "metadata": {
        "name": "dkube-db-pvc",
        "namespace": "dkube",
        },
      "spec": {
        "accessModes": [
          "ReadWriteMany"
        ],
        "storageClassName": "",
        "resources": {
          "requests": {
            "storage": "50Gi"
          }
        },
        "volumeName": "dkube-db-pv"
      }
    },
    {
	"apiVersion": "v1",
	    "kind": "Service",
        "metadata": {
            "name": "dkube-db-server",
            "namespace": "dkube"
	    },
	    "spec": {
		"ports": [
		{
		    "port": 2379,
		    "protocol": "TCP",
		    "targetPort": 2379
		}
		],
		"selector": {
		    "app": "dkube-db-server"
		},
		"type": "ClusterIP"
	    }
    }
    ],
}
