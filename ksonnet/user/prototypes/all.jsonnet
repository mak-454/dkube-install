// @apiVersion 0.1
// @name io.ksonnet.pkg.dkube-user
// @description DKube user components
// @param name string Name to give to each of the components
// @shortDescription DKube user components. This create user environment.
// @optionalParam username string null Username to create and set environment in cluster.

local k = import "k.libsonnet";
local all = import "dkube/user/all.libsonnet";

// updatedParams uses the environment namespace if
// the namespace parameter is not explicitly set
local updatedParams = params {
  namespace: if params.namespace == "null" then env.namespace else params.namespace
};

std.prune(k.core.v1.list.new(all.parts(updatedParams).all))
