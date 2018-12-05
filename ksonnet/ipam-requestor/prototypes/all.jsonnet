// @apiVersion 0.1
// @name io.ksonnet.pkg.ipam-requestor
// @description ipam-requestor components
// @param name string Name to give to each of the components
// @shortDescription ipam-requestor components.
// @optionalParam ipamRequestorImage string ocdr/dkube-custom-ipam-requestor:v2 Dkube custom ipam requester image

local k = import "k.libsonnet";
local all = import "dkube/ipam-requestor/all.libsonnet";

// updatedParams uses the environment namespace if
// the namespace parameter is not explicitly set
local updatedParams = params {
  namespace: if params.namespace == "null" then env.namespace else params.namespace
};

std.prune(k.core.v1.list.new(all.parts(updatedParams).all))
