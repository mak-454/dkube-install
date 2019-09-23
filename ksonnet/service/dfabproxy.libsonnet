{
    all(params):: [
        $.parts(params.namespace).service(),
    ],

    parts(namespace):: {
        service():: {
            "apiVersion": "v1",
            "kind": "Service",
            "metadata": {
                "annotations": {
                    "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dfabproxy\nuse_websocket: true\ntimeout_ms: 600000\nprefix: /dkube/v2/operator\nrewrite: /dkube/v2/operator\nservice: dfabproxy:8000"
                },
                "name": "dkube-operator-api-proxy",
                "namespace": "dkube",
            },
            "spec": {
                "ports": [
                {
                    "name": "dfabproxy",
                    "port": 8000,
                    "protocol": "TCP",
                    "targetPort": 8000
                }
                ],
                "selector": {
                    "app": "dkube-operator-proxy"
                },
                "sessionAffinity": "None",
                "type": "ClusterIP"
            },
        }
    }
}
