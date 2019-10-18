{
  parts(params):: {
    local grafana_config = import "dkube/monitoring/grafana_config.libsonnet",
    local gpu_monitoring = import "dkube/monitoring/gpu_monitoring.libsonnet",
    local dkube_logger_metric = import "dkube/monitoring/dkube_logger_metric.libsonnet",
    local cadvisor = import "dkube/monitoring/cadvisor.libsonnet",
    local d3_storage = import "dkube/monitoring/dkube_storage_monitoring.libsonnet",

    all:: grafana_config.all(params) + gpu_monitoring.all(params) + cadvisor.all(params) + dkube_logger_metric.all(params) + d3_storage.all(params)
  },
}
