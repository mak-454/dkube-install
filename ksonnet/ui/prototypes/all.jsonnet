// @apiVersion 0.1
// @name io.ksonnet.pkg.dkube-ui
// @description DKube ui components
// @param name string Name to give to each of the components
// @shortDescription DKube user components. This create user environment.
// @optionalParam namespace string dkube Namespace for dkube ui.
// @optionalParam dkubeDockerSecret string  Docker secret for dkube images.
// @optionalParam tag string v1 tag for component
// @optionalParam dkubeUIImage string ocdr/dkube-uiserver:v6.1 UI image for dkube.
// @optionalParam nodebind string no Node selector flag
// @optionalParam dkubePort number 32222 dkube access port

local k = import "k.libsonnet";
local all = import "dkube/ui/all.libsonnet";

// updatedParams uses the environment namespace if
// the namespace parameter is not explicitly set
local updatedParams = params {
  namespace: if params.namespace == "null" then env.namespace else params.namespace
};

std.prune(k.core.v1.list.new(all.parts(updatedParams).all))
