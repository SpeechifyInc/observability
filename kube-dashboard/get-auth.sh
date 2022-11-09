#!/bin/bash
set -e

kubectl config get-users

echo
echo "-----------"
echo "Enter the user to set the authentication for: "
read kubernetes_user

echo
echo "Installing token to kube config..."
TOKEN=$(kubectl -n kube-system describe secret admin-user-token | awk '$1=="token:"{print $2}')
kubectl config set-credentials $kubernetes_user --token="${TOKEN}"

echo "Kubernetes dashboard and authentication setup successfully! Use your kube config (usually ~/.kube/config) to login"
