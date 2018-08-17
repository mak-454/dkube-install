{
  parts(params):: {
    local monitoring = import "dkube/monitoring/monitoring.libsonnet",

    all:: monitoring.all(params)
  },
}
