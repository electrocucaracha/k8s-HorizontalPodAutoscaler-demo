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
if [[ ${DEBUG:-false} == "true" ]]; then
    set -o xtrace
fi

function print_stats {
    set +o xtrace
    printf "CPU usage: "
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage " %"}'
    printf "Memory free(Kb):"
    awk -v low="$(grep low /proc/zoneinfo | awk '{k+=$2}END{print k}')" '{a[$1]=$2}  END{ print a["MemFree:"]+a["Active(file):"]+a["Inactive(file):"]+a["SReclaimable:"]-(12*low);}' /proc/meminfo
    if command -v kubectl; then
        for namespace in default ingress-nginx; do
            echo "Kubernetes Events ($namespace):"
            kubectl alpha events -n "$namespace"
            echo "Kubernetes Resources ($namespace):"
            kubectl get all -n "$namespace" -o wide
        done
        echo "Kubernetes Pods:"
        kubectl describe pods
        echo "Kubernetes Nodes:"
        kubectl describe nodes
    fi
    exit 1
}

trap print_stats ERR

# Create website image
if [ -z "$(sudo docker images electrocucaracha/web:1.0 -q)" ]; then
    make build
fi
sudo kind load docker-image electrocucaracha/web:1.0

# Deploy application
kubectl apply -f ./deployments/website.yml
kubectl rollout status deployment cpustats
