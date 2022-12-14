# Observability

Definitions for Grafana, Grafana Agent, Mimir, Loki, and Tempo on Google Kubernetes Engine. This repository also includes definitions for Traefik ingress, K3S helm controller, cert manager and kubernetes dashboard for convenience.

## Getting started

### Cert Manager

We use Cert Manager configured with a DNS resolver using Cloudflare and Lets Encrypt. You'll likely need to edit this configuration based on your setup. For our case, create a `cloudflare-api-token-secret.yaml` file under `/cert-manager` based on the template in `cloudflare-api-token-secret.example.yaml`. Replace the `api-token` field based on the following guide: https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/

You should now be ready to install cert-manager with `kubectl apply -k cert-manager`. If the install fails, try re-running it a few times. This tends to happen because required resources are still pending while kustomize is deploying.

### Controllers

We use the [K3S Helm Controller](https://github.com/k3s-io/helm-controller) to get a `HelmChart` CRD for a more Kubernetes native way of deploying helm charts. Install the controller with `kubectl apply -k helm-controller`

Install the Grafana Agent operator which sets up required CRDs such as `ServiceMonitor` for Traefik and other components `kubectl apply -f observability/grafana-agent-operator.yaml`

We use the open source edge router [Traefik](https://traefik.io/traefik/) for ingress which comes with a built in dashboard.

1. Create a file called `secret.yaml` under `traefik` based on `secret.example.yaml`. Follow the instructions to setup the login
2. Update the `/traefik/dashboard.yaml` file with your domain
3. Install the Traefik ingress controller `kubectl apply -k traefik`
4. Go to https://traefik.observability.your-domain.com to see your dashboard

### Observability stack

Our observability stack (`/observability`) consists of [Grafana](https://grafana.com/grafana/), [Mimir](https://grafana.com/oss/mimir/) (distributed), [Loki](https://grafana.com/logs/) (simple scalable) and [Tempo](https://grafana.com/traces/) (monolithic). Tempo will soon be switched to distributed while Loki will remain in simple scalable since it can already handle 100GB+/day of logs. We also include [Grafana Agents](https://grafana.com/docs/agent/latest/) (`/observability/ingest`) pre-configured for use with [Grafana Faro](https://github.com/grafana/faro). We use GCP for our buckets ([GCS](https://cloud.google.com/storage/)) and [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation) for connecting Kubernetes service accounts with GCP IAM service accounts.

Before continuing, please ensure that Workload Identity Federation has been configured on your cluster as it is not enabled by default at the time of writing: https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity

1. Update `/observability/setup-gcp.sh` with your `PROJECT_ID`. This script will create GCS buckets, IAM roles, IAM service accounts and IAM policy bindings. It requires that `gcloud` and `gsutil` are installed. Please read through the entire script before running
2. Create `grafana-auth.yaml` in `/observability` based on `grafana-auth.example.yaml` and edit as appropriate
3. Edit `grafana.yaml` changing the certificates and ingress routes as appropriate for your domain
4. Edit `mimir.prod.yaml` `loki.prod.yaml` and `tempo.prod.yaml` replacing the service account annotation of `PROJECT_ID_HERE` with your GCP project id
5. Install the stack with `kubectl apply -k observability`
6. If desired, you can use Grafana Faro with Grafana agents. Edit and install the ingest Grafana Agents with `kubectl apply -k observability/ingest`

### Kubernetes Dashboard

The [Kubernetes Dashboard](https://github.com/kubernetes/dashboard) is a web-based interface for your cluster. "It allows users to manage applications running in the cluster and troubleshoot them, as well as manage the cluster itself."

1. Update `/kube-dashboard/ingress.yaml` with your domain
2. Install the Kubernetes dashboard with `kubectl apply -k kube-dashboard`
3. Run `kube-dashboard/get-auth.sh` and follow the instructions to setup your Kubernetes config with a token for logging in
4. Go to https://kube.observability.speechify.dev and use your Kubernetes config (usually `~/.kube/config`) to login
