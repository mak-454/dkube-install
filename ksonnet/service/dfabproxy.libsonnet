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
                "name": "dfabproxy",
                "namespace": "dkube",
            },
            "spec": {
                "clusterIP": "10.108.1.159",
                "ports": [
                {
                    "name": "dfabproxy",
                    "port": 8000,
                    "protocol": "TCP",
                    "targetPort": 8000
                }
                ],
                "selector": {
                    "app": "dfabproxy"
                },
                "sessionAffinity": "None",
                "type": "ClusterIP"
            },
        }
    }
}
