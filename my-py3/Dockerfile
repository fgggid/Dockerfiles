FROM alpine:latest

COPY repositories-aliyun /etc/apk/repositories

RUN mkdir -p ~/.pip && \
    echo [global] >> ~/.pip/pip.conf && \
    echo index-url = https://mirrors.aliyun.com/pypi/simple/ >> ~/.pip/pip.conf && \
    echo [install] >> ~/.pip/pip.conf && \
    echo trusted-host = mirrors.aliyun.com >> ~/.pip/pip.conf && \
    cat ~/.pip/pip.conf

RUN apk add --update --no-cache python3 && \
    python3 -m ensurepip && \
    rm -rf /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    rm -rf /root/.cache && \
    rm -rf /var/cache/apk/*

RUN cd /usr/bin && \
    ln -s python3 python && \
    ln -s pydoc3 pydoc && \
    ln -s idle3.7 idle

CMD ["python"]
