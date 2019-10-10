{
    all(params):: [
        $.parts(params.namespace).service(),
    ],
    parts(namespace):: {
        service()::	{
            "apiVersion": "v1",
            "kind": "Service",
            "metadata": {
                "labels": {
                    "app": "dkube-storage-exporter"
                },
                "name": "dkube-storage-exporter",
                "namespace": "dkube"
            },
            "spec": {
                "ports": [
                {
                    "name": "http-metrics",
                    "port": 9401,
                    "protocol": "TCP",
                    "targetPort": 9401
                }
                ],
                "selector": {
                    "app": "dkube-storage-exporter"
                },
                "type": "ClusterIP"
            }
        }
    },
}
