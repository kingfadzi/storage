# Use AlmaLinux as the base image
FROM almalinux:latest

# Update system and install required packages
RUN yum update -y && yum install -y \
python3 \
python3-pip \
nginx \
&& yum clean all

# Install Supervisor using pip
RUN pip3 install supervisor

# Create Supervisor log directory and set permissions
RUN mkdir -p /var/log/supervisor && chmod -R 777 /var/log/supervisor

# Create MinIO user and necessary directories
RUN useradd -r minio-user \
&& mkdir -p /local_storage \
&& chown -R minio-user:minio-user /local_storage

# Copy MinIO binary (ensure it's in the build context)
COPY minio /usr/local/bin/minio
RUN chmod +x /usr/local/bin/minio

# Copy your custom NGINX config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy Supervisor config
COPY supervisord.conf /etc/supervisord.conf

# Expose ports for NGINX (8000), MinIO (9000), and MinIO Console (9090)
EXPOSE 8000 9000 9090

# Start Supervisor to manage both processes
CMD ["supervisord", "-c", "/etc/supervisord.conf"]