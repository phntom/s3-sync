FROM alpine

ARG S3CMD_VERSION=2.1.0

RUN apk add --update --no-cache \
        ca-certificates \
        curl \
        gnupg \
        inotify-tools \
        py-dateutil \
        py-magic \
        py-setuptools \
        python3 \
        sudo

RUN curl -L https://github.com/s3tools/s3cmd/releases/download/v$S3CMD_VERSION/s3cmd-$S3CMD_VERSION.tar.gz | tar xzf - -C /tmp && \
    cd /tmp/s3cmd-$S3CMD_VERSION && \
    python3 setup.py install && \
    rm -rf /tmp/s3cmd-$S3CMD_VERSION

COPY createuser startup watch push /usr/local/bin/

COPY .s3cfg /root/

CMD watch
