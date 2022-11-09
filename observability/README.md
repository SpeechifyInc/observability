# Setup

!!! Update the service account annotations with your project ID in `mimir.yaml` `loki.yaml` and `tempo.yaml` as well as in `apply-gcp-service-account.sh`

1. Install Grafana Agent Operator with `kubectl apply -f grafana-agent-operator.yaml`
2. Run `apply-gcp-service-account.sh` to setup buckets and service accounts
3. Deploy observability objects with `kubectl apply -k .`

After creation of minio
