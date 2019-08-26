FROM py3:latest

RUN apk add --virtual build-dependencies \
    build-base \
    gcc \
    libffi-dev \
    python3-dev && \
    rm -rf /var/cache/apk/*

RUN pip install --no-cache-dir --upgrade --ignore-installed \
    devpi-server && \
    rm -rf /root/.cache

COPY entrypoint.sh /

VOLUME /data

WORKDIR /data

ENTRYPOINT ["/entrypoint.sh"]

CMD ["devpi"]
