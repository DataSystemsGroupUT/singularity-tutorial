FROM golang:1.17.5-alpine as builder

WORKDIR $GOPATH/src/github.com/apptainer
RUN apk add --no-cache gawk gcc git libc-dev linux-headers libressl-dev libuuid libseccomp-dev make util-linux-dev bash

RUN mkdir /usr/local/apptainer \
    && git clone https://github.com/apptainer/apptainer.git \
    && cd apptainer \
    && git checkout v1.1.8 \
    && ./mconfig -p /usr/local/apptainer --without-suid \
    && cd builddir \
    && make \
    && make install

FROM alpine:3.18
COPY --from=builder /usr/local/apptainer /usr/local/apptainer
ENV PATH="/usr/local/apptainer/bin:$PATH" \
    APPTAINER_TMPDIR="/tmp-apptainer"
RUN apk add --no-cache ca-certificates libseccomp squashfs-tools tzdata perl debootstrap \
    && mkdir -p $APPTAINER_TMPDIR \
    && cp /usr/share/zoneinfo/UTC /etc/localtime \
    && apk del tzdata \
    && rm -rf /tmp/* /var/cache/apk/*

WORKDIR /material

ENTRYPOINT ["/bin/sh"]
