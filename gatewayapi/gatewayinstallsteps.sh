#!/usr/bin/env bash

set -e

echo "Installing Gateway API v1.3.0 (standard)..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

echo "Installing Gateway API v1.3.0 (experimental)..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/experimental-install.yaml

echo "Installing AWS Gateway API CRDs..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/refs/heads/main/config/crd/gateway/gateway-crds.yaml

echo "Done."