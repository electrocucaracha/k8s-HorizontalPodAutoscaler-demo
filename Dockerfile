FROM golang:1.15-alpine3.12 as build

WORKDIR /go/src/github.com/electrocucaracha/k8s-HorizontalPodAutoscaler-demo
ENV GO111MODULE "on"
ENV CGO_ENABLED "0"
ENV GOOS "linux"
ENV GOARCH "amd64"
ENV GOBIN=/bin

COPY go.mod go.sum ./
COPY ./internal/imports ./internal/imports
RUN go build ./internal/imports
COPY . .
RUN go build -v -o /bin ./...

FROM build as test
RUN go test -v ./...

FROM alpine:3.12
MAINTAINER Victor Morales <electrocucaracha@gmail.com>

ENV PORT "3000"

COPY --from=build /bin/cpustats /cpustats
COPY web/template/index.html web/template/

RUN apk add --no-cache tini
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/cpustats"]
