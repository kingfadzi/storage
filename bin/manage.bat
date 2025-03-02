@echo off
setlocal enabledelayedexpansion

set "CONTAINER_NAME=minio-nginx"
set "LOCAL_STORAGE=%USERPROFILE%\minio-data"
set "DOCKER_IMAGE=minio-nginx-almalinux"

set "MINIO_ROOT_USER=admin"
set "MINIO_ROOT_PASSWORD=admin1234"

:check_storage_dirs
if not exist "%LOCAL_STORAGE%" (
    echo Creating local MinIO storage directory at %LOCAL_STORAGE%...
    mkdir "%LOCAL_STORAGE%"
)
goto :eof

:build_image
echo Building MinIO + NGINX Docker image...
docker build -t "%DOCKER_IMAGE%" .
goto :eof

:remove_existing_container
docker ps -a --format "{{.Names}}" | findstr /x "%CONTAINER_NAME%" >nul
if %errorlevel% equ 0 (
    echo Removing existing container...
    docker stop "%CONTAINER_NAME%" && docker rm "%CONTAINER_NAME%"
)
goto :eof

:start_container
call :check_storage_dirs
call :build_image
call :remove_existing_container

echo Starting MinIO + NGINX container...

for /f "delims=" %%i in ('docker run -d --name "%CONTAINER_NAME%" -p 8000:8000 -p 9000:9000 -p 9090:9090 -e "MINIO_ROOT_USER=%MINIO_ROOT_USER%" -e "MINIO_ROOT_PASSWORD=%MINIO_ROOT_PASSWORD%" -v "%LOCAL_STORAGE%:/local_storage" "%DOCKER_IMAGE%"') do set "CONTAINER_ID=%%i"

timeout /t 5 /nobreak >nul

docker ps | findstr "%CONTAINER_NAME%" >nul
if %errorlevel% neq 0 (
    echo Error: MinIO + NGINX failed to start! Check logs with:
    echo docker logs %CONTAINER_NAME%
    exit /b 1
)

echo MinIO + NGINX started successfully!
goto :eof

:stop_container
docker ps --format "{{.Names}}" | findstr /x "%CONTAINER_NAME%" >nul
if %errorlevel% equ 0 (
    echo Stopping MinIO + NGINX container...
    docker stop "%CONTAINER_NAME%" && docker rm "%CONTAINER_NAME%"
    echo Container stopped.
) else (
    echo Container is not running.
)
goto :eof

:restart_container
call :stop_container
call :start_container
goto :eof

:status_container
docker ps --format "{{.Names}}" | findstr /x "%CONTAINER_NAME%" >nul
if %errorlevel% equ 0 (
    echo MinIO + NGINX is running!
) else (
    echo MinIO + NGINX is NOT running.
)
goto :eof

if "%1"=="start" (
    call :start_container
) else if "%1"=="stop" (
    call :stop_container
) else if "%1"=="restart" (
    call :restart_container
) else if "%1"=="status" (
    call :status_container
) else (
    echo Usage: %0 {start^|stop^|restart^|status}
    exit /b 1
)
