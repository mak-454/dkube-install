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
          "apiVersion": "v1",
          "kind": "Service",
          "metadata": {
              "annotations": {
                  "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind: Module\nname: tls\nconfig:\n  server:\n    enabled: True\n    secret: dkube-certificate-secret\n    alpn_protocols: h2\n---\napiVersion: ambassador/v1\nkind:  AuthService\nname:  d3-auth\nauth_service: dkube-auth-server:3001\nallowed_request_headers:\n- \"mode\"\nallowed_authorization_headers:\n- \"d3-privilege\"\n- \"d3-uname\"\n- \"d3-role\"\n",
              },
              "labels": {
                  "service": "dkube-proxy"
              },
              "name": "dkube-proxy",
              "namespace": "dkube",
          },
          "spec": {
              "externalTrafficPolicy": "Cluster",
              "ports": [
              {
                  "name": "ambassador",
                  "nodePort": nodePort,
                  "port": 443,
                  "protocol": "TCP",
                  "targetPort": 443
              }
              ],
              "selector": {
                  "service": "dkube-proxy"
              },
              "type": "NodePort"
          },
      },  // service

    adminService:: {
      apiVersion: "v1",
      kind: "Service",
      metadata: {
        labels: {
          service: "dkube-proxy-admin",
        },
        name: "dkube-proxy-admin",
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
          service: "dkube-proxy",
        },
        type: "NodePort",
      },
    },  // adminService

    role:: {
      apiVersion: "rbac.authorization.k8s.io/v1beta1",
      kind: "Role",
      metadata: {
        name: "dkube-proxy",
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
        name: "dkube-proxy",
        namespace: namespace,
      },
    },  // serviceAccount

    roleBinding:: {
      apiVersion: "rbac.authorization.k8s.io/v1beta1",
      kind: "RoleBinding",
      metadata: {
        name: "dkube-proxy",
        namespace: namespace,
      },
      roleRef: {
        apiGroup: "rbac.authorization.k8s.io",
        kind: "Role",
        name: "dkube-proxy",
      },
      subjects: [
        {
          kind: "ServiceAccount",
          name: "dkube-proxy",
          namespace: namespace,
        },
      ],
    }  // roleBinding
  },  // parts
}
