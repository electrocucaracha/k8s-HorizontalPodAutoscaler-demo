#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o pipefail
set -o xtrace
set -o errexit
set -o nounset

# Install dependencies
pkgs=""
for pkg in podman kind kubectl helm jq make; do
    if ! command -v "$pkg"; then
        pkgs+=" $pkg"
    fi
done
if [ -n "$pkgs" ]; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG=$pkgs bash
fi

# Create website image
if [ -z "$(podman images electrocucaracha/web:1.0 -q)" ] && [ ! -f /tmp/web.tgz ]; then
    make tarball
fi

# Deploy Kubernetes cluster
if ! sudo kind get clusters | grep -q kind; then
    sudo podman pull kindest/node:v1.19.1
    cat << EOF | sudo kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  kubeProxyMode: "ipvs"
kubeadmConfigPatches:
- |
  kind: ClusterConfiguration
  metadata:
    name: config
  controllerManager:
    extraArgs:
      # Reduce the period for which autoscaler will look backwards and not scale down
      horizontal-pod-autoscaler-downscale-stabilization: "15s"
nodes:
  - role: control-plane
    image: kindest/node:v1.19.1
EOF
    mkdir -p "$HOME/.kube"
    sudo cp /root/.kube/config "$HOME/.kube/config"
    sudo chown -R "$USER" "$HOME/.kube/"
    sudo kind load image-archive /tmp/web.tgz
    chmod 600 "$HOME/.kube/config"
fi

# Setup Horizontal Pod Autoscaler components
if ! heml repo list | grep -q prometheus-community; then
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
fi
if ! helm ls | grep -q metric-collector; then
    helm upgrade --install metric-collector prometheus-community/prometheus-operator --wait -f operator.yml
fi
if ! helm ls | grep -q metric-apiserver; then
    helm upgrade --install metric-apiserver prometheus-community/prometheus-adapter --wait -f adapter.yml
fi
cat << EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: cpustats-monitor
spec:
  endpoints:
  - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    interval: 5s
    port: web
  selector:
    matchLabels:
      app: frontend
EOF

# Deploy application
kubectl apply -f deployments/
kubectl rollout status deployment cpustats

set +o xtrace
attempt_counter=0
max_attempts=12
until kubectl get --raw="/apis/custom.metrics.k8s.io/v1beta1" | jq -r '.resources[].name' | grep -q pods/processed_requests_per_second; do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
        echo "Max attempts reached"
        exit 1
    fi
    sleep 10
    attempt_counter=$((attempt_counter+1))
done

# Run Traffic emulator
kubectl apply -f tests/
until [ "$(kubectl get deployments/cpustats  -o jsonpath='{.spec.replicas}')" -gt "1" ]; do
    sleep 5
done
for i in $(seq 5); do
    echo "--- $i iteration ---"
    for pod in $(kubectl get po -l app=frontend -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
        reqs_per_sec="$(kubectl get --raw="/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/processed_requests_per_second?pod=$pod" | jq -r ".items[0].value")"
        echo "${pod} pod has $(( ${reqs_per_sec%m} / 1000)) requests per second"
    done
    sleep 2
done
