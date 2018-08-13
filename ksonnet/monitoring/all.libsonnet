{
  parts(params):: {
    local prometheus = import "dkube/monitoring/prometheus.libsonnet",
    local grafana = import "dkube/monitoring/grafana.libsonnet",

    all:: prometheus.all(params) + grafana.all(params)
  },
}
