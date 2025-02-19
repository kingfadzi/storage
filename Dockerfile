# Use AlmaLinux as the base image
FROM almalinux:latest

# Set environment variables for MinIO credentials
ENV MINIO_ACCESS_KEY="admin"
ENV MINIO_SECRET_KEY="admin"

# Update the system and clean up (no extra packages installed)
RUN yum update -y && yum clean all

# Create MinIO user and necessary directories
RUN useradd -r minio-user \
    && mkdir -p /local_storage /network_storage \
    && chown -R minio-user:minio-user /local_storage /network_storage

# Copy the MinIO binary from the local filesystem (Ensure it's in the build context)
COPY minio /usr/local/bin/minio

# Set executable permissions
RUN chmod +x /usr/local/bin/minio

# Expose MinIO default ports
EXPOSE 9000 9090

# Switch to MinIO user
USER minio-user

# Start MinIO with renamed storage directories
ENTRYPOINT ["/usr/local/bin/minio"]
CMD ["server", "/local_storage", "/network_storage", "--console-address", ":9090"]
