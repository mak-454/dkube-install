{
  parts(params):: {
    local ambassador = import "dkube/dkube/ambassador.libsonnet",
    local dkube = import "dkube/dkube/dkube.libsonnet",
    local logstash = import "dkube/dkube/logstash.libsonnet",

    all:: dkube.all(params)
          + ambassador.all(params)
          + logstash.all(params)
  },
}
