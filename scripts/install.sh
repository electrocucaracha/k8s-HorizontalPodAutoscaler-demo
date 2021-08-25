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
set -o errexit
set -o nounset
if [[ "${DEBUG:-false}" == "true" ]]; then
    set -o xtrace
    export PKG_DEBUG=true
fi

# Install dependencies
pkgs=""
for pkg in docker kind kubectl helm jq make; do
    if ! command -v "$pkg"; then
        pkgs+=" $pkg"
    fi
done
if [ -n "$pkgs" ]; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG=$pkgs bash
fi

# Provision a K8s cluster
if ! sudo kind get clusters | grep -q kind; then
    sudo kind create cluster --config=./scripts/kind-config.yml
    mkdir -p "$HOME/.kube"
    sudo cp /root/.kube/config "$HOME/.kube/config"
    sudo chown -R "$USER" "$HOME/.kube/"
fi

# Setup Horizontal Pod Autoscaler components
if ! helm repo list | grep -q prometheus-community; then
    helm repo add prometheus-community \
        https://prometheus-community.github.io/helm-charts
    helm repo update
fi
if ! helm ls | grep -q metric-collector; then
    helm upgrade --install metric-collector \
        prometheus-community/prometheus-operator --wait \
        -f ./deployments/operator.yml
fi
if ! helm ls | grep -q metric-apiserver; then
    helm upgrade --install metric-apiserver \
        prometheus-community/prometheus-adapter --wait \
        -f ./deployments/adapter.yml
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
