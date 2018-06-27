{
  parts(params):: {
    local argo = import "dkube/argo/argo.libsonnet",

    all:: argo.all(params)
  },
}
