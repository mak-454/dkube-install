// @apiVersion 0.1
// @name io.ksonnet.pkg.dkube
// @description DKube components
// @param name string Name to give to each of the components
// @shortDescription DKube components. This currently includes dkube api server and dkube tf controller.
// @optionalParam namespace string dkube Namespace to use for the components. It is automatically inherited from the environment if not set.
// @optionalParam minioSecretKey string Minio Secret Key
// @optionalParam dkubeApiServerImage string ocdr/dkube-d3api:alpha3.1 The image for dkube api server.
// @optionalParam dkubeMountPath string /home/dkube/d3s Mount path to mount artifacts in dkube
// @optionalParam logstashImage string ocdr/dkube-logstash:v2 Logstash image
// @optionalParam dfabProxyImage string ocdr/dkube-dfabproxy:alpha3 Dfabproxy image
// @optionalParam rdmaEnabled string false RDMA enable flag
// @optionalParam dkubeDockerSecret string  Docker secret for dkube images
// @optionalParam filebeatImage string ocdr/dkube-filebeat:v2 Filebeat image
// @optionalParam dkubeExtImage string ocdr/dkube-ext:alpha3 dkube-ext image
// @optionalParam dkubeWatcherImage string ocdr/dkube-d3watcher:1.1.2 dkube-d3watcher image
// @optionalParam tag string v1 tag for component
// @optionalParam dkubeApiServerAddr string 0.0.0.0:5000 The address of dkube api server
// @optionalParam dkubePVC string dkube-pvc The PVC for dkube etcd server

local k = import "k.libsonnet";
local all = import "dkube/dkube/all.libsonnet";

// updatedParams uses the environment namespace if
// the namespace parameter is not explicitly set
local updatedParams = params {
  namespace: if params.namespace == "null" then env.namespace else params.namespace
};

std.prune(k.core.v1.list.new(all.parts(updatedParams).all))
