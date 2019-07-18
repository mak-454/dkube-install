{
  parts(params):: {
    local grafana_config = import "dkube/monitoring/grafana_config.libsonnet",
    local gpu_monitoring = import "dkube/monitoring/gpu_monitoring.libsonnet",
    local cadvisor = import "dkube/monitoring/cadvisor.libsonnet",
    local service = import "dkube/monitoring/service.libsonnet",

    all:: grafana_config.all(params) + gpu_monitoring.all(params) + cadvisor.all(params) + service.all(params)
  },
}
