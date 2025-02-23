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

# Create a directory for Supervisor logs and set permissions
RUN mkdir -p /var/log/supervisor && chmod -R 777 /var/log/supervisor

# Create a MinIO user and storage directory
RUN useradd -r minio-user \
&& mkdir -p /local_storage \
&& chown -R minio-user:minio-user /local_storage

# Copy the MinIO binary into the image, set it executable, and change ownership
COPY minio /usr/local/bin/minio
RUN chmod +x /usr/local/bin/minio && chown minio-user:minio-user /usr/local/bin/minio

# Copy the custom NGINX configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy the Supervisor configuration
COPY supervisord.conf /etc/supervisord.conf

# Expose the necessary ports:
# - 8000 for NGINX (reverse proxy)
# - 9000 for MinIO API
# - 9090 for MinIO Console
EXPOSE 8000 9000 9090

# Use Supervisor to run both MinIO and NGINX
CMD ["supervisord", "-c", "/etc/supervisord.conf"]