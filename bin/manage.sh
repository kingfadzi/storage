#!/bin/bash

# Define variables
MINIO_CONTAINER_NAME="minio"
LOCAL_STORAGE="$HOME/minio-data"
NETWORK_STORAGE="/mnt/f"  # Network storage (only if available)
DOCKER_IMAGE="minio-almalinux"

# Hardcoded MinIO Credentials
MINIO_ROOT_USER="admin"
MINIO_ROOT_PASSWORD="admin1234"

# Function to ensure the storage directories exist
check_storage_dirs() {
    if [ ! -d "$LOCAL_STORAGE" ]; then
        echo "Creating local MinIO storage directory at $LOCAL_STORAGE..."
        mkdir -p "$LOCAL_STORAGE"
    fi

    # Ensure MinIO has correct ownership
    chown -R "$(id -u):$(id -g)" "$LOCAL_STORAGE"

    # Check for network storage availability
    if [ ! -d "$NETWORK_STORAGE" ]; then
        echo "WARNING: Network storage ($NETWORK_STORAGE) not found! Proceeding without it..."
    fi
}

# Function to build the Docker image
build_image() {
    echo "Building MinIO Docker image..."
    docker build -t "$DOCKER_IMAGE" .
}

# Function to remove an existing MinIO container if it exists
remove_existing_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^$MINIO_CONTAINER_NAME$"; then
        echo "Removing existing MinIO container..."
        docker stop "$MINIO_CONTAINER_NAME" && docker rm "$MINIO_CONTAINER_NAME"
    fi
}

# Function to start the MinIO container
start_minio() {
    check_storage_dirs  # Ensure directories exist
    build_image  # Always build before starting
    remove_existing_container  # Ensure no conflicting container

    echo "Starting MinIO container..."

    if [ -d "$NETWORK_STORAGE" ]; then
        echo "Network storage detected. Using both local and network storage."
        CONTAINER_ID=$(docker run -d --name "$MINIO_CONTAINER_NAME" \
            -p 9000:9000 -p 9090:9090 \
            -e "MINIO_ROOT_USER=$MINIO_ROOT_USER" \
            -e "MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD" \
            -v "$LOCAL_STORAGE:/local_storage" \
            -v "$NETWORK_STORAGE:/network_storage" \
            --user "$(id -u):$(id -g)" \
            "$DOCKER_IMAGE")
    else
        echo "Network storage not found. Running MinIO with local storage only."
        CONTAINER_ID=$(docker run -d --name "$MINIO_CONTAINER_NAME" \
            -p 9000:9000 -p 9090:9090 \
            -e "MINIO_ROOT_USER=$MINIO_ROOT_USER" \
            -e "MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD" \
            -v "$LOCAL_STORAGE:/local_storage" \
            --user "$(id -u):$(id -g)" \
            "$DOCKER_IMAGE")
    fi

    # Wait a few seconds and check if the container is still running
    sleep 5
    if ! docker ps | grep -q "$MINIO_CONTAINER_NAME"; then
        echo "Error: MinIO failed to start! Check logs with:"
        echo "docker logs $MINIO_CONTAINER_NAME"
        exit 1
    fi

    echo "MinIO started successfully!"
    echo "Access MinIO Console: http://$(hostname -I | awk '{print $1}'):9090"
    echo "Access MinIO API: http://$(hostname -I | awk '{print $1}'):9000"
    echo "Login with Username: $MINIO_ROOT_USER and Password: $MINIO_ROOT_PASSWORD"
}

# Function to stop the MinIO container
stop_minio() {
    if docker ps --format '{{.Names}}' | grep -q "^$MINIO_CONTAINER_NAME$"; then
        echo "Stopping MinIO container..."
        docker stop "$MINIO_CONTAINER_NAME" && docker rm "$MINIO_CONTAINER_NAME"
        echo "MinIO container stopped."
    else
        echo "MinIO is not running."
    fi
}

# Function to restart the MinIO container
restart_minio() {
    stop_minio
    start_minio  # Includes build step
}

# Function to check MinIO status
status_minio() {
    if docker ps --format '{{.Names}}' | grep -q "^$MINIO_CONTAINER_NAME$"; then
        echo "MinIO is running!"
    else
        echo "MinIO is NOT running."
    fi
}

# Parse command-line arguments
case "$1" in
    start)
        start_minio
        ;;
    stop)
        stop_minio
        ;;
    restart)
        restart_minio
        ;;
    status)
        status_minio
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
