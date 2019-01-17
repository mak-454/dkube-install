{
  all(params):: [
    $.parts(params.namespace).service(),
  ],

  parts(namespace):: {
    service():: {
      apiVersion: "v1",
      kind: "Service",
      metadata: {
        labels: {
          service: "dkube-ui",
        },
        "annotations": {
          "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_ui\nprefix: /dkube/ui\nrewrite: /dkube/ui\nservice: dkube-ui:3000\ntimeout_ms: 60000"
        },
        name: "dkube-ui",
        namespace: namespace,
      },
      spec: {
        ports: [
          {
            name: "ui",
            port: 3000,
            targetPort: 3000,
          },
        ],
        selector: {
          app: "dkube-ui",
        },
        type: "ClusterIP",
      },
    }  // service
  },  // parts
}
