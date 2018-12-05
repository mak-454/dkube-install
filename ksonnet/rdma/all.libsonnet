{
  parts(params):: {
    local ipam = import "dkube/rdma/ipam.libsonnet",
    local ipam_requestor = import "dkube/rdma/ipam_requestor.libsonnet",
    local multus = import "dkube/rdma/multus.libsonnet",

    all:: ipam.all(params) + ipam_requestor.all(params) + multus.all(params)
  },
}
