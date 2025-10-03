#
# docker build --pull -t phntom/s3-sync --squash . && docker push docker.io/phntom/s3-sync
#
ARG ALPINE_VERSION=3.20
ARG S3CMD_VERSION=2.4.0
ARG S3CMD_SHA256=6b567521be1c151323f2059c8feec85ded96b6f184ff80535837fea33798b40b

# Builder stage
FROM alpine:${ALPINE_VERSION} as builder

ARG S3CMD_VERSION
ARG S3CMD_SHA256

RUN apk add --no-cache \
    curl \
    python3

RUN curl -L "https://github.com/s3tools/s3cmd/releases/download/v${S3CMD_VERSION}/s3cmd-${S3CMD_VERSION}.tar.gz" -o "/tmp/s3cmd.tar.gz" && \
    echo "${S3CMD_SHA256}  /tmp/s3cmd.tar.gz" | sha256sum -c -

RUN tar xzf /tmp/s3cmd.tar.gz -C /tmp && \
    cd "/tmp/s3cmd-${S3CMD_VERSION}" && \
    python3 setup.py install --prefix=/install

# Final stage
FROM alpine:${ALPINE_VERSION}

LABEL org.opencontainers.image.title="s3-sync" \
      org.opencontainers.image.description="A Kubernetes sidecar to sync a container's data volume with an S3 bucket." \
      org.opencontainers.image.source="https://github.com/phntom/s3-sync"

RUN apk add --no-cache \
    ca-certificates \
    inotify-tools \
    python3 \
    py3-dateutil \
    py3-magic \
    sudo

COPY --from=builder /install/ /usr/
COPY --from=joelnb/dumb-init-alpine:latest /usr/bin/dumb-init /usr/bin/dumb-init

COPY .s3cfg /
COPY createuser startup watch push cfg /usr/local/bin/

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["watch"]