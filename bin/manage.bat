@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: %0 {start^|stop^|restart^|status}
    exit /b 1
)
goto main

:check_storage_dirs
if not exist "%LOCAL_STORAGE%" (
    echo Creating local storage directory at %LOCAL_STORAGE%...
    mkdir "%LOCAL_STORAGE%"
)
goto :eof

:build_image
echo Building storage Docker image...
docker build -t "%DOCKER_IMAGE%" .
goto :eof

:remove_existing_container
docker ps -a --format "{{.Names}}" | findstr /x "%CONTAINER_NAME%" >nul
if %errorlevel% equ 0 (
    echo Removing existing container...
    docker stop "%CONTAINER_NAME%" >nul 2>&1
    docker rm "%CONTAINER_NAME%"
)
goto :eof

:start_container
call :check_storage_dirs
call :build_image
call :remove_existing_container

echo Starting storage container...
for /f "delims=" %%i in ('docker run -d --name "%CONTAINER_NAME%" -p 8000:8000 -p 9000:9000 -p 9090:9090 -v "%LOCAL_STORAGE%:/local_storage" "%DOCKER_IMAGE%"') do set "CONTAINER_ID=%%i"

timeout /t 15 /nobreak >nul

docker ps | findstr "%CONTAINER_NAME%" >nul
if %errorlevel% neq 0 (
    echo Error: storage container failed to start! Check logs with:
    echo docker logs %CONTAINER_NAME%
    exit /b 1
)

echo storage container started successfully!
goto :eof

:stop_container
docker ps -a --format "{{.Names}}" | findstr /x "%CONTAINER_NAME%" >nul
if %errorlevel% equ 0 (
    echo Stopping storage container if running...
    docker stop "%CONTAINER_NAME%" >nul 2>&1
    docker rm "%CONTAINER_NAME%"
    echo Container stopped and removed.
) else (
    echo Container does not exist.
)
goto :eof

:restart_container
call :stop_container
call :start_container
goto :eof

:status_container
docker ps -a --format "{{.Names}}" | findstr /x "%CONTAINER_NAME%" >nul
if %errorlevel% equ 0 (
    echo storage container exists.
    docker ps --format "{{.Names}}" | findstr /x "%CONTAINER_NAME%" >nul
    if %errorlevel% equ 0 (
        echo storage container is running.
    ) else (
        echo storage container is not running.
    )
) else (
    echo Container does not exist.
)
goto :eof

:main
set "CONTAINER_NAME=storage"
set "LOCAL_STORAGE=%CD%\storage"
set "DOCKER_IMAGE=storage"

if /I "%1"=="start" (
    call :start_container
) else if /I "%1"=="stop" (
    call :stop_container
) else if /I "%1"=="restart" (
    call :restart_container
) else if /I "%1"=="status" (
    call :status_container
) else (
    echo Usage: %0 {start^|stop^|restart^|status}
    exit /b 1
)
