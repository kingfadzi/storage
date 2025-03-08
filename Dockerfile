FROM almalinux:latest

ARG MINIO_SERVER=localhost

RUN yum update -y && yum install -y \
    python3 \
    python3-pip \
    socat \
    nginx \
&& yum clean all

RUN pip3 install supervisor

RUN mkdir -p /var/log/supervisor && chmod -R 777 /var/log/supervisor

RUN mkdir -p /local_storage

ARG FQDN=your-default-fqdn

RUN curl -fL "http://${MINIO_SERVER}:9000/blobs/minio" -o /usr/local/bin/minio && \
    chmod +x /usr/local/bin/minio \

COPY nginx.conf /etc/nginx/nginx.conf

COPY supervisord.conf /etc/supervisord.conf

EXPOSE 8000 9000 9090

USER root

CMD ["supervisord", "-c", "/etc/supervisord.conf"]
