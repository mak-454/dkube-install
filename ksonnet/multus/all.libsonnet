{
  parts(params):: {
    local multus = import "dkube/multus/multus.libsonnet",

    all:: multus.all(params)
  },
}
