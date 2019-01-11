{
	all(params):: [
		$.parts(params.namespace).deploy(params.filebeatImage, params.dkubeDockerSecret),
	],

	parts(namespace):: {
		deploy(filebeatImage, dkubeDockerSecret):: {
			"apiVersion": "extensions/v1beta1",
			"kind": "DaemonSet",
			"metadata": {
				"labels": {
					"k8s-app": "filebeat-logging",
					"kubernetes.io/cluster-service": "true",
					"version": "v1"
				},
				"name": "filebeat",
				"namespace": "dkube",
			},
			"spec": {
				"revisionHistoryLimit": 10,
				"selector": {
					"matchLabels": {
						"k8s-app": "filebeat-logging",
						"kubernetes.io/cluster-service": "true",
						"version": "v1"
					}
				},
				"template": {
					"metadata": {
						"creationTimestamp": null,
						"labels": {
							"k8s-app": "filebeat-logging",
							"kubernetes.io/cluster-service": "true",
							"version": "v1"
						}
					},
					"spec": {
						"imagePullSecrets": [
						{
							"name": dkubeDockerSecret
						}
						],
						"containers": [
						{
							"command": [
								"bash",
							"-c",
							"while IFS='' read -r line || [[ -n \"$line\" ]]; \ndo\n  IFS='//' read -r -a array1 \u003c\u003c\u003c \"$line\";\n  a=\"/mnt/root\";\n  for i in ${!array1[@]};\n  do\n      if [ $i -ne 0 ];\n      then\n          a=\"$a/${array1[$i]}\";\n      fi;\n  done;\n  a=\"$a/containers\";\n  export DOCKERPATH=$a;\n  export NODENAME=${NODENAME}\n  sed -i -e 's@DOCKERPATH@'\"$DOCKERPATH\"'@' filebeat.yml;\n  sed -i -e 's@NODENAME@'\"$NODENAME\"'@' filebeat.yml;\ndone \u003c \"/tmp/dockerstorage/dockerpath.txt\";\nchown root:filebeat /usr/share/filebeat/filebeat.yml\n./filebeat -e;\n"
							],
							"env": [
							{
								"name": "NODENAME",
								"valueFrom": {
                                    "fieldRef": {
                                        "fieldPath": "spec.nodeName"
                                    }
                                }
							}
							],
							"image": filebeatImage,
							"imagePullPolicy": "IfNotPresent",
							"name": "filebeat",
							"resources": {},
							"terminationMessagePath": "/dev/termination-log",
							"terminationMessagePolicy": "File",
							"volumeMounts": [
							{
								"mountPath": "/mnt/root",
								"name": "varlibdockercontainers",
								"readOnly": true
							},
							{
								"mountPath": "/tmp/dockerstorage",
								"name": "tmp"
							}
							]
						}
						],
						"dnsPolicy": "ClusterFirst",
						"initContainers": [
						{
							"command": [
								"sh",
							"-c",
							"dockvol=$(docker info | grep Docker);\necho $dockvol \u003e /tmp/dockerstorage/dockerpath.txt;\n"
							],
							"image": "docker:18.09",
							"imagePullPolicy": "IfNotPresent",
							"name": "logpath",
							"resources": {},
							"terminationMessagePath": "/dev/termination-log",
							"terminationMessagePolicy": "File",
							"volumeMounts": [
							{
								"mountPath": "/tmp/dockerstorage",
								"name": "tmp"
							},
							{
								"mountPath": "/var/run/docker.sock",
								"name": "dockersock"
							}
							]
						}
						],
						"restartPolicy": "Always",
						"schedulerName": "default-scheduler",
						"serviceAccount": "dkube",
						"volumes": [
						{
							"hostPath": {
								"path": "/",
								"type": ""
							},
							"name": "varlibdockercontainers"
						},
						{
							"emptyDir": {},
							"name": "tmp"
						},
						{
							"hostPath": {
								"path": "/var/run/docker.sock",
								"type": ""
							},
							"name": "dockersock"
						}
						]
					}
				},
				"templateGeneration": 1,
				"updateStrategy": {
					"type": "OnDelete"
				}
			},
		}

	}
}
