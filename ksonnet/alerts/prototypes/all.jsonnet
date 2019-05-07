// @apiVersion 0.1
// @name io.ksonnet.pkg.alerts
// @description alerts components
// @param name string Name to give to each of the components
// @shortDescription alerts components. This creates user environment.
// @optionalParam dkubeDockerSecret string  Docker secret for dkube images
// @optionalParam billingAgentImage string ocdr/billing-agent:1.2 BillingAgent image
// @optionalParam heartBeatImage string ocdr/metering-heartbeat:1.2 HeartBeat image

local k = import "k.libsonnet";
local all = import "dkube/alerts/all.libsonnet";

// updatedParams uses the environment namespace if
// the namespace parameter is not explicitly set
local updatedParams = params {
  namespace: if params.namespace == "null" then env.namespace else params.namespace
};

std.prune(k.core.v1.list.new(all.parts(updatedParams).all))
