{
  parts(params):: {
    local daemonset = import "dkube/dkube/daemonset.libsonnet",
    local deployment = import "dkube/dkube/deployment.libsonnet",

    all:: daemonset.all(params)
          + deployment.all(params)
  },

}
