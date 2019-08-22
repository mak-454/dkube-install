{
  parts(params):: {
    local dkubeUiService = import "dkube/service/dkube-ui-service.libsonnet",
    local ambassador = import "dkube/service/ambassador.libsonnet",
    local dkube = import "dkube/service/dkube.libsonnet",
    local logstash = import "dkube/service/logstash.libsonnet",
    local etcd = import "dkube/service/etcd.libsonnet",
    local d3ext = import "dkube/service/dkube-ext.libsonnet",
    local dfabproxy = import "dkube/service/dfabproxy.libsonnet",
    local d3downloader = import "dkube/service/dkube-d3downloader.libsonnet",
    local d3webapp = import "dkube/service/dkube-webapp.libsonnet",

    all:: dkubeUiService.all(params)
          + ambassador.all(params)
          + dkube.all(params)
          + logstash.all(params)
          + etcd.all(params)
          + d3ext.all(params)
          + dfabproxy.all(params)
          + d3downloader.all(params)
          + d3webapp.all(params)
  },
}
