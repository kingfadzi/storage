FROM almalinux:latest

RUN yum update -y && yum install -y \
    python3 \
    python3-pip \
    socat \
    nginx \
&& yum clean all

RUN pip3 install supervisor

RUN mkdir -p /var/log/supervisor && chmod -R 777 /var/log/supervisor

RUN mkdir -p /local_storage

COPY minio /usr/local/bin/minio

RUN chmod +x /usr/local/bin/minio

COPY nginx.conf /etc/nginx/nginx.conf

COPY supervisord.conf /etc/supervisord.conf

EXPOSE 8000 9000 9090

USER root

CMD ["supervisord", "-c", "/etc/supervisord.conf"]

#FROM redhat/ubi8:latest
#RUN yum update -y && yum install -y python3
#EXPOSE 8080
#CMD ["python3", "-m", "http.server", "8080", "--bind", "0.0.0.0"]

#docker build -t rhel8-port-test .
#docker run -d -p 8080:8080 rhel8-port-test
#Test-NetConnection -ComputerName localhost -Port 8080


