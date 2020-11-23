# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2020
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

test:
	@go test -v ./...
run:
	@go run cmd/cpustats/main.go
docker-test:
	@docker run --rm $$(docker build -q --target test .)
docker-run:
	@docker run --rm -p 3000:3000 $$(docker build -q .)
docker-prune:
	@docker image prune --force
e2e-test:
	@vagrant up
