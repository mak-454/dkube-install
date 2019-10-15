{
    all(params):: [
        $.parts(params.namespace).splunksvc(),
    ],

    parts(namespace):: {
        splunksvc():: {
            "apiVersion": "v1",
            "kind": "Service",
            "metadata": {
                "annotations": {
                    "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube-splunk\nprefix: /splunk\nrewrite: /\ntimeout_ms: 600000\nservice: dkube-splunk.dkube:8000"
                },
                "labels": {
                    "app": "splunk",
                    "role": "splunk_cluster_master",
                    "tier": "management"
                },
                "name": "dkube-splunk",
                "namespace": "dkube",
            },
            "spec": {
                "ports": [
                {
                    "name": "hec",
                    "port": 8088,
                    "protocol": "TCP",
                    "targetPort": 8088
                },
                {
                    "name": "splunkweb",
                    "port": 8000,
                    "protocol": "TCP",
                    "targetPort": 8000
                },
                {
                    "name": "splunkd",
                    "port": 8089,
                    "protocol": "TCP",
                    "targetPort": 8089
                }
                ],
                "selector": {
                    "app": "splunk",
                    "role": "splunk_cluster_master",
                    "tier": "management"
                },
                "type": "ClusterIP"
            }
        }
    }
}
