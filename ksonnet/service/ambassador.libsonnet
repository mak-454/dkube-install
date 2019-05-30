{
  all(params):: [
    $.parts(params.namespace).service(params.ambassadorNodeport),
    $.parts(params.namespace).adminsvc,
    $.parts(params.namespace).clusterrole,
    $.parts(params.namespace).svcaccount,
    $.parts(params.namespace).clusterrolebinding,
    $.parts(params.namespace).authsvcCRD,
    $.parts(params.namespace).mappingCRD,
    $.parts(params.namespace).modulesCRD,
    $.parts(params.namespace).ratelimitCRD,
    $.parts(params.namespace).tcpCRD,
    $.parts(params.namespace).tlsCRD,
    $.parts(params.namespace).tracingCRD,
  ],

  parts(namespace):: {
    service(nodePort):: {
      apiVersion: "v1",
      kind: "Service",
      metadata: {
        annotations: {
            "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind: Module\nname: tls\nconfig:\n  server:\n    enabled: True\n    secret: dkube-certificate-secret\n"
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
            targetPort: 8443,
          },
        ],
        selector: {
          service: "ambassador",
        },
        type: "NodePort",
      },
    },  // service

    adminsvc:: {
   "apiVersion": "v1",
   "kind": "Service",
   "metadata": {
      "labels": {
         "service": "ambassador-admin"
      },
      "name": "ambassador-admin",
      "namespace": namespace
   },
   "spec": {
      "type": "NodePort",
      "ports": [
         {
            "name": "ambassador-admin",
            "port": 8877,
            "targetPort": 8877
         }
      ],
      "selector": {
         "service": "ambassador"
      }
   }
    }, //adminsvc

    clusterrole:: {
   "apiVersion": "rbac.authorization.k8s.io/v1beta1",
   "kind": "ClusterRole",
   "metadata": {
      "name": "ambassador"
   },
   "rules": [
      {
         "apiGroups": [
            ""
         ],
         "resources": [
            "endpoints",
            "namespaces",
            "secrets",
            "services"
         ],
         "verbs": [
            "get",
            "list",
            "watch"
         ]
      },
      {
         "apiGroups": [
            "getambassador.io"
         ],
         "resources": [
            "*"
         ],
         "verbs": [
            "get",
            "list",
            "watch"
         ]
      },
      {
         "apiGroups": [
            "apiextensions.k8s.io"
         ],
         "resources": [
            "customresourcedefinitions"
         ],
         "verbs": [
            "get",
            "list",
            "watch"
         ]
      }
   ]
    },

    svcaccount:: {
   "apiVersion": "v1",
   "kind": "ServiceAccount",
   "metadata": {
      "name": "ambassador",
      "namespace": namespace
   }
    }, //svcaccount

    clusterrolebinding:: {
   "apiVersion": "rbac.authorization.k8s.io/v1beta1",
   "kind": "ClusterRoleBinding",
   "metadata": {
      "name": "ambassador",
      "namespace": namespace
   },
   "roleRef": {
      "apiGroup": "rbac.authorization.k8s.io",
      "kind": "ClusterRole",
      "name": "ambassador"
   },
   "subjects": [
      {
         "kind": "ServiceAccount",
         "name": "ambassador",
         "namespace": "dkube"
      }
   ]
    }, //clusterrolebinding

    authsvcCRD:: {
   "apiVersion": "apiextensions.k8s.io/v1beta1",
   "kind": "CustomResourceDefinition",
   "metadata": {
      "name": "authservices.getambassador.io",
      "namespace": namespace
   },
   "spec": {
      "group": "getambassador.io",
      "version": "v1",
      "versions": [
         {
            "name": "v1",
            "served": true,
            "storage": true
         }
      ],
      "scope": "Namespaced",
      "names": {
         "plural": "authservices",
         "singular": "authservice",
         "kind": "AuthService"
      }
   }
    }, //authsvcCRD

    mappingCRD:: {
   "apiVersion": "apiextensions.k8s.io/v1beta1",
   "kind": "CustomResourceDefinition",
   "metadata": {
      "name": "mappings.getambassador.io",
      "namespace": namespace
   },
   "spec": {
      "group": "getambassador.io",
      "version": "v1",
      "versions": [
         {
            "name": "v1",
            "served": true,
            "storage": true
         }
      ],
      "scope": "Namespaced",
      "names": {
         "plural": "mappings",
         "singular": "mapping",
         "kind": "Mapping"
      }
   }
    }, //mappingCRD

    modulesCRD:: {
   "apiVersion": "apiextensions.k8s.io/v1beta1",
   "kind": "CustomResourceDefinition",
   "metadata": {
      "name": "modules.getambassador.io",
      "namespace": namespace
   },
   "spec": {
      "group": "getambassador.io",
      "version": "v1",
      "versions": [
         {
            "name": "v1",
            "served": true,
            "storage": true
         }
      ],
      "scope": "Namespaced",
      "names": {
         "plural": "modules",
         "singular": "module",
         "kind": "Module"
      }
   }
    }, //modulesCRD

    ratelimitCRD:: {
   "apiVersion": "apiextensions.k8s.io/v1beta1",
   "kind": "CustomResourceDefinition",
   "metadata": {
      "name": "ratelimitservices.getambassador.io",
      "namespace": namespace
   },
   "spec": {
      "group": "getambassador.io",
      "version": "v1",
      "versions": [
         {
            "name": "v1",
            "served": true,
            "storage": true
         }
      ],
      "scope": "Namespaced",
      "names": {
         "plural": "ratelimitservices",
         "singular": "ratelimitservice",
         "kind": "RateLimitService"
      }
   }
    }, //ratelimitCRD

    tcpCRD:: {
   "apiVersion": "apiextensions.k8s.io/v1beta1",
   "kind": "CustomResourceDefinition",
   "metadata": {
      "name": "tcpmappings.getambassador.io",
      "namespace": namespace
   },
   "spec": {
      "group": "getambassador.io",
      "version": "v1",
      "versions": [
         {
            "name": "v1",
            "served": true,
            "storage": true
         }
      ],
      "scope": "Namespaced",
      "names": {
         "plural": "tcpmappings",
         "singular": "tcpmapping",
         "kind": "TCPMapping"
      }
   }
    }, //tcpCRD

    tlsCRD:: {
   "apiVersion": "apiextensions.k8s.io/v1beta1",
   "kind": "CustomResourceDefinition",
   "metadata": {
      "name": "tlscontexts.getambassador.io",
      "namespace": namespace
   },
   "spec": {
      "group": "getambassador.io",
      "version": "v1",
      "versions": [
         {
            "name": "v1",
            "served": true,
            "storage": true
         }
      ],
      "scope": "Namespaced",
      "names": {
         "plural": "tlscontexts",
         "singular": "tlscontext",
         "kind": "TLSContext"
      }
   }
    }, //tlsCRD

    tracingCRD:: {
   "apiVersion": "apiextensions.k8s.io/v1beta1",
   "kind": "CustomResourceDefinition",
   "metadata": {
      "name": "tracingservices.getambassador.io",
      "namespace": namespace
   },
   "spec": {
      "group": "getambassador.io",
      "version": "v1",
      "versions": [
         {
            "name": "v1",
            "served": true,
            "storage": true
         }
      ],
      "scope": "Namespaced",
      "names": {
         "plural": "tracingservices",
         "singular": "tracingservice",
         "kind": "TracingService"
      }
   }
    }, //tracingCRD
  },  // parts
}
