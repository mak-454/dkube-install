{
  all(params):: [

    {
      "apiVersion": "apiextensions.k8s.io/v1beta1",
      "kind": "CustomResourceDefinition",
      "metadata": {
        "name": "workflows.argoproj.io"
      },
      "spec": {
        "group": "argoproj.io",
        "names": {
          "kind": "Workflow",
          "plural": "workflows",
          "shortNames": [
            "wf"
          ]
        },
        "scope": "Namespaced",
        "version": "v1alpha1"
      }
    },
    {
      "apiVersion": "v1",
      "kind": "ConfigMap",
      "metadata": {
        "name": "workflow-controller-configmap",
        "namespace": "dkube"
      }
    },
    
    {
      "apiVersion": "v1",
      "kind": "ServiceAccount",
      "metadata": {
        "name": "argo",
        "namespace": "dkube"
      }
    },
    
    {
      "apiVersion": "rbac.authorization.k8s.io/v1",
      "kind": "ClusterRole",
      "metadata": {
        "name": "argo-cluster-role"
      },
      "rules": [
        {
          "apiGroups": [
            ""
          ],
          "resources": [
            "pods",
            "pods/exec"
          ],
          "verbs": [
            "create",
            "get",
            "list",
            "watch",
            "update",
            "patch",
            "delete"
          ]
        },
        {
          "apiGroups": [
            ""
          ],
          "resources": [
            "configmaps"
          ],
          "verbs": [
            "get",
            "watch",
            "list"
          ]
        },
        {
          "apiGroups": [
            ""
          ],
          "resources": [
            "persistentvolumeclaims"
          ],
          "verbs": [
            "create",
            "delete"
          ]
        },
        {
          "apiGroups": [
            "argoproj.io"
          ],
          "resources": [
            "workflows",
            "workflows/finalizers"
          ],
          "verbs": [
            "get",
            "list",
            "watch",
            "update",
            "patch",
            "delete"
          ]
        }
      ]
    },
    
    {
      "apiVersion": "rbac.authorization.k8s.io/v1",
      "kind": "ClusterRoleBinding",
      "metadata": {
        "name": "argo-binding"
      },
      "roleRef": {
        "apiGroup": "rbac.authorization.k8s.io",
        "kind": "ClusterRole",
        "name": "argo-cluster-role"
      },
      "subjects": [
        {
          "kind": "ServiceAccount",
          "name": "argo",
          "namespace": "dkube"
        }
      ]
    },
    
    {
      "apiVersion": "apps/v1beta2",
      "kind": "Deployment",
      "metadata": {
        "name": "workflow-controller",
        "namespace": "dkube"
      },
      "spec": {
        "selector": {
          "matchLabels": {
            "app": "workflow-controller"
          }
        },
        "template": {
          "metadata": {
            "labels": {
              "app": "workflow-controller"
            }
          },
          "spec": {
            "containers": [
              {
                "args": [
                  "--configmap",
                  "workflow-controller-configmap",
                  "--executor-image",
                  "argoproj/argoexec:v2.2.0"
                ],
                "command": [
                  "workflow-controller"
                ],
                "image": "argoproj/workflow-controller:v2.2.0",
                "name": "workflow-controller"
              }
            ],
            "serviceAccountName": "argo"
          }
        }
      }
    }
   
  ]
}

