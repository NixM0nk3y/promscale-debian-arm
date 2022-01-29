#
#
#

FROM debian:buster

LABEL maintainer="Nick Gregory <docker@openenterprise.co.uk>"

ARG GOLANG_VERSION="1.17.6"
ARG GOLANG_SHA256="82c1a033cce9bc1b47073fd6285233133040f0378439f3c4659fe77cc534622a"

ARG PROMSCALE_VERSION="0.8.0"

# basic build infra
RUN apt-get -y update \
    && apt-get -y dist-upgrade \
    && apt-get -y install curl build-essential cmake sudo wget git-core autoconf automake pkg-config quilt \
    && apt-get -y install ruby ruby-dev rubygems \
    && gem install --no-document fpm

RUN cd /tmp \
    && echo "==> Downloading Golang..." \
    && curl -fSL  https://go.dev/dl/go${GOLANG_VERSION}.linux-arm64.tar.gz -o go${GOLANG_VERSION}.linux-arm64.tar.gz \
    && sha256sum go${GOLANG_VERSION}.linux-arm64.tar.gz \
    && echo "${GOLANG_SHA256}  go${GOLANG_VERSION}.linux-arm64.tar.gz" | sha256sum -c - \
    && tar -C /usr/local -xzf /tmp/go${GOLANG_VERSION}.linux-arm64.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

# package build
RUN cd /tmp \ 
    && git clone https://github.com/timescale/promscale.git \
    && cd promscale \
    && git checkout ${PROMSCALE_VERSION} \
    && cd cmd/promscale \
    && go install \
    && go build ./...

# extension needs PG12
#RUN apt-get -y install postgresql-server-dev-11 libssl-dev
#RUN cd /tmp/timescale-prometheus/extension \
#    && make package

# package install
RUN cd /tmp \
    && install -D -m 0755 ./promscale/cmd/promscale/promscale /install/opt/promscale/promscale \
    && fpm -s dir -t deb -C /install --name promscale --version 1 --iteration ${PROMSCALE_VERSION} \
       --description "Use TimescaleDB as a compressed, long-term store for Prometheus time-series metrics"

STOPSIGNAL SIGTERM
