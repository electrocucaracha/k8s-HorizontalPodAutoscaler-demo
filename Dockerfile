FROM golang:1.17-alpine3.14 as build

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

FROM alpine:3.14

ENV PORT "3000"

WORKDIR /opt/cpustats
COPY --from=build /bin/cpustats ./server
COPY web/template/index.html web/template/

RUN apk add --no-cache tini=0.19.0-r0
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["./server"]
