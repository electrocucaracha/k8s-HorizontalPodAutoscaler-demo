FROM golang:1.15-alpine3.12 as builder

WORKDIR /go/src/github.com/electrocucaracha/k8s-HorizontalPodAutoscaler-demo
COPY demo/ .

ENV GO111MODULE "on"
ENV CGO_ENABLED "0"
ENV GOOS "linux"
ENV GOARCH "amd64"

RUN go build -v -o /bin/demo_server ./...

FROM alpine:3.12
MAINTAINER Victor Morales <electrocucaracha@gmail.com>

ENV PORT "3000"

COPY --from=builder /bin/demo_server /demo_server
COPY demo/index.html /

ENTRYPOINT ["/demo_server"]
