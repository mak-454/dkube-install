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
                   "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_ext\nuse_websocket: true\nprefix: /dkube/v2/ext\nrewrite: /dkube/v2\ntimeout_ms: 0\nservice: dkube-ext:9401\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\"",
                    "prometheus.io/port": "9401",
                    "prometheus.io/scrape": "true"
                },
                "labels": {
                    "app": "dkube-gpu-exporter"
                },
                "name": "dkube-ext",
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
                    "app": "dkube-ext"
                },
                "type": "ClusterIP"
            }
        }
    },
}
