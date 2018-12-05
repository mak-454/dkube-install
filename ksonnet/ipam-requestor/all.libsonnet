{
  parts(params):: {
    local ipam_requestor = import "dkube/ipam-requestor/ipam_requestor.libsonnet",

    all:: ipam_requestor.all(params)
  },
}
