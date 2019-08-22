{
    all(params):: [
        $.parts(params.namespace).dkubeInferenceService(),
        $.parts(params.namespace).dkubeDocsService(),
        $.parts(params.namespace).dkubeInstallerService(),
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
                "namespace": "dkube"
            },
            "spec": {
                "ports": [
                    {
                        "name": "serve",
                        "port": 8888,
                        "protocol": "TCP",
                        "targetPort": 8888
                    }
                ],
                "selector": {
                    "app": "docs"
                },
                "type": "ClusterIP"
            }
        },
        dkubeInferenceService():: {
            "apiVersion": "v1",
            "kind": "Service",
            "metadata": {
                "annotations": {
                    "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_webapp\nprefix: /inference\nrewrite: /inference\ntimeout_ms: 600000\nservice: dkube-inference:8000\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\"\n---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_webapp_predict\nprefix: /predict\nrewrite: /predict\ntimeout_ms: 600000\nservice: dkube-inference:8000\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\""
                },
                "name": "dkube-inference",
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
                    "app": "inference"
                },
                "type": "ClusterIP"
            }

        },
    dkubeInstallerService()::{
        "apiVersion": "v1",
        "kind": "Service",
        "metadata": {
            "annotations": {
                "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_installer\nprefix: /installer\nrewrite: /ui\ntimeout_ms: 600000\nservice: dkube-installer-service.kube-system:8888\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\"\n---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_installer_report\nprefix: /report\nrewrite: /report\ntimeout_ms: 600000\nservice: dkube-installer-service.kube-system:8888\ncors:\n origins: \"*\"\n methods: \"*\"\n headers: \"*\""
            },
            "name": "installer-mapping-service",
            "namespace": "dkube"
        },
        "spec": {
            "ports": [
                {
                    "name": "serve",
                    "port": 8888,
                    "protocol": "TCP",
                    "targetPort": 8888
                }
            ],
            "selector": {
                "role": "dkube-installer"
            },
            "type": "ClusterIP"
        }
        }
    }
}



