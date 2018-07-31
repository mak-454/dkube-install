{
  parts(params):: {
    local minio = import "dkube/minio/minio.libsonnet",

    all:: minio.all(params)
  },
}
