// @apiVersion 0.1
// @name io.ksonnet.pkg.dkube-spinner
// @description DKube spinner components
// @param name string Name to give to each of the components
// @shortDescription DKube spinner components. This currently includes dkube api server and dkube tf controller.
// @optionalParam namespace string dkube Namespace to use for the components. It is automatically inherited from the environment if not set.
// @optionalParam dkubeApiServerImage string ocdr/dkube-api-server:v1 The image for dkube spinner api server.
// @optionalParam dkubeTFControllerImage string ocdr/dkube-tf-controller:v1 The image for dkube spinner tf-controller.
// @optionalParam dkubePachydermClientImage string ocdr/dkube-pachyderm-client:v1 The image for dkube spinner pachyderm client.
// @optionalParam dkubeLogCollectorImage string ocdr/dkube-log-collector:v1 The image for log collector.
// @optionalParam dkubeApiServerAddr string localhost:5000 The address of dkube api server
// @optionalParam pachydermAddr string pachd:650 The address of pachyderm server address
// @optionalParam dkubeMountPath string /tmp/dkube/scratchpad Mount path to mount pvc in dkube engine
// @optionalParam nfsServerAddr string 10.96.0.20 Nfs server ip
// @optionalParam nfsBasePath string /exports Mfs mount path
// @optionalParam ambassadorNodeport number 32222 Ambassador nodeport

local k = import "k.libsonnet";
local all = import "dkube/spinner/all.libsonnet";

// updatedParams uses the environment namespace if
// the namespace parameter is not explicitly set
local updatedParams = params {
  namespace: if params.namespace == "null" then env.namespace else params.namespace
};

std.prune(k.core.v1.list.new(all.parts(updatedParams).all))
