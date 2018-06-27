{
  parts(params):: {
    local pachyderm = import "dkube/pachyderm/pachyderm.libsonnet",

    all:: pachyderm.all(params)
  },
}
