{
  all(params):: [
{
    "apiVersion": "monitoring.coreos.com/v1",
    "kind": "PrometheusRule",
    "metadata": {
        "labels": {
            "prometheus": "kube-prometheus",
            "role": "alert-rules"
        },
        "name": "dkube-rules",
        "namespace": "monitoring",
    },
    "spec": {
        "groups": [
            {
                "name": "dkube.rules",
                "rules": [
                    {
                        "alert": "BillingAgentDown",
                        "expr": "absent(billing_agent_status{name=\"billing_agent\"}) == 1",
                        "for": "30s",
                        "labels": {
                            "app": "billing_agent",
                            "severity": "critical"
                        }
                    }
                ]
            }
        ]
    }
}
]
}
