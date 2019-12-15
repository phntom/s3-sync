FROM alpine:3.10

ARG S3CMD_VERSION=2.0.2

RUN apk add --update \
        ca-certificates \
        curl \
        gnupg \
        inotify-tools \
        py-dateutil \
        py-magic \
        py-setuptools \
        python \
        sudo && \
    rm -rf /var/cache/apk/* && \
    curl -L https://github.com/s3tools/s3cmd/releases/download/v$S3CMD_VERSION/s3cmd-$S3CMD_VERSION.tar.gz | tar xzf - -C /tmp && \
    cd /tmp/s3cmd-$S3CMD_VERSION && \
    python setup.py install && \ 
    rm -rf /tmp/s3cmd-$S3CMD_VERSION 

COPY createuser startup watch push /usr/local/bin/

CMD watch
