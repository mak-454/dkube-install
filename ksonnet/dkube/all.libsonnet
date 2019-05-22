{
  parts(params):: {
    local daemonset = import "dkube/dkube/daemonset.libsonnet",
    local deployment = import "dkube/dkube/deployment.libsonnet",
    local statefulset = import "dkube/dkube/statefulset.libsonnet",

    all:: daemonset.all(params)
          + deployment.all(params)
          + statefulset.all(params)
  },

}
