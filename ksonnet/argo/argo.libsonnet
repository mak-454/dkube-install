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
            "patch"
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
            "workflows"
          ], 
          "verbs": [
            "get", 
            "list", 
            "watch", 
            "update", 
            "patch"
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
      "apiVersion": "v1", 
      "data": {
        "config": "artifactRepository: {}\nexecutorImage: argoproj/argoexec:v2.1.1\n"
      }, 
      "kind": "ConfigMap", 
      "metadata": {
        "creationTimestamp": null, 
        "name": "workflow-controller-configmap", 
        "namespace": "dkube"
      }
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
        "strategy": {}, 
        "template": {
          "metadata": {
            "creationTimestamp": null, 
            "labels": {
              "app": "workflow-controller"
            }
          }, 
          "spec": {
            "containers": [
              {
                "args": [
                  "--configmap", 
                  "workflow-controller-configmap"
                ], 
                "command": [
                  "workflow-controller"
                ], 
                "env": [
                  {
                    "name": "ARGO_NAMESPACE", 
                    "valueFrom": {
                      "fieldRef": {
                        "apiVersion": "v1", 
                        "fieldPath": "metadata.namespace"
                      }
                    }
                  }
                ], 
                "image": "argoproj/workflow-controller:v2.1.1", 
                "name": "workflow-controller", 
                "resources": {}
              }
            ], 
            "serviceAccountName": "argo"
          }
        }
      }
    }
  ]
}

