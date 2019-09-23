{
    all(params):: [
        $.parts(params.namespace).service(),
    ],
    parts(namespace):: {
        service()::	{
            "apiVersion": "v1",
            "kind": "Service",
            "metadata": {
                "annotations": {
                   "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_downloader\nuse_websocket: true\nprefix: /dkube/v2/ext\nrewrite: /dkube/v2\ntimeout_ms: 0\nservice: dkube-d3downloader:9401\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\""
                },
                "name": "dkube-downloader",
                "namespace": "dkube"
            },
            "spec": {
                "ports": [
                {
                    "port": 9401,
                    "protocol": "TCP",
                    "targetPort": 9401
                }
                ],
                "selector": {
                    "app": "dkube-controller-worker"
                },
                "type": "ClusterIP"
            }
        }
    },
}
