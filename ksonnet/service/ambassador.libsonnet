{
  all(params):: [
    $.parts(params.namespace).service(params.ambassadorNodeport),
    $.parts(params.namespace).adminService,
    $.parts(params.namespace).role,
    $.parts(params.namespace).serviceAccount,
    $.parts(params.namespace).roleBinding,
  ],

  parts(namespace):: {
    service(nodePort):: {
      apiVersion: "v1",
      kind: "Service",
      metadata: {
        annotations: {
            "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind: Module\nname: tls\nconfig:\n  server:\n    enabled: True\n    secret: dkube-certificate-secret\n    alpn_protocols: h2\n---\napiVersion: ambassador/v1\nkind:  AuthService\nname:  authentication\nauth_service: \"dkube-auth:3000\"\n"
            "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind: Module\nname: tls\nconfig:\n  server:\n    enabled: True\n    secret: dkube-certificate-secret\n    alpn_protocols: h2\n"
        },
        labels: {
          service: "ambassador",
        },
        name: "ambassador",
        namespace: namespace,
      },
      spec: {
        ports: [
          {
            name: "ambassador",
            port: 443,
            nodePort: nodePort,
            targetPort: 443,
          },
        ],
        selector: {
          service: "ambassador",
        },
        type: "NodePort",
      },
    },  // service

    adminService:: {
      apiVersion: "v1",
      kind: "Service",
      metadata: {
        labels: {
          service: "ambassador-admin",
        },
        name: "ambassador-admin",
        namespace: namespace,
      },
      spec: {
        ports: [
          {
            name: "ambassador-admin",
            port: 8877,
            targetPort: 8877,
          },
        ],
        selector: {
          service: "ambassador",
        },
        type: "ClusterIP",
      },
    },  // adminService

    role:: {
      apiVersion: "rbac.authorization.k8s.io/v1beta1",
      kind: "Role",
      metadata: {
        name: "ambassador",
        namespace: namespace,
      },
      rules: [
        {
          apiGroups: [
            "",
          ],
          resources: [
            "services",
          ],
          verbs: [
            "get",
            "list",
            "watch",
          ],
        },
        {
          apiGroups: [
            "",
          ],
          resources: [
            "configmaps",
          ],
          verbs: [
            "create",
            "update",
            "patch",
            "get",
            "list",
            "watch",
          ],
        },
        {
          apiGroups: [
            "",
          ],
          resources: [
            "secrets",
          ],
          verbs: [
            "get",
            "list",
            "watch",
          ],
        },
      ],
    },  // role

    serviceAccount:: {
      apiVersion: "v1",
      kind: "ServiceAccount",
      metadata: {
        name: "ambassador",
        namespace: namespace,
      },
    },  // serviceAccount

    roleBinding:: {
      apiVersion: "rbac.authorization.k8s.io/v1beta1",
      kind: "RoleBinding",
      metadata: {
        name: "ambassador",
        namespace: namespace,
      },
      roleRef: {
        apiGroup: "rbac.authorization.k8s.io",
        kind: "Role",
        name: "ambassador",
      },
      subjects: [
        {
          kind: "ServiceAccount",
          name: "ambassador",
          namespace: namespace,
        },
      ],
    }  // roleBinding
  },  // parts
}
