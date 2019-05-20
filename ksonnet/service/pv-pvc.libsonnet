{
  all(params)::
    $.parts(params.namespace, params.nfsServer).pv_pvc_dkube_system_db() +
    $.parts(params.namespace, params.nfsServer).pv_pvc_dkube_system_logs(),

  parts(namespace, nfsServer):: {

    pv_pvc_dkube_system_db():: [
	{
		"apiVersion": "v1",
		"kind": "PersistentVolume",
		"metadata": {
			"name": "pv-dkube-system-db",
			"labels": {
				"scope": "dkube"
			}
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
				"name": "pvc-dkube-system-db",
				"namespace": namespace
			},
			"nfs": {
				"path": "/dkube-system/db",
				"server": nfsServer
			},
			"persistentVolumeReclaimPolicy": "Retain"
		}
	},
	{
		"apiVersion": "v1",
		"kind": "PersistentVolumeClaim",
		"metadata": {
			"name": "pvc-dkube-system-db",
			"namespace": namespace,
			"labels": {
				"scope": "dkube"
			}
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
			"volumeName": "pv-dkube-system-db"
		}
	}
	],
    pv_pvc_dkube_system_logs():: [
	{
		"apiVersion": "v1",
		"kind": "PersistentVolume",
		"metadata": {
			"name": "pv-dkube-system-logs",
			"labels": {
				"scope": "dkube"
			}
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
				"name": "pvc-dkube-system-logs",
				"namespace": namespace
			},
			"nfs": {
				"path": "/dkube-system/logs",
				"server": nfsServer
			},
			"persistentVolumeReclaimPolicy": "Retain"
		}
	},
	{
		"apiVersion": "v1",
		"kind": "PersistentVolumeClaim",
		"metadata": {
			"name": "pvc-dkube-system-logs",
			"namespace": namespace,
            "labels": {
                "scope": "dkube"
            }
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
			"volumeName": "pv-dkube-system-logs"
		}
	}
	]
  }
}
