{
  all(params):: [
    $.parts(params.namespace).service(params.ambassadorNodeport),
    $.parts(params.namespace).adminService,
    $.parts(params.namespace).role,
    $.parts(params.namespace).serviceAccount,
    $.parts(params.namespace).roleBinding,
    $.parts(params.namespace).deploy,
  ],

  parts(namespace):: {
    local ambassadorImage = "quay.io/datawire/ambassador:0.30.1",
    service(nodePort):: {
      apiVersion: "v1",
      kind: "Service",
      metadata: {
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
            port: 80,
            nodePort: nodePort,
            targetPort: 80,
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
    },  // roleBinding

    deploy:: {
      apiVersion: "extensions/v1beta1",
      kind: "Deployment",
      metadata: {
        name: "ambassador",
        namespace: namespace,
      },
      spec: {
        replicas: 1,
        template: {
          metadata: {
            labels: {
              service: "ambassador",
            },
            namespace: namespace,
          },
          spec: {
            containers: [
              {
                env: [
                  {
                    name: "AMBASSADOR_NAMESPACE",
                    valueFrom: {
                      fieldRef: {
                        fieldPath: "metadata.namespace",
                      },
                    },
                  },
                  {
                    name: "AMBASSADOR_SINGLE_NAMESPACE",
                    value: "false",
                  },
                ],
                image: ambassadorImage,
                livenessProbe: {
                  httpGet: {
                    path: "/ambassador/v0/check_alive",
                    port: 8877,
                  },
                  initialDelaySeconds: 30,
                  periodSeconds: 30,
                },
                name: "ambassador",
                readinessProbe: {
                  httpGet: {
                    path: "/ambassador/v0/check_ready",
                    port: 8877,
                  },
                  initialDelaySeconds: 30,
                  periodSeconds: 30,
                },
                resources: {
                  limits: {
                    cpu: 1,
                    memory: "400Mi",
                  },
                  requests: {
                    cpu: "200m",
                    memory: "100Mi",
                  },
                },
              },
              //{
              //  image: "quay.io/datawire/statsd:0.30.1",
              //  name: "statsd",
              //},
            ],
            restartPolicy: "Always",
            serviceAccountName: "ambassador",
          },
        },
      },
    },  // deploy
  },  // parts
}
