{
  all(params):: [
    
    {
      "apiVersion": "v1", 
      "data": {
        "Filter": "{ \"pods\": [\"pod-1\", \"pod-2\"],\"namespaces\": [\"oc\"] }"
      }, 
      "kind": "ConfigMap", 
      "metadata": {
        "labels": {
          "name": "OC"
        }, 
        "name": "oc-configmap", 
        "namespace": "dkube"
      }
    },
    {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "labels": {
          "addonmanager.kubernetes.io/mode": "Reconcile", 
          "k8s-app": "elasticsearch-logging", 
          "kubernetes.io/cluster-service": "true", 
          "kubernetes.io/name": "Elasticsearch"
        }, 
        "name": "elasticsearch-logging", 
        "namespace": "dkube"
      }, 
      "spec": {
        "ports": [
          {
            "port": 9200, 
            "protocol": "TCP", 
            "targetPort": "db"
          }
        ], 
        "selector": {
          "k8s-app": "elasticsearch-logging"
        }
      }
    },
    {
      "apiVersion": "v1", 
      "kind": "ServiceAccount", 
      "metadata": {
        "labels": {
          "addonmanager.kubernetes.io/mode": "Reconcile", 
          "k8s-app": "elasticsearch-logging", 
          "kubernetes.io/cluster-service": "true"
        }, 
        "name": "elasticsearch-logging", 
        "namespace": "dkube"
      }
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "ClusterRole", 
      "metadata": {
        "labels": {
          "addonmanager.kubernetes.io/mode": "Reconcile", 
          "k8s-app": "elasticsearch-logging", 
          "kubernetes.io/cluster-service": "true"
        }, 
        "name": "elasticsearch-logging"
      }, 
      "rules": [
        {
          "apiGroups": [
            ""
          ], 
          "resources": [
            "services", 
            "namespaces", 
            "endpoints"
          ], 
          "verbs": [
            "get"
          ]
        }
      ]
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "ClusterRoleBinding", 
      "metadata": {
        "labels": {
          "addonmanager.kubernetes.io/mode": "Reconcile", 
          "k8s-app": "elasticsearch-logging", 
          "kubernetes.io/cluster-service": "true"
        }, 
        "name": "elasticsearch-logging", 
        "namespace": "dkube"
      }, 
      "roleRef": {
        "apiGroup": "", 
        "kind": "ClusterRole", 
        "name": "elasticsearch-logging"
      }, 
      "subjects": [
        {
          "apiGroup": "", 
          "kind": "ServiceAccount", 
          "name": "elasticsearch-logging", 
          "namespace": "dkube"
        }
      ]
    },
    {
      "apiVersion": "apps/v1", 
      "kind": "StatefulSet", 
      "metadata": {
        "labels": {
          "addonmanager.kubernetes.io/mode": "Reconcile", 
          "k8s-app": "elasticsearch-logging", 
          "kubernetes.io/cluster-service": "true", 
          "version": "v5.6.4"
        }, 
        "name": "elasticsearch-logging", 
        "namespace": "dkube"
      }, 
      "spec": {
        "replicas": 2, 
        "selector": {
          "matchLabels": {
            "k8s-app": "elasticsearch-logging", 
            "version": "v5.6.4"
          }
        }, 
        "serviceName": "elasticsearch-logging", 
        "template": {
          "metadata": {
            "labels": {
              "k8s-app": "elasticsearch-logging", 
              "kubernetes.io/cluster-service": "true", 
              "version": "v5.6.4"
            }
          }, 
          "spec": {
            "containers": [
              {
                "env": [
                  {
                    "name": "NAMESPACE", 
                    "valueFrom": {
                      "fieldRef": {
                        "fieldPath": "metadata.namespace"
                      }
                    }
                  }
                ], 
                "image": "k8s.gcr.io/elasticsearch:v5.6.4", 
                "name": "elasticsearch-logging", 
                "ports": [
                  {
                    "containerPort": 9200, 
                    "name": "db", 
                    "protocol": "TCP"
                  }, 
                  {
                    "containerPort": 9300, 
                    "name": "transport", 
                    "protocol": "TCP"
                  }
                ], 
                "resources": {
                  "limits": {
                    "cpu": "1000m"
                  }, 
                  "requests": {
                    "cpu": "100m"
                  }
                }, 
                "volumeMounts": [
                  {
                    "mountPath": "/data", 
                    "name": "elasticsearch-logging"
                  }
                ]
              }
            ], 
            "initContainers": [
              {
                "command": [
                  "/sbin/sysctl", 
                  "-w", 
                  "vm.max_map_count=262144"
                ], 
                "image": "alpine:3.6", 
                "name": "elasticsearch-logging-init", 
                "securityContext": {
                  "privileged": true
                }
              }
            ], 
            "serviceAccountName": "elasticsearch-logging", 
            "volumes": [
              {
                "emptyDir": {}, 
                "name": "elasticsearch-logging"
              }
            ]
          }
        }
      }
    },
    {
      "apiVersion": "v1", 
      "data": {
        "containers.input.conf": "# This configuration file for Fluentd / td-agent is used\n# to watch changes to Docker log files. The kubelet creates symlinks that\n# capture the pod name, namespace, container name & Docker container ID\n# to the docker logs for pods in the /var/log/containers directory on the host.\n# If running this fluentd configuration in a Docker container, the /var/log\n# directory should be mounted in the container.\n#\n# These logs are then submitted to Elasticsearch which assumes the\n# installation of the fluent-plugin-elasticsearch & the\n# fluent-plugin-kubernetes_metadata_filter plugins.\n# See https://github.com/uken/fluent-plugin-elasticsearch &\n# https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter for\n# more information about the plugins.\n#\n# Example\n# =======\n# A line in the Docker log file might look like this JSON:\n#\n# {\"log\":\"2014/09/25 21:15:03 Got request with path wombat\\n\",\n#  \"stream\":\"stderr\",\n#   \"time\":\"2014-09-25T21:15:03.499185026Z\"}\n#\n# The time_format specification below makes sure we properly\n# parse the time format produced by Docker. This will be\n# submitted to Elasticsearch and should appear like:\n# $ curl 'http://elasticsearch-logging:9200/_search?pretty'\n# ...\n# {\n#      \"_index\" : \"logstash-2014.09.25\",\n#      \"_type\" : \"fluentd\",\n#      \"_id\" : \"VBrbor2QTuGpsQyTCdfzqA\",\n#      \"_score\" : 1.0,\n#      \"_source\":{\"log\":\"2014/09/25 22:45:50 Got request with path wombat\\n\",\n#                 \"stream\":\"stderr\",\"tag\":\"docker.container.all\",\n#                 \"@timestamp\":\"2014-09-25T22:45:50+00:00\"}\n#    },\n# ...\n#\n# The Kubernetes fluentd plugin is used to write the Kubernetes metadata to the log\n# record & add labels to the log record if properly configured. This enables users\n# to filter & search logs on any metadata.\n# For example a Docker container's logs might be in the directory:\n#\n#  /var/lib/docker/containers/997599971ee6366d4a5920d25b79286ad45ff37a74494f262e3bc98d909d0a7b\n#\n# and in the file:\n#\n#  997599971ee6366d4a5920d25b79286ad45ff37a74494f262e3bc98d909d0a7b-json.log\n#\n# where 997599971ee6... is the Docker ID of the running container.\n# The Kubernetes kubelet makes a symbolic link to this file on the host machine\n# in the /var/log/containers directory which includes the pod name and the Kubernetes\n# container name:\n#\n#    synthetic-logger-0.25lps-pod_default_synth-lgr-997599971ee6366d4a5920d25b79286ad45ff37a74494f262e3bc98d909d0a7b.log\n#    ->\n#    /var/lib/docker/containers/997599971ee6366d4a5920d25b79286ad45ff37a74494f262e3bc98d909d0a7b/997599971ee6366d4a5920d25b79286ad45ff37a74494f262e3bc98d909d0a7b-json.log\n#\n# The /var/log directory on the host is mapped to the /var/log directory in the container\n# running this instance of Fluentd and we end up collecting the file:\n#\n#   /var/log/containers/synthetic-logger-0.25lps-pod_default_synth-lgr-997599971ee6366d4a5920d25b79286ad45ff37a74494f262e3bc98d909d0a7b.log\n#\n# This results in the tag:\n#\n#  var.log.containers.synthetic-logger-0.25lps-pod_default_synth-lgr-997599971ee6366d4a5920d25b79286ad45ff37a74494f262e3bc98d909d0a7b.log\n#\n# The Kubernetes fluentd plugin is used to extract the namespace, pod name & container name\n# which are added to the log message as a kubernetes field object & the Docker container ID\n# is also added under the docker field object.\n# The final tag is:\n#\n#   kubernetes.var.log.containers.synthetic-logger-0.25lps-pod_default_synth-lgr-997599971ee6366d4a5920d25b79286ad45ff37a74494f262e3bc98d909d0a7b.log\n#\n# And the final log record look like:\n#\n# {\n#   \"log\":\"2014/09/25 21:15:03 Got request with path wombat\\n\",\n#   \"stream\":\"stderr\",\n#   \"time\":\"2014-09-25T21:15:03.499185026Z\",\n#   \"kubernetes\": {\n#     \"namespace\": \"default\",\n#     \"pod_name\": \"synthetic-logger-0.25lps-pod\",\n#     \"container_name\": \"synth-lgr\"\n#   },\n#   \"docker\": {\n#     \"container_id\": \"997599971ee6366d4a5920d25b79286ad45ff37a74494f262e3bc98d909d0a7b\"\n#   }\n# }\n#\n# This makes it easier for users to search for logs by pod name or by\n# the name of the Kubernetes container regardless of how many times the\n# Kubernetes pod has been restarted (resulting in a several Docker container IDs).\n# Json Log Example:\n# {\"log\":\"[info:2016-02-16T16:04:05.930-08:00] Some log text here\\n\",\"stream\":\"stdout\",\"time\":\"2016-02-17T00:04:05.931087621Z\"}\n# CRI Log Example:\n# 2016-02-17T00:04:05.931087621Z stdout F [info:2016-02-16T16:04:05.930-08:00] Some log text here\n<source>\n  @id fluentd-containers.log\n  @type tail\n  path /var/log/containers/*.log\n  pos_file /var/log/es-containers.log.pos\n  time_format %Y-%m-%dT%H:%M:%S.%NZ\n  tag raw.kubernetes.*\n  read_from_head true\n  <parse>\n    @type multi_format\n    <pattern>\n      format json\n      keep_time_key true\n      time_key time\n      time_format %Y-%m-%dT%H:%M:%S.%NZ\n    </pattern>\n    <pattern>\n      format /^(?<time>.+) (?<stream>stdout|stderr) [^ ]* (?<log>.*)$/\n      time_format %Y-%m-%dT%H:%M:%S.%N%:z\n    </pattern>\n  </parse>\n</source>\n# Detect exceptions in the log output and forward them as one log entry.\n<match raw.kubernetes.**>\n  @id raw.kubernetes\n  @type detect_exceptions\n  remove_tag_prefix raw\n  message log\n  stream stream\n  multiline_flush_interval 5\n  max_bytes 500000\n  max_lines 1000\n</match>", 
        "forward.input.conf": "# Takes the messages sent over TCP\n<source>\n  @type forward\n</source>", 
        "monitoring.conf": "# Prometheus Exporter Plugin\n# input plugin that exports metrics\n<source>\n  @type prometheus\n</source>\n<source>\n  @type monitor_agent\n</source>\n# input plugin that collects metrics from MonitorAgent\n<source>\n  @type prometheus_monitor\n  <labels>\n    host ${hostname}\n  </labels>\n</source>\n# input plugin that collects metrics for output plugin\n<source>\n  @type prometheus_output_monitor\n  <labels>\n    host ${hostname}\n  </labels>\n</source>\n# input plugin that collects metrics for in_tail plugin\n<source>\n  @type prometheus_tail_monitor\n  <labels>\n    host ${hostname}\n  </labels>\n</source>", 
        "output.conf": "# Enriches records with Kubernetes metadata\n<filter  kubernetes.**>\n  @type kubernetes_metadata\n</filter>\n   \n<match  kubernetes.var.log.containers.**_kube-system_**>\n# @id elasticsearch\n  @type elasticsearch\n  @log_level info\n  include_tag_key true\n  host elasticsearch-logging\n  port 9200\n  logstash_format true\n  buffer_chunk_limit 4M\n  # Cap buffer memory usage to 2MiB/chunk * 32 chunks = 64 MiB\n  buffer_queue_limit 256\n  flush_interval 5s\n  # Never wait longer than 5 minutes between retries.      \n  max_retry_wait 30\n  # Disable the limit on the number of retries (retry forever).\n  disable_retry_limit\n</match>", 
        "system.conf": "<system>\n  root_dir /tmp/fluentd-buffers/\n</system>", 
        "system.input.conf": "# Example:\n# 2015-12-21 23:17:22,066 [salt.state       ][INFO    ] Completed state [net.ipv4.ip_forward] at time 23:17:22.066081\n<source>\n  @id minion\n  @type tail\n  format /^(?<time>[^ ]* [^ ,]*)[^\\[]*\\[[^\\]]*\\]\\[(?<severity>[^ \\]]*) *\\] (?<message>.*)$/\n  time_format %Y-%m-%d %H:%M:%S\n  path /var/log/salt/minion\n  pos_file /var/log/salt.pos\n  tag salt\n</source>\n# Example:\n# Dec 21 23:17:22 gke-foo-1-1-4b5cbd14-node-4eoj startupscript: Finished running startup script /var/run/google.startup.script\n<source>\n  @id startupscript.log\n  @type tail\n  format syslog\n  path /var/log/startupscript.log\n  pos_file /var/log/es-startupscript.log.pos\n  tag startupscript\n</source>\n# Examples:\n# time=\"2016-02-04T06:51:03.053580605Z\" level=info msg=\"GET /containers/json\"\n# time=\"2016-02-04T07:53:57.505612354Z\" level=error msg=\"HTTP Error\" err=\"No such image: -f\" statusCode=404\n# TODO(random-liu): Remove this after cri container runtime rolls out.\n<source>\n  @id docker.log\n  @type tail\n  format /^time=\"(?<time>[^)]*)\" level=(?<severity>[^ ]*) msg=\"(?<message>[^\"]*)\"( err=\"(?<error>[^\"]*)\")?( statusCode=($<status_code>\\d+))?/\n  path /var/log/docker.log\n  pos_file /var/log/es-docker.log.pos\n  tag docker\n</source>\n# Example:\n# 2016/02/04 06:52:38 filePurge: successfully removed file /var/etcd/data/member/wal/00000000000006d0-00000000010a23d1.wal\n<source>\n  @id etcd.log\n  @type tail\n  # Not parsing this, because it doesn't have anything particularly useful to\n  # parse out of it (like severities).\n  format none\n  path /var/log/etcd.log\n  pos_file /var/log/es-etcd.log.pos\n  tag etcd\n</source>\n# Multi-line parsing is required for all the kube logs because very large log\n# statements, such as those that include entire object bodies, get split into\n# multiple lines by glog.\n# Example:\n# I0204 07:32:30.020537    3368 server.go:1048] POST /stats/container/: (13.972191ms) 200 [[Go-http-client/1.1] 10.244.1.3:40537]\n<source>\n  @id kubelet.log\n  @type tail\n  format multiline\n  multiline_flush_interval 5s\n  format_firstline /^\\w\\d{4}/\n  format1 /^(?<severity>\\w)(?<time>\\d{4} [^\\s]*)\\s+(?<pid>\\d+)\\s+(?<source>[^ \\]]+)\\] (?<message>.*)/\n  time_format %m%d %H:%M:%S.%N\n  path /var/log/kubelet.log\n  pos_file /var/log/es-kubelet.log.pos\n  tag kubelet\n</source>\n# Example:\n# I1118 21:26:53.975789       6 proxier.go:1096] Port \"nodePort for kube-system/default-http-backend:http\" (:31429/tcp) was open before and is still needed\n<source>\n  @id kube-proxy.log\n  @type tail\n  format multiline\n  multiline_flush_interval 5s\n  format_firstline /^\\w\\d{4}/\n  format1 /^(?<severity>\\w)(?<time>\\d{4} [^\\s]*)\\s+(?<pid>\\d+)\\s+(?<source>[^ \\]]+)\\] (?<message>.*)/\n  time_format %m%d %H:%M:%S.%N\n  path /var/log/kube-proxy.log\n  pos_file /var/log/es-kube-proxy.log.pos\n  tag kube-proxy\n</source>\n# Example:\n# I0204 07:00:19.604280       5 handlers.go:131] GET /api/v1/nodes: (1.624207ms) 200 [[kube-controller-manager/v1.1.3 (linux/amd64) kubernetes/6a81b50] 127.0.0.1:38266]\n<source>\n  @id kube-apiserver.log\n  @type tail\n  format multiline\n  multiline_flush_interval 5s\n  format_firstline /^\\w\\d{4}/\n  format1 /^(?<severity>\\w)(?<time>\\d{4} [^\\s]*)\\s+(?<pid>\\d+)\\s+(?<source>[^ \\]]+)\\] (?<message>.*)/\n  time_format %m%d %H:%M:%S.%N\n  path /var/log/kube-apiserver.log\n  pos_file /var/log/es-kube-apiserver.log.pos\n  tag kube-apiserver\n</source>\n# Example:\n# I0204 06:55:31.872680       5 servicecontroller.go:277] LB already exists and doesn't need update for service kube-system/kube-ui\n<source>\n  @id kube-controller-manager.log\n  @type tail\n  format multiline\n  multiline_flush_interval 5s\n  format_firstline /^\\w\\d{4}/\n  format1 /^(?<severity>\\w)(?<time>\\d{4} [^\\s]*)\\s+(?<pid>\\d+)\\s+(?<source>[^ \\]]+)\\] (?<message>.*)/\n  time_format %m%d %H:%M:%S.%N\n  path /var/log/kube-controller-manager.log\n  pos_file /var/log/es-kube-controller-manager.log.pos\n  tag kube-controller-manager\n</source>\n# Example:\n# W0204 06:49:18.239674       7 reflector.go:245] pkg/scheduler/factory/factory.go:193: watch of *api.Service ended with: 401: The event in requested index is outdated and cleared (the requested history has been cleared [2578313/2577886]) [2579312]\n<source>\n  @id kube-scheduler.log\n  @type tail\n  format multiline\n  multiline_flush_interval 5s\n  format_firstline /^\\w\\d{4}/\n  format1 /^(?<severity>\\w)(?<time>\\d{4} [^\\s]*)\\s+(?<pid>\\d+)\\s+(?<source>[^ \\]]+)\\] (?<message>.*)/\n  time_format %m%d %H:%M:%S.%N\n  path /var/log/kube-scheduler.log\n  pos_file /var/log/es-kube-scheduler.log.pos\n  tag kube-scheduler\n</source>\n# Example:\n# I1104 10:36:20.242766       5 rescheduler.go:73] Running Rescheduler\n<source>\n  @id rescheduler.log\n  @type tail\n  format multiline\n  multiline_flush_interval 5s\n  format_firstline /^\\w\\d{4}/\n  format1 /^(?<severity>\\w)(?<time>\\d{4} [^\\s]*)\\s+(?<pid>\\d+)\\s+(?<source>[^ \\]]+)\\] (?<message>.*)/\n  time_format %m%d %H:%M:%S.%N\n  path /var/log/rescheduler.log\n  pos_file /var/log/es-rescheduler.log.pos\n  tag rescheduler\n</source>\n# Example:\n# I0603 15:31:05.793605       6 cluster_manager.go:230] Reading config from path /etc/gce.conf\n<source>\n  @id glbc.log\n  @type tail\n  format multiline\n  multiline_flush_interval 5s\n  format_firstline /^\\w\\d{4}/\n  format1 /^(?<severity>\\w)(?<time>\\d{4} [^\\s]*)\\s+(?<pid>\\d+)\\s+(?<source>[^ \\]]+)\\] (?<message>.*)/\n  time_format %m%d %H:%M:%S.%N\n  path /var/log/glbc.log\n  pos_file /var/log/es-glbc.log.pos\n  tag glbc\n</source>\n# Example:\n# I0603 15:31:05.793605       6 cluster_manager.go:230] Reading config from path /etc/gce.conf\n<source>\n  @id cluster-autoscaler.log\n  @type tail\n  format multiline\n  multiline_flush_interval 5s\n  format_firstline /^\\w\\d{4}/\n  format1 /^(?<severity>\\w)(?<time>\\d{4} [^\\s]*)\\s+(?<pid>\\d+)\\s+(?<source>[^ \\]]+)\\] (?<message>.*)/\n  time_format %m%d %H:%M:%S.%N\n  path /var/log/cluster-autoscaler.log\n  pos_file /var/log/es-cluster-autoscaler.log.pos\n  tag cluster-autoscaler\n</source>\n# Logs from systemd-journal for interesting services.\n# TODO(random-liu): Remove this after cri container runtime rolls out.\n<source>\n  @id journald-docker\n  @type systemd\n  filters [{ \"_SYSTEMD_UNIT\": \"docker.service\" }]\n  <storage>\n    @type local\n    persistent true\n  </storage>\n  read_from_head true\n  tag docker\n</source>\n<source>\n  @id journald-container-runtime\n  @type systemd\n  filters [{ \"_SYSTEMD_UNIT\": \"{{ container_runtime }}.service\" }]\n  <storage>\n    @type local\n    persistent true\n  </storage>\n  read_from_head true\n  tag container-runtime\n</source>\n<source>\n  @id journald-kubelet\n  @type systemd\n  filters [{ \"_SYSTEMD_UNIT\": \"kubelet.service\" }]\n  <storage>\n    @type local\n    persistent true\n  </storage>\n  read_from_head true\n  tag kubelet\n</source>\n<source>\n  @id journald-node-problem-detector\n  @type systemd\n  filters [{ \"_SYSTEMD_UNIT\": \"node-problem-detector.service\" }]\n  <storage>\n    @type local\n    persistent true\n  </storage>\n  read_from_head true\n  tag node-problem-detector\n</source>\n\n<source>\n  @id kernel\n  @type systemd\n  filters [{ \"_TRANSPORT\": \"kernel\" }]\n  <storage>\n    @type local\n    persistent true\n  </storage>\n  <entry>\n    fields_strip_underscores true\n    fields_lowercase true\n  </entry>\n  read_from_head true\n  tag kernel\n</source>"
      }, 
      "kind": "ConfigMap", 
      "metadata": {
        "labels": {
          "addonmanager.kubernetes.io/mode": "Reconcile"
        }, 
        "name": "fluentd-es-config-v0.1.4", 
        "namespace": "dkube"
      }
    },
    {
      "apiVersion": "v1", 
      "kind": "ServiceAccount", 
      "metadata": {
        "labels": {
          "addonmanager.kubernetes.io/mode": "Reconcile", 
          "k8s-app": "fluentd-es", 
          "kubernetes.io/cluster-service": "true"
        }, 
        "name": "fluentd-es", 
        "namespace": "dkube"
      }
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "ClusterRole", 
      "metadata": {
        "labels": {
          "addonmanager.kubernetes.io/mode": "Reconcile", 
          "k8s-app": "fluentd-es", 
          "kubernetes.io/cluster-service": "true"
        }, 
        "name": "fluentd-es"
      }, 
      "rules": [
        {
          "apiGroups": [
            ""
          ], 
          "resources": [
            "namespaces", 
            "pods"
          ], 
          "verbs": [
            "get", 
            "watch", 
            "list"
          ]
        }
      ]
    },
    {
      "apiVersion": "rbac.authorization.k8s.io/v1", 
      "kind": "ClusterRoleBinding", 
      "metadata": {
        "labels": {
          "addonmanager.kubernetes.io/mode": "Reconcile", 
          "k8s-app": "fluentd-es", 
          "kubernetes.io/cluster-service": "true"
        }, 
        "name": "fluentd-es"
      }, 
      "roleRef": {
        "apiGroup": "", 
        "kind": "ClusterRole", 
        "name": "fluentd-es"
      }, 
      "subjects": [
        {
          "apiGroup": "", 
          "kind": "ServiceAccount", 
          "name": "fluentd-es", 
          "namespace": "dkube"
        }
      ]
    },
    {
      "apiVersion": "apps/v1", 
      "kind": "DaemonSet", 
      "metadata": {
        "labels": {
          "addonmanager.kubernetes.io/mode": "Reconcile", 
          "k8s-app": "fluentd-es", 
          "kubernetes.io/cluster-service": "true", 
          "version": "v2.0.4"
        }, 
        "name": "fluentd-es", 
        "namespace": "dkube"
      }, 
      "spec": {
        "selector": {
          "matchLabels": {
            "k8s-app": "fluentd-es", 
            "version": "v2.0.4"
          }
        }, 
        "template": {
          "metadata": {
            "annotations": {
              "scheduler.alpha.kubernetes.io/critical-pod": ""
            }, 
            "labels": {
              "k8s-app": "fluentd-es", 
              "kubernetes.io/cluster-service": "true", 
              "version": "v2.0.4"
            }
          }, 
          "spec": {
            "containers": [
              {
                "env": [
                  {
                    "name": "FLUENTD_ARGS", 
                    "value": "--no-supervisor -q"
                  }
                ], 
                "image": "k8s.gcr.io/fluentd-elasticsearch:v2.0.4", 
                "name": "fluentd-es", 
                "resources": {
                  "limits": {
                    "memory": "500Mi"
                  }, 
                  "requests": {
                    "cpu": "100m", 
                    "memory": "200Mi"
                  }
                }, 
                "volumeMounts": [
                  {
                    "mountPath": "/var/log", 
                    "name": "varlog"
                  }, 
                  {
                    "mountPath": "/var/lib/docker/containers", 
                    "name": "varlibdockercontainers", 
                    "readOnly": true
                  }, 
                  {
                    "mountPath": "/etc/fluent/config.d", 
                    "name": "config-volume"
                  }
                ]
              }
            ], 
            "priorityClassName": "system-node-critical", 
            "serviceAccountName": "fluentd-es", 
            "terminationGracePeriodSeconds": 30, 
            "volumes": [
              {
                "hostPath": {
                  "path": "/var/log"
                }, 
                "name": "varlog"
              }, 
              {
                "hostPath": {
                  "path": "/var/lib/docker/containers"
                }, 
                "name": "varlibdockercontainers"
              }, 
              {
                "configMap": {
                  "name": "fluentd-es-config-v0.1.4"
                }, 
                "name": "config-volume"
              }
            ]
          }
        }
      }
    },
    {
      "apiVersion": "apps/v1", 
      "kind": "Deployment", 
      "metadata": {
        "labels": {
          "addonmanager.kubernetes.io/mode": "Reconcile", 
          "k8s-app": "kibana-logging", 
          "kubernetes.io/cluster-service": "true"
        }, 
        "name": "kibana-logging", 
        "namespace": "dkube"
      }, 
      "spec": {
        "replicas": 1, 
        "selector": {
          "matchLabels": {
            "k8s-app": "kibana-logging"
          }
        }, 
        "template": {
          "metadata": {
            "labels": {
              "k8s-app": "kibana-logging"
            }
          }, 
          "spec": {
            "containers": [
              {
                "env": [
                  {
                    "name": "ELASTICSEARCH_URL", 
                    "value": "http://elasticsearch-logging:9200"
                  }, 
                  {
                    "name": "SERVER_BASEPATH", 
                    "value": "/dkube/kibana"
                  }, 
                  {
                    "name": "XPACK_MONITORING_ENABLED", 
                    "value": "false"
                  }, 
                  {
                    "name": "XPACK_SECURITY_ENABLED", 
                    "value": "false"
                  }
                ], 
                "image": "docker.elastic.co/kibana/kibana:5.6.4", 
                "name": "kibana-logging", 
                "ports": [
                  {
                    "containerPort": 5601, 
                    "name": "ui", 
                    "protocol": "TCP"
                  }
                ], 
                "resources": {
                  "limits": {
                    "cpu": "1000m"
                  }, 
                  "requests": {
                    "cpu": "100m"
                  }
                }
              }
            ]
          }
        }
      }
    },
    {
      "apiVersion": "v1", 
      "kind": "Service", 
      "metadata": {
        "annotations": {
          "getambassador.io/config": "---\napiVersion: ambassador/v0\nkind:  Mapping\nname:  dkube_spinner_kibana\nprefix: /dkube/kibana/\nrewrite: /\nservice: kibana-logging.dkube:5601"
        }, 
        "name": "kibana-service-mapping", 
        "namespace": "dkube"
      }, 
      "spec": {
        "clusterIP": "None", 
        "type": "ClusterIP"
      }
    }
  ]
}

