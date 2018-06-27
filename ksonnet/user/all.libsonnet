{
  parts(params):: {
    local dkubeUser = import "dkube/user/dkube-user.libsonnet",

    all:: dkubeUser.all(params)
  },
}
