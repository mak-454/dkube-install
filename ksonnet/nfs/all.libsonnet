{
  parts(params):: {
    local nfs = import "dkube/nfs/nfs.libsonnet",

    all:: nfs.all(params)
  },
}
