// @apiVersion 0.1
// @name io.ksonnet.pkg.dkube
// @description DKube components
// @param name string Name to give to each of the components
// @shortDescription DKube components. This currently includes dkube api server and dkube tf controller.
// @optionalParam namespace string dkube Namespace to use for the components. It is automatically inherited from the environment if not set.
// @optionalParam dkubeApiServerImage string ocdr/dkube-d3api:alpha3.1 The image for dkube api server.
// @optionalParam dkubeApiServerAddr string 0.0.0.0:5000 The address of dkube api server
// @optionalParam dkubeMountPath string /home/dkube/d3s Mount path to mount artifacts in dkube
// @optionalParam ambassadorNodeport number 32222 Ambassador nodeport
// @optionalParam logstashImage string ocdr/dkube-logstash:v1 Logstash image
// @optionalParam rdmaEnabled string false RDMA enable flag
// @optionalParam dkubeDockerSecret string  Docker secret for dkube images
// @optionalParam dkubeClusterRole string  Cluster role for dkube
// @optionalParam dkubeExtImage string ocdr/dkube-ext:alpha3 dkube-ext image

local k = import "k.libsonnet";
local all = import "dkube/dkube/all.libsonnet";

// updatedParams uses the environment namespace if
// the namespace parameter is not explicitly set
local updatedParams = params {
  namespace: if params.namespace == "null" then env.namespace else params.namespace
};

std.prune(k.core.v1.list.new(all.parts(updatedParams).all))
