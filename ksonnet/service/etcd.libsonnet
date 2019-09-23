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
        "volumeName": "d3etcd"
      }
    },
    {
	"apiVersion": "v1",
	    "kind": "Service",
        "metadata": {
            "annotations": {
                "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_etcd\nprefix: /dkube/v2/etcd/\nrewrite: /\ntimeout_ms: 600000\nservice: dkube-etcd-server:2379"
            },
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
