FROM golang:1.15.7-alpine3.13 as builder

WORKDIR $GOPATH/src/github.com/sylabs
RUN apk add --no-cache gawk gcc git libc-dev linux-headers libressl-dev libuuid libseccomp-dev make util-linux-dev

RUN git clone https://github.com/sylabs/singularity.git \
    && cd singularity \
    && git checkout v3.8.0 \
    && ./mconfig -p /usr/local/singularity \
    && cd builddir \
    && make \
    && make install

FROM alpine:3.13
COPY --from=builder /usr/local/singularity /usr/local/singularity
ENV PATH="/usr/local/singularity/bin:$PATH" \
    SINGULARITY_TMPDIR="/tmp-singularity"
RUN apk add --no-cache ca-certificates libseccomp squashfs-tools tzdata perl debootstrap \
    && mkdir -p $SINGULARITY_TMPDIR \
    && cp /usr/share/zoneinfo/UTC /etc/localtime \
    && apk del tzdata \
    && rm -rf /tmp/* /var/cache/apk/*

WORKDIR /material

ENTRYPOINT ["/bin/sh"]
