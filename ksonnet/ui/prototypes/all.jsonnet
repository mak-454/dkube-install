// @apiVersion 0.1
// @name io.ksonnet.pkg.dkube-ui
// @description DKube ui components
// @param name string Name to give to each of the components
// @shortDescription DKube user components. This create user environment.
// @optionalParam dkubeUIImage string dkube/uiserver:v1 UI image for dkube.
// @optionalParam restServerEndpoint string <master-ip:nodeport> dkube address.
// @optionalParam gitClientId string null github client id.
// @optionalParam gitClientSecret string null github client secret.
// @optionalParam namespace string dkube Namespace for dkube ui.

local k = import "k.libsonnet";
local all = import "dkube/ui/all.libsonnet";

// updatedParams uses the environment namespace if
// the namespace parameter is not explicitly set
local updatedParams = params {
  namespace: if params.namespace == "null" then env.namespace else params.namespace
};

std.prune(k.core.v1.list.new(all.parts(updatedParams).all))
