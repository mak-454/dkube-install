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
    },
    {
	"kind": "PersistentVolumeClaim",
	"apiVersion": "v1",
	"metadata": {
	    "name": "etcd-pvc",
	    "namespace": "dkube"
	},
	"spec": {
	    "accessModes": [
		"ReadWriteMany"
	    ],
	    "storageClassName": params.storageClass,
	    "resources": {
		"requests": {
		    "storage": "100Gi"
		}
	    },
	    [if params.storageClass=="" then "volumeName"]: params.etcdStoragePV
	}
    }

    ],
}
