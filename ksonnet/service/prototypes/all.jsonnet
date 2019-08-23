// @apiVersion 0.1
// @name io.ksonnet.pkg.services
// @description DKube service components
// @param name string Name to give to each of the components
// @shortDescription DKube service components.
// @optionalParam namespace string dkube Namespace for dkube service.
// @optionalParam dkubeClusterRole string  Cluster role for dkube
// @optionalParam dkubeApiServerAddr string 0.0.0.0:5000 The address of dkube api server

local k = import "k.libsonnet";
local all = import "dkube/service/all.libsonnet";

// updatedParams uses the environment namespace if
// the namespace parameter is not explicitly set
local updatedParams = params {
  namespace: if params.namespace == "null" then env.namespace else params.namespace
};

std.prune(k.core.v1.list.new(all.parts(updatedParams).all))
