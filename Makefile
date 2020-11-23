# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2020
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

DOCKER ?= $(shell which docker 2> /dev/null || which podman 2> /dev/null || echo docker)

test:
	@go test -v ./...
run:
	@go run cmd/cpustats/main.go
build:
	$(DOCKER) build -t electrocucaracha/web:1.0 .
	$(DOCKER) image prune --force
tarball: build
	@rm -f /tmp/web.tgz
	$(DOCKER) save --output /tmp/web.tgz --compress electrocucaracha/web:1.0
integration-test:
	$(DOCKER) run --rm $$($(DOCKER) build -q --target test .)
container-run:
	$(DOCKER) run --rm -p 3000:3000 $$($(DOCKER) build -q .)
system-test:
	@vagrant up
