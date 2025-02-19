# Use AlmaLinux as the base image
FROM almalinux:latest

# Update the system and clean up (minimal installation)
RUN yum update -y && yum clean all

# Create MinIO user and necessary directories
RUN useradd -r minio-user \
    && mkdir -p /local_storage \
    && chown -R minio-user:minio-user /local_storage

# Copy the MinIO binary from the local filesystem (Ensure it's in the build context)
COPY minio /usr/local/bin/minio

# Set executable permissions
RUN chmod +x /usr/local/bin/minio

# Expose MinIO default ports
EXPOSE 9000 9090

# Switch to MinIO user
USER minio-user

# Start MinIO with local storage only
ENTRYPOINT ["/usr/local/bin/minio"]
CMD ["server", "/local_storage", "--address", "0.0.0.0:9000", "--console-address", "0.0.0.0:9090"]
