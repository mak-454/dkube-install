{
  parts(params):: {
    local ipam = import "dkube/ipam/ipam.libsonnet",

    all:: ipam.all(params)
  },
}
