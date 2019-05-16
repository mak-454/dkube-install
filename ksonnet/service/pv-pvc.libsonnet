{
  all(params)::
    $.parts(params.namespace, params.nfsServer).pv_pvcD3() +
    $.parts(params.namespace, params.nfsServer).pv_pvcD3Store() +
    $.parts(params.namespace, params.nfsServer).pv_pvcD3UserLogs(),

  parts(namespace, nfsServer):: {

    pv_pvcD3():: [
	{
		"apiVersion": "v1",
		"kind": "PersistentVolume",
		"metadata": {
			"name": "pv-d3"
		},
		"spec": {
			"accessModes": [
				"ReadWriteMany"
			],
			"capacity": {
				"storage": "20Gi"
			},
			"storageClassName": "",
			"claimRef": {
				"name": "pvc-d3",
				"namespace": namespace
			},
			"nfs": {
				"path": "/",
				"server": nfsServer
			},
			"persistentVolumeReclaimPolicy": "Retain"
		}
	},
	{
		"apiVersion": "v1",
		"kind": "PersistentVolumeClaim",
		"metadata": {
			"name": "pvc-d3",
			"namespace": namespace
		},
		"spec": {
			"accessModes": [
				"ReadWriteMany"
			],
			"resources": {
				"requests": {
					"storage": "20Gi"
				}
			},
			"storageClassName": "",
			"volumeName": "pv-d3"
		}
	}
	],
    pv_pvcD3Store():: [
	{
		"apiVersion": "v1",
		"kind": "PersistentVolume",
		"metadata": {
			"name": "pv-d3store"
		},
		"spec": {
			"accessModes": [
				"ReadWriteMany"
			],
			"capacity": {
				"storage": "20Gi"
			},
			"storageClassName": "",
			"claimRef": {
				"name": "pvc-d3store",
				"namespace": namespace
			},
			"nfs": {
				"path": "/dkube",
				"server": nfsServer
			},
			"persistentVolumeReclaimPolicy": "Retain"
		}
	},
	{
		"apiVersion": "v1",
		"kind": "PersistentVolumeClaim",
		"metadata": {
			"name": "pvc-d3store",
			"namespace": namespace
		},
		"spec": {
			"accessModes": [
				"ReadWriteMany"
			],
			"resources": {
				"requests": {
					"storage": "20Gi"
				}
			},
			"storageClassName": "",
			"volumeName": "pv-d3store"
		}
	}
	],
    pv_pvcD3UserLogs():: [
	{
		"apiVersion": "v1",
		"kind": "PersistentVolume",
		"metadata": {
			"name": "pv-d3user-logs"
		},
		"spec": {
			"accessModes": [
				"ReadWriteMany"
			],
			"capacity": {
				"storage": "20Gi"
			},
			"storageClassName": "",
			"claimRef": {
				"name": "pvc-d3user-logs",
				"namespace": namespace
			},
			"nfs": {
				"path": "/logs",
				"server": nfsServer
			},
			"persistentVolumeReclaimPolicy": "Retain"
		}
	},
	{
		"apiVersion": "v1",
		"kind": "PersistentVolumeClaim",
		"metadata": {
			"name": "pvc-d3user-logs",
			"namespace": namespace
		},
		"spec": {
			"accessModes": [
				"ReadWriteMany"
			],
			"resources": {
				"requests": {
					"storage": "20Gi"
				}
			},
			"storageClassName": "",
			"volumeName": "pv-d3userlogs"
		}
	}
	]
  }
}
