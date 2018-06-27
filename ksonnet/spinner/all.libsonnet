{
  parts(params):: {
    local ambassador = import "dkube/spinner/ambassador.libsonnet",
    local dkube = import "dkube/spinner/dkube.libsonnet",

    all:: dkube.all(params)
          + ambassador.all(params)
  },
}
