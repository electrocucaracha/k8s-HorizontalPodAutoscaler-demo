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
if [ "${DEBUG:-false}" == "true" ]; then
    set -o xtrace
fi

local_url="http://127.0.0.1:3000"
metrics_url="$local_url/metrics"
script_path=$(cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)

function info {
    _print_msg "INFO" "$1"
}

function error {
    _print_msg "ERROR" "$1"
    exit 1
}

function _print_msg {
    echo "$(date +%H:%M:%S) - $1: $2"
}

function assert_non_empty {
    local input=$1

    if [ -z "$input" ]; then
        error "Empty input value"
    fi
}

function assert_equals {
    local input=$1
    local expected=$2

    if [ "$input" != "$expected" ]; then
        error "Go $input expeted $expected"
    fi
}

# Setup
if [ -z "$(docker ps --filter "name=cpustats" --format "{{.Names}}")" ] ; then
    info "Starting website container..."
    make container-start --directory="$(dirname "$script_path")" > /dev/null
fi
docker logs cpustats | grep -e "Starting server at" > /dev/null
curl -f -sLI "$metrics_url" > /dev/null
assert_non_empty "$(curl -s "$metrics_url")"
curl -s "$metrics_url" | grep -e "^processed_requests_total" > /dev/null

# Test cases
info "Validate that processed_requests_total are increased"
assert_equals "$(curl -s "$metrics_url" | grep "^processed_requests_total" | awk '{ print $2}')" "0"
if [ "${DEBUG:-false}" == "true" ]; then
    curl -s "$local_url"
else
    curl -s "$local_url" > /dev/null
fi
assert_equals "$(curl -s "$metrics_url" | grep "^processed_requests_total" | awk '{ print $2}')" "1"

# Teardown
info "Destroying website container"
make container-stop --directory="$(dirname "$script_path")"/ > /dev/null
