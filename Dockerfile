FROM alpine:3.10

RUN apk add --update \
        ca-certificates \
        curl \
        gnupg \
        inotify-tools \
        python \
        py-dateutil \
        py-setuptools \
        py-magic && \
    rm -rf /var/cache/apk/* && \
    curl -L https://github.com/s3tools/s3cmd/releases/download/v2.0.2/s3cmd-2.0.2.tar.gz | tar xzf - -C /tmp && \
    cd /tmp/s3cmd-2.0.2 && \
    python setup.py install && \ 
    rm -rf /tmp/s3cmd-2.0.2 

COPY startup watch push /usr/local/bin/

CMD watch
