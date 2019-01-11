{
  parts(params):: {
    local ambassador = import "dkube/dkube/ambassador.libsonnet",
    local dkube = import "dkube/dkube/dkube.libsonnet",
    local logstash = import "dkube/dkube/logstash.libsonnet",
    local etcd = import "dkube/dkube/etcd.libsonnet",
    local d3ext = import "dkube/dkube/dkube-ext.libsonnet",
    local dfabproxy = import "dkube/dkube/dfabproxy.libsonnet",
    local filebeat = import "dkube/dkube/filebeat.libsonnet",

    all:: dkube.all(params)
          + ambassador.all(params)
          + logstash.all(params)
          + etcd.all(params)
          + d3ext.all(params)
          + dfabproxy.all(params)
          + filebeat.all(params)
  },

}
