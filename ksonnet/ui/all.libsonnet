{
  parts(params):: {
    local dkubeUi = import "dkube/ui/dkube-ui.libsonnet",

    all:: dkubeUi.all(params)
  },
}
