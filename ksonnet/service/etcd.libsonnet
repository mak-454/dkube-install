{
    all(params):: [
    {
	"apiVersion": "v1",
	    "kind": "Service",
	    "metadata": {
		"name": "dkube-etcd-server",
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
		    "app": "dkube-etcd-server"
		},
		"type": "ClusterIP"
	    }
    }
    ],
}
