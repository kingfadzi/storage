#!/bin/bash

# Define variables
CONTAINER_NAME="minio-nginx"  # Container name to reflect both MinIO & NGINX
LOCAL_STORAGE="$HOME/minio-data"  # Single storage mount
DOCKER_IMAGE="minio-nginx-almalinux"  # Docker image name

# Hardcoded MinIO Credentials
MINIO_ROOT_USER="admin"
MINIO_ROOT_PASSWORD="admin1234"

# Function to ensure the storage directory exists
check_storage_dirs() {
    if [ ! -d "$LOCAL_STORAGE" ]; then
        echo "Creating local MinIO storage directory at $LOCAL_STORAGE..."
        mkdir -p "$LOCAL_STORAGE"
    fi

    # Ensure correct ownership
    chown -R "$(id -u):$(id -g)" "$LOCAL_STORAGE"
}

# Function to build the Docker image
build_image() {
    echo "Building MinIO + NGINX Docker image..."
    docker build -t "$DOCKER_IMAGE" .
}

# Function to remove an existing container if it exists
remove_existing_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        echo "Removing existing container..."
        docker stop "$CONTAINER_NAME" && docker rm "$CONTAINER_NAME"
    fi
}

# Function to start the container
start_container() {
    check_storage_dirs  # Ensure directories exist
    build_image         # Always build before starting
    remove_existing_container  # Ensure no conflicting container

    echo "Starting MinIO + NGINX container..."

    CONTAINER_ID=$(docker run -d --name "$CONTAINER_NAME" \
        -p 8000:8000 -p 9000:9000 -p 9090:9090 \
        -e "MINIO_ROOT_USER=$MINIO_ROOT_USER" \
        -e "MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD" \
        -v "$LOCAL_STORAGE:/local_storage" \
        --user "$(id -u):$(id -g)" \
        "$DOCKER_IMAGE")

    # Wait a few seconds and check if the container is still running
    sleep 5
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        echo "Error: MinIO + NGINX failed to start! Check logs with:"
        echo "docker logs $CONTAINER_NAME"
        exit 1
    fi

    # Print access information
    echo "MinIO + NGINX started successfully!"
    echo "Access NGINX Proxy:  http://$(hostname -I | awk '{print $1}'):8000/"
    echo "Access MinIO API:    http://$(hostname -I | awk '{print $1}'):8000/minio/"
    echo "Access MinIO Console:http://$(hostname -I | awk '{print $1}'):8000/minio-console/"
    echo "   (Proxied through NGINX on port 8000)"
    echo
    echo "Direct MinIO ports (without NGINX proxy):"
    echo " - MinIO API:       http://$(hostname -I | awk '{print $1}'):9000"
    echo " - MinIO Console:   http://$(hostname -I | awk '{print $1}'):9090"
    echo
    echo "MinIO Login Username: $MINIO_ROOT_USER"
    echo "MinIO Login Password: $MINIO_ROOT_PASSWORD"
}

# Function to stop the container
stop_container() {
    if docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        echo "Stopping MinIO + NGINX container..."
        docker stop "$CONTAINER_NAME" && docker rm "$CONTAINER_NAME"
        echo "Container stopped."
    else
        echo "Container is not running."
    fi
}

# Function to restart the container
restart_container() {
    stop_container
    start_container  # Includes build step
}

# Function to check container status
status_container() {
    if docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        echo "MinIO + NGINX is running!"
    else
        echo "MinIO + NGINX is NOT running."
    fi
}

# Parse command-line arguments
case "$1" in
    start)
        start_container
        ;;
    stop)
        stop_container
        ;;
    restart)
        restart_container
        ;;
    status)
        status_container
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac