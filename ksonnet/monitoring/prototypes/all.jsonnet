// @apiVersion 0.1
// @name io.ksonnet.pkg.monitoring
// @description monitoring components
// @param name string Name to give to each of the components
// @shortDescription monitoring components. This create user environment.
// @optionalParam dkubeDockerSecret string  Docker secret for dkube images
// @optionalParam nodebind string yes Node selector flag

local k = import "k.libsonnet";
local all = import "dkube/monitoring/all.libsonnet";

// updatedParams uses the environment namespace if
// the namespace parameter is not explicitly set
local updatedParams = params {
  namespace: if params.namespace == "null" then env.namespace else params.namespace
};

std.prune(k.core.v1.list.new(all.parts(updatedParams).all))
