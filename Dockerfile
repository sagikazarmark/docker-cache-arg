ARG GO_VERSION=1.15
ARG FROM_IMAGE=scratch

FROM golang:${GO_VERSION}-alpine3.12 AS builder

# set up nsswitch.conf for Go's "netgo" implementation
# https://github.com/gliderlabs/docker-alpine/issues/367#issuecomment-424546457
RUN echo 'hosts: files dns' > /etc/nsswitch.conf.build

RUN apk add --update --no-cache bash ca-certificates make curl git mercurial tzdata

ENV GOFLAGS="-mod=readonly"
ARG GOPROXY

RUN mkdir -p /build
WORKDIR /build

COPY go.* /build/
RUN go mod download

ARG VERSION
ARG COMMIT_HASHH
ARG BUILD_DATEE

COPY . /build
RUN go build -o /build/hello


FROM ${FROM_IMAGE}

COPY --from=builder /build/hello /

CMD ["/hello"]
