{
  parts(params):: {
    local billing_agent = import "dkube/alerts/billing_agent.libsonnet",
    local alert_rules = import "dkube/alerts/alert_rules.libsonnet",

    all:: billing_agent.all(params) + alert_rules.all(params)
  },
}
