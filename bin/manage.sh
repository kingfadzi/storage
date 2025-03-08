#!/bin/bash
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 {start|stop|restart|status}"
  exit 1
fi

CONTAINER_NAME="storage"
LOCAL_STORAGE="$(pwd)/storage"
DOCKER_IMAGE="storage"

check_storage_dirs() {
  if [ ! -d "$LOCAL_STORAGE" ]; then
    echo "Creating local storage directory at $LOCAL_STORAGE..."
    mkdir -p "$LOCAL_STORAGE"
  fi
}

build_image() {
  echo "Building storage Docker image..."
  docker build -t "$DOCKER_IMAGE" .
}

remove_existing_container() {
  if docker ps -a --format "{{.Names}}" | grep -iq "$CONTAINER_NAME"; then
    echo "Removing existing container..."
    docker stop "$CONTAINER_NAME" > /dev/null 2>&1
    docker rm "$CONTAINER_NAME"
  fi
}

wait_for_container() {
  counter=0
  max_wait=30
  while true; do
    if docker ps --format "{{.Names}}" | grep -iq "$CONTAINER_NAME"; then
      echo "storage container started successfully!"
      break
    fi
    ((counter++))
    if [ "$counter" -ge "$max_wait" ]; then
      echo "Error: storage container failed to start after $max_wait seconds! Check logs with:"
      echo "docker logs $CONTAINER_NAME"
      exit 1
    fi
    sleep 1
  done
}

start_container() {
  check_storage_dirs
  build_image
  remove_existing_container
  echo "Starting storage container..."
  CONTAINER_ID=$(docker run -d --name "$CONTAINER_NAME" -p 8000:8000 -p 9000:9000 -p 9090:9090 -p 3000:3000 -p 8099:8099 -p 5432:5432 -v storage_volume:/local_storage "$DOCKER_IMAGE")
  wait_for_container
}

stop_container() {
  if docker ps -a --format "{{.Names}}" | grep -iq "$CONTAINER_NAME"; then
    echo "Stopping storage container..."
    docker stop "$CONTAINER_NAME" > /dev/null 2>&1
    docker rm "$CONTAINER_NAME"
    echo "Container stopped and removed."
  else
    echo "Container does not exist."
  fi
}

restart_container() {
  stop_container
  start_container
}

status_container() {
  if docker ps -a --format "{{.Names}}" | grep -iq "$CONTAINER_NAME"; then
    echo "storage container exists."
    if docker ps --format "{{.Names}}" | grep -iq "$CONTAINER_NAME"; then
      echo "storage container is running."
    else
      echo "storage container is not running."
    fi
  else
    echo "Container does not exist."
  fi
}

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
