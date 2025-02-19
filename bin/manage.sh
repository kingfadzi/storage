#!/bin/bash

# Define variables
MINIO_CONTAINER_NAME="minio"
LOCAL_STORAGE="$HOME/minio-data"  # Maps to /local_storage in the container
NETWORK_STORAGE="/mnt/f"          # Maps to /network_storage in the container
DOCKER_IMAGE="minio-almalinux"

# Function to ensure /mnt/f is mounted and accessible
check_network_drive() {
    if [ ! -d "$NETWORK_STORAGE" ]; then
        echo "Error: Network drive $NETWORK_STORAGE is not mounted!"
        exit 1
    else
        echo "Ensuring correct permissions on $NETWORK_STORAGE..."
        sudo chmod -R 777 "$NETWORK_STORAGE"
    fi
}

# Function to ensure the local storage directory exists
check_local_folder() {
    if [ ! -d "$LOCAL_STORAGE" ]; then
        echo "Creating local MinIO storage directory at $LOCAL_STORAGE..."
        mkdir -p "$LOCAL_STORAGE"
    fi
}

# Function to build the Docker image
build_image() {
    echo "Building MinIO Docker image..."
    docker build -t "$DOCKER_IMAGE" .
}

# Function to start the MinIO container
start_minio() {
    check_local_folder
    # check_network_drive
    build_image  # Always build before starting

    if docker ps --format '{{.Names}}' | grep -q "^$MINIO_CONTAINER_NAME$"; then
        echo "MinIO is already running!"
    else
        echo "Starting MinIO container..."
        docker run -d --name "$MINIO_CONTAINER_NAME" \
            -p 9000:9000 -p 9090:9090 \
            -e MINIO_ROOT_USER=admin \
            -e MINIO_ROOT_PASSWORD=admin \
            -v "$LOCAL_STORAGE:/local_storage" \
            -v "$NETWORK_STORAGE:/network_storage" \
            "$DOCKER_IMAGE"
        echo "MinIO started successfully!"
        echo "Access MinIO Console: http://localhost:9090"
        echo "Access MinIO API: http://localhost:9000"
    fi
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
