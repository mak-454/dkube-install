// @apiVersion 0.1
// @name io.ksonnet.pkg.efk
// @description efk components
// @param name string Name to give to each of the components
// @shortDescription efk components. This create user environment.

local k = import "k.libsonnet";
local all = import "dkube/efk/all.libsonnet";

// updatedParams uses the environment namespace if
// the namespace parameter is not explicitly set
local updatedParams = params {
  namespace: if params.namespace == "null" then env.namespace else params.namespace
};

std.prune(k.core.v1.list.new(all.parts(updatedParams).all))
