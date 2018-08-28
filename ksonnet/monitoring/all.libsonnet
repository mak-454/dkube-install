{
  parts(params):: {
    local grafana_config = import "dkube/monitoring/grafana_config.libsonnet",
    local gpu_monitoring = import "dkube/monitoring/gpu_monitoring.libsonnet",

    all:: grafana_config.all(params) + gpu_monitoring.all(params)
  },
}
