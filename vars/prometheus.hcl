datacenters = [
  "lab",
]
prometheus_task_app_prometheus_yaml = <<EOF
---
global:
  scrape_interval: 30s
  evaluation_interval: 3s

rule_files:
  - rules.yml

alerting:
 alertmanagers:
    - consul_sd_configs:
      - server: {{ env "attr.unique.network.ip-address" }}:8500
        services:
        - alertmanager

remote_write:
  - url: http://localhost:9009/api/v1/push

scrape_configs:
  - job_name: lab
    consul_sd_configs:
    - server: {{ env "attr.unique.network.ip-address" }}:8500
      datacenter: lab
      tags:
      - metrics
    relabel_configs:
    - source_labels: [__meta_consul_service]
      target_label: job
    - source_labels: ['__meta_consul_service_id']
      regex: '.*-sidecar-proxy'
      action: drop
  - job_name: "nomad"
    metrics_path: "/v1/metrics"
    params:
      format:
      - "prometheus"
    consul_sd_configs:
    - server: "{{ env "attr.unique.network.ip-address" }}:8500"
      services:
        - "nomad"
        - "nomad-client"
      tags:
        - "http"
    relabel_configs:
    - source_labels: [__meta_consul_service]
      target_label: job
EOF
prometheus_task_services = [{
  service_port_label = "http",
  service_name       = "prometheus",
  service_tags       = ["metrics"],
  service_upstreams  = [{name = "mimir", port = 9009}],
  check_enabled      = true,
  check_path         = "/-/healthy",
  check_interval     = "3s",
  check_timeout      = "1s",
}]