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

function print_stats {
    set +o xtrace
    printf "CPU usage: "
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage " %"}'
    printf "Memory free(Kb):"
    awk -v low="$(grep low /proc/zoneinfo | awk '{k+=$2}END{print k}')" '{a[$1]=$2}  END{ print a["MemFree:"]+a["Active(file):"]+a["Inactive(file):"]+a["SReclaimable:"]-(12*low);}' /proc/meminfo
    if command -v kubectl; then
        for namespace in default ingress-nginx; do
            echo "Kubernetes Events ($namespace):"
            kubectl get events -n "$namespace" --sort-by=".metadata.managedFields[0].time"
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

attempt_counter=0
max_attempts=12
until kubectl get --raw="/apis/custom.metrics.k8s.io/v1beta1" | jq -r '.resources[].name' | grep -q pods/processed_requests_per_second; do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
        echo "Max attempts reached"
        exit 1
    fi
    attempt_counter=$((attempt_counter+1))
    sleep $((attempt_counter*2))
done

# Run Traffic emulator
kubectl apply -f tests/
trap 'kubectl delete -f tests/' EXIT

# Wait for scaling up
attempt_counter=0
until [ "$(kubectl get deployments/cpustats  -o jsonpath='{.spec.replicas}')" -gt "1" ]; do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
        echo "Max attempts reached"
        exit 1
    fi
    attempt_counter=$((attempt_counter+1))
    sleep $((attempt_counter*1))
done

for i in $(seq 10); do
    echo "--- $i iteration ---"
    for pod in $(kubectl get po -l app=frontend -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
        reqs_per_sec="$(kubectl get --raw="/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/processed_requests_per_second?pod=$pod" | jq -r ".items[0].value")"
        echo "${pod} pod has $(( ${reqs_per_sec%m} / 1000)) requests per second"
    done
    sleep 3
done

echo "CPU stats - Replicas $(kubectl get deployments/cpustats  -o jsonpath='{.spec.replicas}')"
