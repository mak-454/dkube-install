{
    all(params):: [
        $.parts(params.namespace).dkubeInferenceService(),
        $.parts(params.namespace).dkubeDocsService(),
    ],
    parts(namespace):: {
        dkubeDocsService():: {
            "apiVersion": "v1",
            "kind": "Service",
            "metadata": {
                "annotations": {
                    "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_docs\nprefix: /docs\nrewrite: /docs\ntimeout_ms: 600000\nservice: dkube-docs:8888\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\""
                },
                "name": "dkube-docs",
                "namespace": namespace
            },
            "spec": {
                "ports": [
                    {
                        "name": "serve",
                        "port": 8888,
                        "protocol": "TCP",
                        "targetPort": 80
                    }
                ],
                "selector": {
                    "app": "dkube-tools"
                },
                "type": "ClusterIP"
            }
        },
        dkubeInferenceService():: {
            "apiVersion": "v1",
            "kind": "Service",
            "metadata": {
                "annotations": {
                    "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_webapp\nprefix: /inference\nrewrite: /inference\ntimeout_ms: 600000\nservice: dkube-serving:8000\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\"\n---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_webapp_predict\nprefix: /predict\nrewrite: /predict\ntimeout_ms: 600000\nservice: dkube-serving:8000\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\""
                },
                "name": "dkube-serving",
                "namespace": namespace
            },
            "spec": {
                "ports": [
                    {
                        "name": "serve",
                        "port": 8000,
                        "protocol": "TCP",
                        "targetPort": 8000
                    }
                ],
                "selector": {
                    "app": "dkube-tools"
                },
                "type": "ClusterIP"
            }

        }
    }
}
