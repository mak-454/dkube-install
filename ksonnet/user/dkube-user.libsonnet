{
  all(params):: [
    $.parts().dkubeUserNamespace(params.username),
    $.parts().dkubeUserServiceAccount(params.username),
    $.parts().dkubeUserClusterRoleBinding(params.username),
    $.parts().dkubeUserRoleBinding(params.username),
  ],

  parts():: {
    dkubeUserNamespace(username):: {
      "apiVersion": "v1",
      "kind": "Namespace",
      "metadata": {
        "name": username
      }
    }, // namespace
    dkubeUserServiceAccount(username):: {
      "apiVersion": "v1", 
      "kind": "ServiceAccount", 
      "metadata": {
        "name": username, 
        "namespace": username
      }
    }, // service account
    dkubeUserClusterRoleBinding(username):: {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "ClusterRoleBinding", 
      "metadata": {
        "name": username, 
        "namespace": username
      }, 
      "roleRef": {
        "apiGroup": "rbac.authorization.k8s.io", 
        "kind": "ClusterRole", 
        "name": "dkube-spinner-user-clusterrole"
      }, 
      "subjects": [
        {
          "kind": "ServiceAccount", 
          "name": username, 
          "namespace": username
        }
      ]
    }, // clusterrolebinding
    dkubeUserRoleBinding(username):: {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "RoleBinding", 
      "metadata": {
        "name": username, 
        "namespace": username
      }, 
      "roleRef": {
        "apiGroup": "rbac.authorization.k8s.io", 
        "kind": "ClusterRole", 
        "name": "dkube-spinner-user-role"
      }, 
      "subjects": [
        {
          "kind": "ServiceAccount", 
          "name": username, 
          "namespace": username
        }
      ]
    }, // rolebinding
  }, // parts
}

