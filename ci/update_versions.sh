#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2025
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o pipefail
set -o errexit
set -o nounset

last_version=$(curl -sL https://registry.hub.docker.com/v2/repositories/kindest/node/tags | python -c 'import json,sys,re;versions=[obj["name"][1:] for obj in json.load(sys.stdin)["results"] if re.match("^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$",obj["name"])];print("\n".join(versions))' | uniq | sort -rn | head -n 1)

trap "make fmt" EXIT

cat <<EOT >scripts/kind-config.yml
---
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2021-$(date +"%Y")
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

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
    image: kindest/node:v$last_version
    extraPortMappings:
      - containerPort: 30001
        hostPort: 9001
EOT

if command -v go >/dev/null; then
    rm go.*
    go mod init github.com/electrocucaracha/k8s-HorizontalPodAutoscaler-demo
    go mod tidy -go="$(curl -sL https://golang.org/VERSION?m=text | sed -n 's/go//;s/\..$//;1p')"
    GOPATH=$(go env GOPATH)
    if [ ! -f "$GOPATH/bin/cyclonedx-gomod" ]; then
        go install github.com/CycloneDX/cyclonedx-gomod/cmd/cyclonedx-gomod@latest
    fi
    "$GOPATH/bin/cyclonedx-gomod" mod -licenses -json -output mod_k8s-HorizontalPodAutoscaler-demo.bom.json
fi

# Update GitHub Action commit hashes
gh_actions=$(grep -r "uses: [a-zA-Z\-]*/[\_a-z\-]*@" .github/ | sed 's/@.*//' | awk -F ': ' '{ print $3 }' | sort -u)
for action in $gh_actions; do
    commit_hash=$(git ls-remote "https://github.com/$action" | grep 'refs/tags/[v]\?[0-9][0-9\.]*$' | sed 's|refs/tags/[vV]\?[\.]\?||g' | sort -u -k2 -V | tail -1 | awk '{ printf "%s # %s\n",$1,$2 }')
    # shellcheck disable=SC2267
    grep -ElRZ "uses: $action@" .github/ | xargs -0 -l sed -i -e "s|uses: $action@.*|uses: $action@$commit_hash|g"
done
