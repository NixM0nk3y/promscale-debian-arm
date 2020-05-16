#
#
#

FROM arm32v7/debian:buster

LABEL maintainer="Nick Gregory <docker@openenterprise.co.uk>"

ARG GOLANG_VERSION="1.14.2"
ARG GOLANG_SHA256="eb4550ba741506c2a4057ea4d3a5ad7ed5a887de67c7232f1e4795464361c83c"

ARG TIMESCALE_PROMETHEUS_VERSION="master"

# basic build infra
RUN apt-get -y update \
    && apt-get -y dist-upgrade \
    && apt-get -y install curl build-essential cmake sudo wget git-core autoconf automake pkg-config quilt \
    && apt-get -y install ruby ruby-dev rubygems \
    && gem install --no-document fpm

RUN cd /tmp \
    && echo "==> Downloading Golang..." \
    && curl -fSL  https://dl.google.com/go/go${GOLANG_VERSION}.linux-armv6l.tar.gz -o go${GOLANG_VERSION}.linux-armv6l.tar.gz \
    && sha256sum go${GOLANG_VERSION}.linux-armv6l.tar.gz \
    && echo "${GOLANG_SHA256}  go${GOLANG_VERSION}.linux-armv6l.tar.gz" | sha256sum -c - \
    && tar -C /usr/local -xzf /tmp/go${GOLANG_VERSION}.linux-armv6l.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

# package build
RUN cd /tmp \ 
    && git clone https://github.com/timescale/timescale-prometheus.git \
    && cd timescale-prometheus \
    && git checkout ${TIMESCALE_PROMETHEUS_VERSION} \
    && go mod download \
    && CGO_ENABLED=0 go build -v -a --ldflags '-w' -o /tmp/timescale-prometheus-${TIMESCALE_PROMETHEUS_VERSION} ./cmd/timescale-prometheus

# extension needs PG12
#RUN apt-get -y install postgresql-server-dev-11 libssl-dev
#RUN cd /tmp/timescale-prometheus/extension \
#    && make package

# package install
RUN cd /tmp \
    && install -D -m 0755 ./timescale-prometheus-${TIMESCALE_PROMETHEUS_VERSION} /install/opt/timescale-prometheus/timescale-prometheus \
    && fpm -s dir -t deb -C /install --name timescale-prometheus --version 0.1 --iteration 1 \
       --description "Use TimescaleDB as a compressed, long-term store for Prometheus time-series metrics"

STOPSIGNAL SIGTERM
