#!/bin/bash
set -e

# Binds the kubernetes service account to a GCP service account
# For getting access to GCP APIs
# !!! This requires that workload federation is enabled and the full docs can be found here:
# https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity

PROJECT_ID=YOUR_PROJECT_ID_HERE
K8S_NAMESPACE=observability

# Creat buckets
create_bucket () {
  BUCKET_NAME=$1
  gcloud storage buckets create gs://$BUCKET_NAME --location us-east1 --uniform-bucket-level-access --public-access-prevention --project $PROJECT_ID
}

create_bucket observability-mimir-alert-manager
create_bucket observability-mimir-blocks
create_bucket observability-mimir-ruler

create_bucket observability-loki-chunks
create_bucket observability-loki-admin
create_bucket observability-loki-ruler

create_bucket observability-tempo

# Create role for Tempo
create_role() {
  TITLE=$1
  PERMISSIONS=$2
  gcloud iam roles create $TITLE --project=$PROJECT_ID \
    --title $TITLE \
    --permissions $PERMISSIONS \
    --stage GA
}

create_role ObservabilityMimir storage.objects.create,storage.objects.delete,storage.objects.get,storage.objects.list
create_role ObservabilityLoki storage.objects.create,storage.objects.delete,storage.objects.get,storage.objects.list
create_role ObservabilityTempo storage.objects.create,storage.objects.delete,storage.objects.get,storage.buckets.get

# Create service accounts
create_service_account () {
  GCP_SA_NAME=$1
  gcloud iam service-accounts create $GCP_SA_NAME --project $PROJECT_ID
}

create_service_account observability-mimir
create_service_account observability-loki
create_service_account observability-tempo

# Grant access to buckets
add_bucket_access () {
  GCP_SA_NAME=$1
  BUCKET_NAME=$2
  ROLE=$3
  gsutil iam ch \
    serviceAccount:$GCP_SA_NAME@$PROJECT_ID.iam.gserviceaccount.com:projects/$PROJECT_ID/roles/$ROLE \
    gs://$BUCKET_NAME
}

add_bucket_access observability-mimir observability-mimir-alert-manager ObservabilityMimir
add_bucket_access observability-mimir observability-mimir-blocks ObservabilityMimir
add_bucket_access observability-mimir observability-mimir-ruler ObservabilityMimir

add_bucket_access observability-loki observability-loki-chunks ObservabilityLoki
add_bucket_access observability-loki observability-loki-admin ObservabilityLoki
add_bucket_access observability-loki observability-loki-ruler ObservabilityLoki

add_bucket_access observability-tempo observability-tempo ObservabilityTempo

# Bind Kubernetes and GCP service accounts together
apply_iam_policy_binding () {
  GCP_SA_NAME=$1
  K8S_SA_NAME=$2
  gcloud iam service-accounts add-iam-policy-binding $GCP_SA_NAME@$PROJECT_ID.iam.gserviceaccount.com \
      --role roles/iam.workloadIdentityUser \
      --member "serviceAccount:$PROJECT_ID.svc.id.goog[$K8S_NAMESPACE/$K8S_SA_NAME]" \
      --project $PROJECT_ID
}

apply_iam_policy_binding "observability-mimir" "mimir"
apply_iam_policy_binding "observability-loki" "loki"
apply_iam_policy_binding "observability-tempo" "tempo"
