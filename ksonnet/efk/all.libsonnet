{
  parts(params):: {
    local efk = import "dkube/efk/efk.libsonnet",

    all:: efk.all(params)
  },
}
