// @apiVersion 0.1
// @name io.ksonnet.pkg.ipam
// @description ipam components
// @param name string Name to give to each of the components
// @shortDescription ipam components.
// @optionalParam ipamImage string ocdr/dkube-custom-ipam:v2 Dkube custom ipam image.

local k = import "k.libsonnet";
local all = import "dkube/ipam/all.libsonnet";

// updatedParams uses the environment namespace if
// the namespace parameter is not explicitly set
local updatedParams = params {
  namespace: if params.namespace == "null" then env.namespace else params.namespace
};

std.prune(k.core.v1.list.new(all.parts(updatedParams).all))
