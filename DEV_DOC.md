# Docker Developer Guide

*Everything you need to know about Docker to understand and run this project.*

---

## Table of Contents

1. [What is Docker?](#what-is-docker)
2. [Key Concepts](#key-concepts)
3. [Installation](#installation)
4. [Docker Commands](#docker-commands)
5. [Docker Compose Commands](#docker-compose-commands)
6. [Dockerfile — Deep Dive](#dockerfile--deep-dive)
7. [Docker Layers and Build Cache](#docker-layers-and-build-cache)
8. [Docker Networks — Deep Dive](#docker-networks--deep-dive)
9. [Docker Volumes — Deep Dive](#docker-volumes--deep-dive)
10. [Docker Secrets — Deep Dive](#docker-secrets--deep-dive)
11. [PID 1 and Signal Handling](#pid-1-and-signal-handling)
12. [Services Used in This Project](#services-used-in-this-project)
13. [How a Web Request Works — Step by Step](#how-a-web-request-works--step-by-step)
14. [SSL and HTTPS Explained](#ssl-and-https-explained)
15. [NGINX Configuration Explained](#nginx-configuration-explained)
16. [PHP-FPM and FastCGI Explained](#php-fpm-and-fastcgi-explained)
17. [MariaDB — Useful Commands](#mariadb--useful-commands)
18. [Redis — Useful Commands](#redis--useful-commands)
19. [WP-CLI — WordPress from Terminal](#wp-cli--wordpress-from-terminal)
20. [FTP — Active vs Passive Mode](#ftp--active-vs-passive-mode)
21. [Shell Scripting Patterns Used](#shell-scripting-patterns-used)
22. [Environment Variables — How They Flow](#environment-variables--how-they-flow)
23. [This Project — Architecture](#this-project--architecture)
24. [Ports and Services](#ports-and-services)
25. [Data Storage](#data-storage)
26. [Managing the Project](#managing-the-project)
27. [Security Best Practices](#security-best-practices)
28. [Troubleshooting](#troubleshooting)
29. [Quick Reference Card](#quick-reference-card)

---

## What is Docker?

Docker is a tool that lets you run applications inside **containers**. A container is like a small, isolated box. Inside the box you have everything the application needs — the code, the libraries, the configuration. The box runs the same way on any machine.

### Why is this useful?

Imagine you write a program on your computer and it works perfectly. Then you send it to a friend and they say "it does not work on my machine." This happens because their machine has different software versions, different settings, or a different operating system.

Docker solves this problem. You put your application in a container with everything it needs. Now it runs the same way everywhere — your computer, your friend's computer, a server in another country, anywhere.

### Docker vs Virtual Machine

A virtual machine (VM) runs a full operating system. It has its own kernel, its own memory management, everything is duplicated. It is heavy and slow to start.

Docker containers share the kernel of the host machine. They only contain the application and its dependencies. They are light and start in seconds.

```
Virtual Machine:
┌─────────────────────────────────────┐
│  App A       │  App B               │
│  Libs        │  Libs                │
│  Full OS     │  Full OS             │
│  (kernel)    │  (kernel)            │
├──────────────┴──────────────────────┤
│           Hypervisor                │
│           Host OS + Kernel          │
│           Hardware                  │
└─────────────────────────────────────┘

Docker:
┌─────────────────────────────────────┐
│  App A       │  App B               │
│  Libs        │  Libs                │
│  (no kernel) │  (no kernel)         │
├──────────────┴──────────────────────┤
│           Docker Engine             │
│           Host OS + Kernel (shared) │
│           Hardware                  │
└─────────────────────────────────────┘
```

| | Virtual Machine | Docker Container |
|---|---|---|
| Boot time | 1-5 minutes | Under 1 second |
| Memory usage | 512MB+ per VM | 10-50MB per container |
| Isolation | Full OS isolation | Process isolation |
| Disk space | Several GB per VM | Usually under 200MB |
| Good for | Maximum security needs | Development and microservices |

---

## Key Concepts

### Image

An image is a read-only template. It describes exactly what should be inside a container. You build images from a `Dockerfile`. Think of it like a recipe — the recipe does not change, but you can cook from it many times.

```
Dockerfile  →  (docker build)  →  Image  →  (docker run)  →  Container
  Recipe                          Blueprint               Running instance
```

Images are made of **layers**. Each instruction in a Dockerfile creates one layer. Layers are cached, which makes rebuilding fast (explained more in the layers section).

### Container

A container is a running instance of an image. It is isolated — it has its own file system, its own network interface, its own process space. Multiple containers from the same image do not share data unless you set up volumes.

```bash
# One image, multiple containers
docker run -d --name web1 nginx
docker run -d --name web2 nginx
docker run -d --name web3 nginx
# Three completely separate containers, same image
```

### Volume

Containers are ephemeral by default — when you delete a container, everything inside it disappears. Volumes are storage that lives outside the container lifecycle. You can delete and recreate a container, but the volume (and its data) stays.

### Network

A Docker network lets containers communicate with each other. Docker handles DNS inside the network — containers find each other by their service name, not by IP address. IP addresses can change, but service names are stable.

### Dockerfile

A text file with instructions to build an image. Every instruction adds a layer to the image.

### docker-compose.yml

A configuration file that describes multiple services (containers), their settings, networks, and volumes. Instead of running many `docker run` commands manually, you write one compose file and run `docker-compose up`.

---

## Installation

### Install Docker on Debian/Ubuntu

```bash
# Step 1 — Update package list
sudo apt-get update

# Step 2 — Install required packages
sudo apt-get install -y ca-certificates curl gnupg

# Step 3 — Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Step 4 — Add Docker repository to apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 5 — Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Step 6 — Verify installation
docker --version
docker compose version
```

### Run Docker without sudo

By default, only root can run Docker commands. Add your user to the docker group:

```bash
sudo usermod -aG docker $USER
newgrp docker        # apply the change in current terminal
# OR log out and log back in
```

### Verify Docker works

```bash
docker run hello-world
# Should print: Hello from Docker!
```

### Install Docker Compose standalone (older method)

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

---

## Docker Commands

### Images

```bash
# List all images on your machine
docker images
docker image ls             # same thing

# Pull an image from DockerHub
docker pull debian:bookworm
docker pull nginx:1.25

# Build an image from Dockerfile in current directory
docker build -t myapp:latest .

# Build with a specific Dockerfile
docker build -t myapp -f path/to/Dockerfile .

# Build with a build argument
docker build --build-arg MY_VERSION=1.2 -t myapp .

# Tag an existing image with a new name
docker tag myapp myapp:v1.0

# Remove one image
docker rmi myapp:latest

# Remove all unused images (images not used by any container)
docker image prune

# Remove ALL images (including used ones) — be careful
docker image prune -a

# Show how an image was built (all layers)
docker history myapp

# Inspect an image — see full metadata in JSON
docker inspect myapp

# Save an image to a tar file
docker save -o myapp.tar myapp

# Load an image from a tar file
docker load -i myapp.tar
```

### Containers

```bash
# Run a container (stops when main process exits)
docker run debian echo "hello"

# Run in detached mode (background)
docker run -d nginx

# Run with a custom name
docker run -d --name my-nginx nginx

# Run and open interactive terminal
docker run -it debian bash
docker run -it debian sh        # use sh if bash is not available

# Run and delete container when it stops
docker run --rm debian echo "temporary"

# Run with port mapping  HOST_PORT:CONTAINER_PORT
docker run -d -p 8080:80 nginx          # host port 8080 → container port 80
docker run -d -p 443:443 -p 80:80 nginx # multiple ports

# Run with environment variables
docker run -d -e DB_HOST=localhost -e DB_PORT=3306 myapp

# Run with a volume
docker run -d -v myvolume:/app/data myapp
docker run -d -v /host/path:/container/path myapp  # bind mount

# Run with a network
docker run -d --network my-network myapp

# Run with a secret (only in swarm or compose)
docker run -d --secret my-secret myapp

# Run with resource limits
docker run -d --memory="512m" --cpus="1.0" myapp

# Run as a specific user
docker run -d --user www-data myapp

# List running containers
docker ps

# List ALL containers (running + stopped)
docker ps -a

# List only container IDs
docker ps -q

# List IDs of all containers
docker ps -aq

# Filter containers by name
docker ps -f name=wordpress

# Filter containers by status
docker ps -f status=exited

# Format output
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Stop a container (sends SIGTERM, waits, then SIGKILL)
docker stop my-nginx

# Stop with a custom timeout (seconds)
docker stop -t 30 my-nginx

# Start a stopped container
docker start my-nginx

# Restart a container
docker restart my-nginx

# Pause a container (freeze processes)
docker pause my-nginx

# Unpause a container
docker unpause my-nginx

# Kill a container immediately (sends SIGKILL, no grace period)
docker kill my-nginx

# Remove a stopped container
docker rm my-nginx

# Remove a running container by force
docker rm -f my-nginx

# Remove all stopped containers
docker container prune

# Remove all containers (running and stopped)
docker rm -f $(docker ps -aq)

# Rename a container
docker rename old-name new-name
```

### Logs and Inspection

```bash
# See all logs
docker logs my-nginx

# Follow logs in real time
docker logs -f my-nginx

# Show last 100 lines
docker logs --tail 100 my-nginx

# Show logs with timestamps
docker logs -t my-nginx

# Show logs since a specific time
docker logs --since 2024-01-01T10:00:00 my-nginx

# Show logs from the last 30 minutes
docker logs --since 30m my-nginx

# Inspect a container — full JSON with all details
docker inspect my-nginx

# Get a specific field from inspect
docker inspect --format='{{.State.Status}}' my-nginx
docker inspect --format='{{.NetworkSettings.IPAddress}}' my-nginx

# See live resource usage (CPU, memory, network, disk)
docker stats

# See resource usage once (not live)
docker stats --no-stream

# See resource usage for specific containers
docker stats my-nginx wordpress

# See processes running inside a container
docker top my-nginx

# See port mappings of a container
docker port my-nginx

# See changes to filesystem inside container
docker diff my-nginx
```

### Execute Commands Inside Containers

```bash
# Open interactive shell
docker exec -it my-nginx bash
docker exec -it my-nginx sh       # if bash not available

# Run a single command
docker exec my-nginx nginx -t     # test nginx config
docker exec my-nginx ls /etc/nginx

# Run as a specific user
docker exec -u root my-nginx bash
docker exec -u www-data my-nginx bash

# Set environment variable for the exec session
docker exec -e MY_VAR=hello my-nginx bash

# Run in a specific working directory
docker exec -w /etc/nginx my-nginx ls

# Copy files from container to host
docker cp my-nginx:/etc/nginx/nginx.conf ./nginx.conf

# Copy files from host to container
docker cp ./my-config.conf my-nginx:/etc/nginx/nginx.conf
```

### Volumes

```bash
# List all volumes
docker volume ls

# Create a named volume
docker volume create my-data

# Inspect a volume — see where data is on host
docker volume inspect my-data

# Remove a volume (only if not used by any container)
docker volume rm my-data

# Remove all unused volumes
docker volume prune

# Remove all volumes including used ones — DANGEROUS
docker volume rm $(docker volume ls -q)
```

### Networks

```bash
# List all networks
docker network ls

# Create a bridge network
docker network create my-network

# Create with a specific driver
docker network create --driver bridge my-network

# Inspect a network — see connected containers, IP ranges
docker network inspect my-network

# Remove a network
docker network rm my-network

# Remove all unused networks
docker network prune

# Connect a running container to a network
docker network connect my-network my-container

# Disconnect a container from a network
docker network disconnect my-network my-container
```

### System

```bash
# Show Docker disk usage breakdown
docker system df

# Show detailed disk usage
docker system df -v

# Remove ALL unused resources (containers, images, networks)
docker system prune

# Remove ALL unused resources including volumes
docker system prune --volumes

# Remove everything — even images with tags
docker system prune -a

# Remove everything including volumes — FULL RESET
docker system prune -a --volumes

# Show Docker version
docker version

# Show Docker system info
docker info
```

---

## Docker Compose Commands

Run these from the directory containing `docker-compose.yml`, or use `-f` to specify a file.

```bash
# Start all services (builds if needed)
docker-compose up

# Start in background
docker-compose up -d

# Force rebuild all images before starting
docker-compose up -d --build

# Build only one service
docker-compose up -d --build wordpress

# Use a specific compose file
docker-compose -f srcs/docker-compose.yml up -d --build

# Stop all services (containers stay, just stopped)
docker-compose stop

# Stop one service
docker-compose stop nginx

# Stop and remove containers (volumes and images kept)
docker-compose down

# Stop, remove containers AND volumes (data deleted)
docker-compose down -v

# Stop, remove containers, volumes, AND images
docker-compose down -v --rmi all

# Restart all services
docker-compose restart

# Restart one service
docker-compose restart nginx

# See status of all services
docker-compose ps

# See logs of all services
docker-compose logs

# Follow logs of all services
docker-compose logs -f

# Follow logs of one service
docker-compose logs -f wordpress

# Show last 50 lines of logs for one service
docker-compose logs --tail 50 mariadb

# Execute command in a running service
docker-compose exec wordpress bash
docker-compose exec mariadb mysql -u root -p

# Run a one-off command (starts temporary container)
docker-compose run --rm wordpress wp --info

# Build images without starting
docker-compose build

# Build without using cache (full rebuild)
docker-compose build --no-cache

# Pull latest images
docker-compose pull

# List images used by compose
docker-compose images

# Show config after variable substitution
docker-compose config

# Show which ports are exposed
docker-compose port nginx 443
```

---

## Dockerfile — Deep Dive

### All Instructions Explained

```dockerfile
# FROM — base image, always the first line
# Use specific version tags, never "latest"
FROM debian:bookworm

# LABEL — metadata about the image
LABEL maintainer="merilhan@42.fr"
LABEL version="1.0"

# ARG — build-time variable (only available during build, not at runtime)
ARG APP_VERSION=1.0
RUN echo "Building version $APP_VERSION"

# ENV — runtime environment variable (available in container too)
ENV APP_HOME=/var/www
ENV NODE_ENV=production

# RUN — execute a command during build
# Always combine commands with && to reduce layers
# Always clean apt cache at the end
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    curl \
    && rm -rf /var/lib/apt/lists/*

# COPY — copy files from build context to image
# Preferred over ADD for simple file copying
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/start.sh /start.sh

# ADD — like COPY but also handles URLs and tar extraction
# Only use ADD when you need these extra features
ADD https://example.com/file.tar.gz /tmp/
# This extracts the tar automatically:
ADD archive.tar.gz /usr/local/

# WORKDIR — set working directory (like cd, but permanent)
# Creates directory if it does not exist
WORKDIR /var/www/html

# USER — run subsequent commands as this user
RUN useradd -m appuser
USER appuser
# Now RUN, CMD, ENTRYPOINT run as appuser

# EXPOSE — document which port the container uses
# This does NOT actually open the port — it is just documentation
# You still need -p flag in docker run or ports: in compose
EXPOSE 80
EXPOSE 443

# VOLUME — declare a mount point
# Docker will create an anonymous volume here if no volume is provided
VOLUME /var/www/html

# ENTRYPOINT — main command, always runs
# Use exec form (JSON array) — this makes the process PID 1
ENTRYPOINT ["nginx", "-g", "daemon off;"]

# CMD — default arguments for ENTRYPOINT, or default command
# Can be overridden with docker run arguments
CMD ["--help"]

# If both ENTRYPOINT and CMD are set:
# docker run myimage        → runs: nginx -g "daemon off;" --help
# docker run myimage -v     → runs: nginx -g "daemon off;" -v
```

### COPY vs ADD

```dockerfile
# Use COPY for simple file operations
COPY src/app.py /app/app.py
COPY ./config/ /etc/myapp/

# Use ADD only when you need:
# 1. Download from URL
ADD https://example.com/file.txt /tmp/file.txt

# 2. Automatic tar extraction
ADD myarchive.tar.gz /usr/local/

# For everything else, COPY is better because:
# - It is more explicit and predictable
# - ADD with URLs does not use build cache properly
```

### ARG vs ENV

```dockerfile
# ARG — only available at build time
# Use for: version numbers, build flags
ARG PHP_VERSION=8.2
RUN apt-get install -y php${PHP_VERSION}-fpm

# ENV — available at build time AND runtime
# Use for: application configuration, paths
ENV APP_ENV=production
ENV DB_HOST=mariadb

# You can set ENV from ARG
ARG BUILD_ENV=production
ENV APP_ENV=${BUILD_ENV}

# Override ARG at build time:
# docker build --build-arg PHP_VERSION=8.1 .

# Override ENV at runtime:
# docker run -e APP_ENV=development myapp
```

### .dockerignore

Just like `.gitignore`, `.dockerignore` tells Docker which files to ignore when building. This makes builds faster and images smaller.

```
# .dockerignore file (place in same directory as Dockerfile)

# Ignore git files
.git
.gitignore

# Ignore documentation
README.md
*.md

# Ignore development files
node_modules/
*.log
.env

# Ignore test files
tests/
*.test.js

# Ignore OS files
.DS_Store
Thumbs.db
```

---

## Docker Layers and Build Cache

### How Layers Work

Every instruction in a Dockerfile creates a new layer. Layers are stacked on top of each other. Each layer only contains the changes from the previous layer.

```
Layer 4: COPY tools/start.sh /start.sh         (adds 2KB)
Layer 3: RUN apt-get install -y nginx           (adds 50MB)
Layer 2: RUN apt-get update                     (adds 20MB)
Layer 1: FROM debian:bookworm                   (adds 115MB)
```

Total image size = sum of all layers.

### Build Cache

Docker caches each layer. When you rebuild an image, Docker checks if anything changed. If a layer is the same as before, Docker reuses the cached version instead of rebuilding it. This makes rebuilds much faster.

```
# First build: all layers built fresh
Step 1/4 : FROM debian:bookworm      → pulled from internet
Step 2/4 : RUN apt-get update        → executed
Step 3/4 : RUN apt-get install nginx → executed (took 30 seconds)
Step 4/4 : COPY nginx.conf /etc/...  → executed

# Second build (nginx.conf changed):
Step 1/4 : FROM debian:bookworm      → Using cache ✓
Step 2/4 : RUN apt-get update        → Using cache ✓
Step 3/4 : RUN apt-get install nginx → Using cache ✓
Step 4/4 : COPY nginx.conf /etc/...  → executed (cache invalidated)
```

### Cache Invalidation

When a layer changes, all layers AFTER it are also rebuilt (cache invalidated). This is why the order of instructions matters.

```dockerfile
# BAD — changing app.py forces apt-get to run again
COPY app.py /app/
RUN apt-get install -y python3      # always rebuilds when app.py changes

# GOOD — install packages first (they rarely change)
RUN apt-get install -y python3      # cached unless Dockerfile changes
COPY app.py /app/                   # only this and below rebuild on change
```

### Force Rebuild Without Cache

```bash
docker build --no-cache -t myapp .
docker-compose build --no-cache
```

---

## Docker Networks — Deep Dive

### Network Types

**Bridge (default)** — Creates a private internal network. Containers on the same bridge network can talk to each other. Containers on different bridge networks cannot talk directly.

```bash
docker network create --driver bridge my-net
```

**Host** — Container uses the host's network directly. No isolation. Port 80 in the container IS port 80 on the host. Forbidden in this project.

```bash
docker run --network host nginx
```

**None** — No network at all. Container cannot communicate with anything.

```bash
docker run --network none debian
```

**Overlay** — For Docker Swarm, connects containers across multiple host machines. Not used here.

### How Container DNS Works

On a custom bridge network, Docker runs an internal DNS server. Every container gets a DNS entry equal to its container name (or service name in compose). When WordPress wants to connect to MariaDB, it just uses `mariadb` as the hostname — Docker's DNS resolves this to the correct container IP automatically.

```
WordPress container:
  "connect to mariadb:3306"
         ↓
  Docker internal DNS (127.0.0.11)
         ↓
  "mariadb = 172.18.0.3"
         ↓
  TCP connection to 172.18.0.3:3306
         ↓
  MariaDB container
```

### Inspect Network Traffic

```bash
# See which containers are on which network
docker network inspect dev_net

# See the IP of a container
docker inspect --format='{{.NetworkSettings.Networks.srcs_dev_net.IPAddress}}' wordpress

# See all container IPs
docker inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -q)
```

---

## Docker Volumes — Deep Dive

### Volume Types

**Named Volumes** — Docker manages them. They have a name. You can inspect them with `docker volume inspect`.

```yaml
volumes:
  my-data:          # named volume, Docker manages location

services:
  app:
    volumes:
      - my-data:/app/data
```

**Anonymous Volumes** — Like named volumes but with a random ID as name. Created when you use `VOLUME` in Dockerfile without specifying a name in compose.

**Bind Mounts** — You specify the exact path on the host. Docker does not manage them. They do not appear in `docker volume ls`.

```yaml
services:
  app:
    volumes:
      - /home/user/data:/app/data   # bind mount — host path:container path
```

**tmpfs Mounts** — Stored in host memory, not on disk. Gone when container stops.

```yaml
services:
  app:
    tmpfs:
      - /tmp
```

### Named Volume with Custom Path (This Project's Approach)

This is how we satisfy both requirements: named volume + data at specific host path.

```yaml
volumes:
  wp_vol:
    driver: local
    driver_opts:
      type: none          # no special filesystem type
      device: /home/merilhan/data/wordpress   # host path
      o: bind             # mount option: bind
```

This is a named volume (appears in `docker volume ls`) that stores data at a specific location. The `o: bind` is a Linux kernel mount option, not the same as a Docker "bind mount" in compose syntax.

```bash
# Verify it is a named volume
docker volume ls
# DRIVER    VOLUME NAME
# local     srcs_db_vol
# local     srcs_wp_vol

docker volume inspect srcs_wp_vol
# "Driver": "local"
# "Options": {"device": "/home/merilhan/data/wordpress", "o": "bind", "type": "none"}
# "Mountpoint": "/var/lib/docker/volumes/srcs_wp_vol/_data"
```

### Volume Permissions

Volumes can have permission issues. If the container runs as a non-root user, it may not be able to write to the volume.

```sh
# In the entrypoint script, fix permissions before starting the app
chown -R www-data:www-data /var/www/wordpress
chmod -R 755 /var/www/wordpress
```

---

## Docker Secrets — Deep Dive

### How Secrets Work in Docker Compose

Docker Compose file-based secrets work like this:

1. You have a file on the host machine with the secret value (e.g., `secrets/db_password.txt` containing `mypassword123`)
2. You declare the secret in `docker-compose.yml`
3. You assign the secret to services that need it
4. Docker mounts the file into each service container at `/run/secrets/secret-name`
5. The container script reads the value with `cat /run/secrets/secret-name`

```yaml
# docker-compose.yml

secrets:
  db_password:
    file: ../secrets/db_password.txt    # source file on host

services:
  mariadb:
    secrets:
      - db_password    # mounts at /run/secrets/db_password inside container
  wordpress:
    secrets:
      - db_password    # same file, also available here
```

```sh
# Inside the container script:
DB_PASSWORD=$(cat /run/secrets/db_password)
echo "The password is: $DB_PASSWORD"
```

### Why Not Just Use Environment Variables for Passwords?

```bash
# If you use environment variables for passwords:
docker inspect wordpress
# You can see ALL environment variables in plain text:
# "DB_PASSWORD": "mysecretpassword"
# Anyone with docker inspect access can read all passwords

# With secrets:
docker inspect wordpress
# Only shows: "db_password" is mounted — not the value
# The actual value is only visible inside the container
```

Also, environment variables can leak through:
- Error logs that print all env vars
- `/proc/1/environ` on Linux
- Child processes that inherit env vars

Secrets are files — harder to accidentally expose.

### Security Comparison

| | Env Variables | Docker Secrets |
|---|---|---|
| Visible in `docker inspect` | Yes, in plain text | No |
| Visible in logs | Sometimes (if app prints env) | Rarely |
| Access inside container | `$VARIABLE` | `cat /run/secrets/name` |
| Risk if git committed | Very high | N/A (file is separate) |

---

## PID 1 and Signal Handling

### What is PID 1?

Every Linux process has an ID (PID). The first process that starts gets PID 1. In a normal Linux system, PID 1 is `init` or `systemd`. In a Docker container, PID 1 is whatever your `ENTRYPOINT` or `CMD` runs.

PID 1 is special because:
- When Docker stops a container, it sends `SIGTERM` to PID 1
- If PID 1 does not exit within 10 seconds, Docker sends `SIGKILL` (force kill)
- PID 1 is responsible for reaping "zombie" child processes

### Exec Form vs Shell Form

```dockerfile
# SHELL FORM — runs via /bin/sh -c
# The shell becomes PID 1, NOT your actual program
ENTRYPOINT nginx -g "daemon off;"
# Container process tree:
# PID 1: /bin/sh -c nginx -g "daemon off;"
# PID 2: nginx -g "daemon off;"
# When Docker sends SIGTERM, sh may not pass it to nginx → unclean shutdown

# EXEC FORM — runs directly, no shell wrapper
# Your actual program becomes PID 1
ENTRYPOINT ["nginx", "-g", "daemon off;"]
# Container process tree:
# PID 1: nginx -g "daemon off;"
# SIGTERM goes directly to nginx → clean shutdown
```

Always use exec form (the JSON array format) for `ENTRYPOINT` and `CMD`. This is why all scripts in this project use:

```sh
exec php-fpm8.2 -F      # "exec" replaces the shell with php-fpm — it becomes PID 1
exec mysqld --user=mysql # "exec" makes mysqld PID 1
exec vsftpd /etc/vsftpd.conf
```

The `exec` command replaces the current shell process with the new program. So the shell (PID 1) becomes nginx or mysqld.

### What is daemon off in NGINX?

By default, NGINX starts and then immediately puts itself in the background (daemonizes). In a Docker container this is a problem — if the process goes to background, there is no foreground process, and Docker thinks the container finished and stops it.

`daemon off;` tells NGINX to stay in the foreground. This way NGINX is PID 1 and Docker keeps the container running.

---

## Services Used in This Project

### NGINX

NGINX is a web server and reverse proxy. In this project it does several things:

1. **Terminates SSL** — decrypts HTTPS traffic from the browser
2. **Serves WordPress** — passes PHP requests to PHP-FPM
3. **Reverse proxy** — forwards `/adminer/`, `/portainer/`, `/portfolio/` to the right containers
4. **Only entry point** — the only container with a port open to the outside (443)

NGINX uses an event-driven architecture. It can handle thousands of connections at the same time with very low memory usage. Apache (another web server) uses one thread per connection, which uses much more memory.

### MariaDB

MariaDB is a relational database — a fork of MySQL. WordPress uses it to store all content: posts, pages, users, settings, everything.

It runs only on the internal Docker network. No one from the internet can reach it directly. Only WordPress and Adminer can connect to it through the `dev_net` network.

Data is stored in `/home/merilhan/data/mariadb/` on the host machine.

### PHP-FPM

PHP-FPM (FastCGI Process Manager) runs PHP code. NGINX itself cannot run PHP — it hands PHP files to PHP-FPM, which processes them and sends the HTML result back.

PHP-FPM listens on port 9000. NGINX and PHP-FPM communicate using the FastCGI protocol (more on this later).

### Redis

Redis is an in-memory data store. It is extremely fast because it stores everything in RAM instead of on disk.

WordPress uses Redis as an object cache. When WordPress fetches something from the database (like the front page content), it saves a copy in Redis. Next time someone visits the page, WordPress gets the data from Redis instead of querying MariaDB. This is much faster.

### vsftpd (FTP Server)

vsftpd (Very Secure FTP Daemon) is an FTP server. It gives direct file access to the WordPress volume. You can connect with any FTP client and browse, upload, or download WordPress files.

### Adminer

Adminer is a database management tool written in a single PHP file. It provides a web interface to browse and query the MariaDB database. Useful for inspecting data, running SQL queries, and debugging.

### Portainer

Portainer is a Docker management UI. It lets you see all containers, their logs, resource usage, volumes, and networks from a web browser. Much more convenient than typing docker commands for quick checks.

---

## How a Web Request Works — Step by Step

When you type `https://merilhan.42.fr` in your browser:

```
1. Browser → DNS lookup
   "What is the IP of merilhan.42.fr?"
   /etc/hosts says: 127.0.0.1
   So the request goes to localhost

2. Browser → TCP connection to 127.0.0.1:443

3. Host machine → port 443 is forwarded to NGINX container
   (because of "ports: 443:443" in docker-compose)

4. NGINX → SSL handshake
   NGINX presents its self-signed certificate
   Browser warns "Not secure" (because it's self-signed, not from a CA)
   After accepting, traffic is encrypted

5. NGINX → receives HTTP request
   "GET / HTTP/1.1"
   "Host: merilhan.42.fr"

6. NGINX → checks if file exists in /var/www/wordpress
   "Is there a file at /var/www/wordpress/index.php?"
   Yes → pass to PHP-FPM

7. NGINX → FastCGI request to wordpress:9000
   "Run /var/www/wordpress/index.php"
   "Query string: ?"
   "Server name: merilhan.42.fr"

8. PHP-FPM → executes index.php
   WordPress loads
   WordPress queries MariaDB for content
   WordPress checks Redis cache (if cached, skip MariaDB)
   WordPress builds HTML page

9. PHP-FPM → sends HTML back to NGINX

10. NGINX → sends HTML back to browser with HTTP 200 OK

11. Browser → renders the page
```

### For /adminer/ requests:

```
Browser → https://merilhan.42.fr/adminer/
NGINX → location /adminer/ matches
NGINX → proxy_pass to http://adminer:8080/
Adminer container → serves Adminer PHP file
Adminer → connects to mariadb:3306 when you log in
```

---

## SSL and HTTPS Explained

### What is SSL/TLS?

SSL (Secure Sockets Layer) and its successor TLS (Transport Layer Security) are protocols that encrypt internet traffic. HTTPS = HTTP + TLS.

Without HTTPS, anyone on your network can read what you send and receive (passwords, cookies, content).

With HTTPS:
1. Browser and server agree on encryption method
2. Server sends a certificate proving its identity
3. Both sides generate encryption keys
4. All traffic is encrypted — no one in the middle can read it

### TLS Versions

- **TLS 1.0, 1.1** — old and insecure, disabled
- **TLS 1.2** — secure, widely supported, allowed in this project
- **TLS 1.3** — newest, faster, most secure, allowed in this project
- **SSL 2.0, 3.0** — completely broken, never use

This project's NGINX config only allows TLS 1.2 and 1.3:
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

### What is a Certificate?

A certificate is a file that proves who you are. It contains:
- Your domain name
- Your public key
- Validity period
- Signature from a Certificate Authority (CA)

CAs (like Let's Encrypt, DigiCert) are trusted organizations that verify you own the domain before signing.

A **self-signed certificate** is signed by yourself. Browsers do not trust it by default and show a warning. This is fine for development — in production you would use Let's Encrypt (free) or a paid CA.

### How We Generate the Certificate

```sh
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=TR/ST=Kocaeli/L=Kocaeli/O=42/OU=42/CN=merilhan.42.fr"
```

- `-x509` — create a self-signed certificate (not a certificate request)
- `-nodes` — do not encrypt the private key (so NGINX can read it without password)
- `-days 365` — valid for 1 year
- `-newkey rsa:2048` — generate a new 2048-bit RSA key pair
- `-keyout` — save the private key here
- `-out` — save the certificate here
- `-subj` — certificate details (country, state, city, org, domain)

---

## NGINX Configuration Explained

```nginx
server {
    # Listen on port 443 with SSL enabled
    listen 443 ssl;

    # The domain this server block responds to
    server_name merilhan.42.fr;

    # Only allow TLS 1.2 and 1.3 — older versions are insecure
    ssl_protocols TLSv1.2 TLSv1.3;

    # The certificate and private key files
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    # Default directory for files
    root /var/www/wordpress;

    # Try these files when someone requests a directory
    index index.php index.html index.htm;

    # Handle all requests
    location / {
        # Try to serve the file, then the directory, then fall back to index.php
        # This makes WordPress routing work (pretty URLs)
        try_files $uri $uri/ /index.php?$args;
    }

    # Handle PHP files — pass to PHP-FPM
    location ~ \.php$ {
        # Split the path: /index.php/some/path → /index.php + /some/path
        fastcgi_split_path_info ^(.+\.php)(/.+)$;

        # Send to PHP-FPM at wordpress:9000
        fastcgi_pass wordpress:9000;

        # Default file if directory is requested
        fastcgi_index index.php;

        # Include standard FastCGI parameters
        include fastcgi_params;

        # Tell PHP where the script file is
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    # Proxy for portfolio — no path stripping
    location /portfolio/ {
        # No trailing slash on proxy_pass — keeps /portfolio/ prefix
        proxy_pass http://static:80;
    }

    # Proxy for Adminer
    location /adminer/ {
        # Trailing slash — strips /adminer/ prefix, passes rest
        proxy_pass http://adminer:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Proxy for Portainer — needs WebSocket support
    location /portainer/ {
        proxy_pass http://portainer:9000/;

        # WebSocket support (Portainer uses WebSockets for live updates)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### proxy_pass URL Rules

The trailing slash in `proxy_pass` matters a lot:

```nginx
# WITH trailing slash — strips the location prefix
location /adminer/ {
    proxy_pass http://adminer:8080/;
    # Request: /adminer/index.php
    # Sent to: http://adminer:8080/index.php   ← /adminer/ is stripped
}

# WITHOUT trailing slash — keeps the full path
location /portfolio/ {
    proxy_pass http://static:80;
    # Request: /portfolio/static/js/main.js
    # Sent to: http://static:80/portfolio/static/js/main.js   ← kept
}
```

---

## PHP-FPM and FastCGI Explained

### What is PHP-FPM?

PHP-FPM is a process manager for PHP. It keeps PHP processes running and ready to handle requests. When a request comes in, PHP-FPM gives it to one of the ready processes, which runs the PHP file and returns the result.

NGINX cannot run PHP by itself. PHP-FPM is the bridge between NGINX and PHP.

```
Browser → NGINX (handles HTTP, SSL)
              ↓ FastCGI protocol
          PHP-FPM (runs PHP code)
              ↓ SQL queries
          MariaDB (stores data)
```

### What is FastCGI?

FastCGI is a protocol for communication between a web server and an application. It is faster than the old CGI because:
- CGI starts a new process for every request — slow
- FastCGI keeps processes running and reuses them — fast

### www.conf — PHP-FPM Pool Configuration

```ini
[www]
; Run as this user
user = www-data
group = www-data

; Listen on port 9000 — NGINX connects here
listen = 0.0.0.0:9000

; Process management mode
pm = ondemand         ; start workers only when needed (saves memory)
; pm = static         ; always keep N workers running
; pm = dynamic        ; keep some running, start more when busy

; Maximum number of worker processes
pm.max_children = 5

; Pass all environment variables to PHP processes
; Without this, WordPress cannot read env variables
clear_env = no
```

---

## MariaDB — Useful Commands

### Connect to MariaDB

```bash
# From host, using docker exec
docker exec -it $(docker ps -q -f name=mariadb) mysql -u wp_manager -p wordpress_db

# Inside the container
mysql -u root -p
mysql -u wp_manager -pYOUR_PASSWORD wordpress_db

# Without password prompt (less secure)
mysql -u root -pROOTPASSWORD
```

### Useful SQL Commands

```sql
-- Show all databases
SHOW DATABASES;

-- Use a specific database
USE wordpress_db;

-- Show all tables
SHOW TABLES;

-- Describe a table structure
DESCRIBE wp_users;
DESCRIBE wp_posts;

-- Count rows in a table
SELECT COUNT(*) FROM wp_posts;

-- Show all WordPress users
SELECT user_login, user_email, user_registered FROM wp_users;

-- Show all posts
SELECT ID, post_title, post_status, post_type FROM wp_posts WHERE post_status = 'publish';

-- Show WordPress options (settings)
SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'blogname', 'admin_email');

-- Check database size
SELECT
  table_schema AS "Database",
  ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS "Size (MB)"
FROM information_schema.tables
GROUP BY table_schema;

-- Show active connections
SHOW PROCESSLIST;

-- Show current user
SELECT USER();

-- Show all privileges of a user
SHOW GRANTS FOR 'wp_manager'@'%';
```

### MariaDB Backup and Restore

```bash
# Backup database to SQL file
docker exec $(docker ps -q -f name=mariadb) \
  mysqldump -u root -p wordpress_db > backup.sql

# Restore database from SQL file
docker exec -i $(docker ps -q -f name=mariadb) \
  mysql -u root -p wordpress_db < backup.sql
```

---

## Redis — Useful Commands

### Connect to Redis

```bash
# Connect to Redis CLI
docker exec -it $(docker ps -q -f name=redis) redis-cli

# Test connection
docker exec -it $(docker ps -q -f name=redis) redis-cli ping
# Should respond: PONG
```

### Useful Redis Commands

```bash
# Inside redis-cli:

# Check if Redis is working
PING
# → PONG

# Set a key-value pair
SET mykey "hello"

# Get a value
GET mykey
# → "hello"

# Set with expiry (seconds)
SET mykey "hello" EX 3600

# Check time to live
TTL mykey

# Delete a key
DEL mykey

# List all keys (careful in production — slow on large datasets)
KEYS *

# List keys matching a pattern
KEYS wordpress:*

# Count total keys
DBSIZE

# Get server info
INFO

# Get memory usage stats
INFO memory

# Get hit/miss statistics (check if cache is working)
INFO stats
# Look for: keyspace_hits and keyspace_misses
# hits/(hits+misses) = cache hit rate

# Flush all data (CAREFUL — deletes everything)
FLUSHALL

# Monitor all commands in real time
MONITOR

# Exit redis-cli
EXIT
```

### Check if WordPress Cache is Working

```bash
# Open two terminals

# Terminal 1 — watch Redis in real time
docker exec -it $(docker ps -q -f name=redis) redis-cli MONITOR

# Terminal 2 — visit the website
curl -sk https://merilhan.42.fr > /dev/null

# In Terminal 1 you should see GET/SET commands
# This means WordPress is reading and writing to Redis
```

---

## WP-CLI — WordPress from Terminal

WP-CLI is a command-line tool for managing WordPress. It is installed in the WordPress container.

```bash
# Run WP-CLI inside the WordPress container
docker exec -it $(docker ps -q -f name=wordpress) sh

# Then inside the container:
wp --info                          # check WP-CLI version
wp core version                    # check WordPress version
wp core check-update               # check for updates

# User management
wp user list                       # list all users
wp user get admin --field=email   # get user email
wp user create newuser user@example.com --role=subscriber --user_pass=pass123
wp user delete 2                   # delete user with ID 2
wp user update 1 --user_pass=newpass  # change password

# Plugin management
wp plugin list                     # list all plugins
wp plugin install redis-cache      # install a plugin
wp plugin activate redis-cache     # activate a plugin
wp plugin deactivate redis-cache   # deactivate a plugin
wp plugin delete redis-cache       # delete a plugin
wp plugin update --all             # update all plugins

# Theme management
wp theme list                      # list all themes
wp theme activate twentytwentyone  # activate a theme

# Database
wp db check                        # check database connection
wp db export backup.sql            # export database
wp db import backup.sql            # import database
wp db query "SELECT * FROM wp_users"  # run SQL query

# Options (WordPress settings)
wp option get siteurl              # get site URL
wp option update siteurl "https://merilhan.42.fr"  # update site URL
wp option get blogname             # get site title

# Cache
wp cache flush                     # flush object cache
wp redis status                    # check Redis status
wp redis enable                    # enable Redis cache
wp redis disable                   # disable Redis cache

# Config
wp config list                     # list wp-config.php values
wp config get DB_HOST              # get one value
wp config set DB_HOST mariadb      # set a value
wp config delete MY_CONST         # remove a value

# Posts
wp post list                       # list all posts
wp post create --post_title="Hello" --post_status=publish  # create post

# Search and replace
wp search-replace 'http://old.com' 'https://new.com'  # update URLs in database
```

---

## FTP — Active vs Passive Mode

### What is FTP?

FTP (File Transfer Protocol) uses two separate connections:
1. **Control connection** (port 21) — for sending commands
2. **Data connection** — for actually transferring files

The difference between active and passive mode is who creates the data connection.

### Active Mode

```
Client (random port)  →  Server port 21   (client connects for control)
Server port 20        →  Client (random)  (SERVER connects back for data)
```

Problem: The client is often behind a firewall or NAT. The server cannot connect back to the client. Active mode breaks.

### Passive Mode

```
Client (random port)  →  Server port 21          (client connects for control)
Client (random port)  →  Server port 21100-21110  (CLIENT connects for data too)
```

The server tells the client "connect to port 21100 for the data." The client makes both connections. This works through firewalls and NAT.

This is why we expose ports `21100-21110` in docker-compose — these are the passive mode data ports.

### vsftpd Configuration Explained

```ini
listen=YES                    # listen for connections
listen_ipv6=NO               # do not use IPv6

anonymous_enable=NO          # do not allow anonymous login
local_enable=YES             # allow system users to log in
write_enable=YES             # allow upload and delete
local_umask=022              # new files get 755 permissions

chroot_local_user=YES        # lock users in their home directory
allow_writeable_chroot=YES   # allow writing in the chroot directory

local_root=/var/www/wordpress # FTP users land here when they connect
secure_chroot_dir=/var/run/vsftpd/empty  # required by vsftpd security

pasv_enable=YES              # enable passive mode
pasv_min_port=21100          # first passive port
pasv_max_port=21110          # last passive port
```

### Connect to FTP

```bash
# Command line FTP client
ftp merilhan.42.fr
# Enter username and password when prompted

# Using lftp (better command line client)
lftp -u ftpuser,PASSWORD merilhan.42.fr

# Common FTP commands inside ftp client:
ls              # list files
cd wordpress    # change directory
get wp-config.php   # download a file
put myfile.php      # upload a file
mkdir newdir    # create directory
bye             # exit

# Recommended GUI clients:
# FileZilla (free, all platforms)
# Cyberduck (Mac/Windows)
```

---

## Shell Scripting Patterns Used

### Wait Until Service is Ready

Instead of `sleep 20` (unreliable), retry until the service responds:

```sh
# Wait until MariaDB is ready by trying to install WordPress
# wp core install fails if DB is not ready, so we retry
until wp core install --url=https://${DOMAIN_NAME} \
                      --title="My Site" \
                      --admin_user=admin \
                      --admin_password=$(cat /run/secrets/wp_admin_password) \
                      --admin_email=admin@example.com \
                      --allow-root; do
    echo "Waiting for database..."
    sleep 2
done
```

### Read Secret from File

```sh
# Read a secret at runtime
MY_PASSWORD=$(cat /run/secrets/my_password)

# Use it immediately without storing in a variable (more secure)
echo "user:$(cat /run/secrets/my_password)" | chpasswd
```

### Check if Already Set Up

```sh
# Only run setup once — check for a file that setup creates
if [ ! -f /var/www/wordpress/wp-config.php ]; then
    echo "First run — setting up WordPress..."
    # do setup
fi
# Always continue to start the service
exec php-fpm8.2 -F
```

### Use exec to Become PID 1

```sh
#!/bin/sh

# Do setup
mkdir -p /run/php
chown -R www-data:www-data /var/www

# exec replaces this shell with php-fpm
# php-fpm becomes PID 1 and receives signals properly
exec php-fpm8.2 -F
```

### Heredoc for Multi-line SQL

```sh
cat << EOF > /tmp/setup.sql
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF
# Note: backslash before backtick prevents shell expansion
# ${VARIABLE} is expanded, \`backtick\` is literal
```

---

## Environment Variables — How They Flow

```
Host machine:
  srcs/.env file
  ├── DOMAIN_NAME=merilhan.42.fr
  ├── DB_NAME=wordpress_db
  └── DB_USER=wp_manager

  secrets/db_password.txt
  └── "secrets_1906"

  ↓  (docker-compose reads .env and secrets)

docker-compose.yml:
  services:
    wordpress:
      env_file: .env       ← injects all .env variables as env vars
      secrets:
        - db_password      ← mounts file at /run/secrets/db_password

  ↓  (container starts)

WordPress container:
  Environment variables:
    DOMAIN_NAME=merilhan.42.fr    ← from .env
    DB_NAME=wordpress_db          ← from .env
    DB_USER=wp_manager            ← from .env

  Secret files:
    /run/secrets/db_password      ← file containing "secrets_1906"
    /run/secrets/wp_admin_password
    /run/secrets/wp_user_password

  wp-config.sh reads them:
    DB_PASSWORD=$(cat /run/secrets/db_password)
    uses $DOMAIN_NAME, $DB_NAME, $DB_USER from env
```

---

## This Project — Architecture

### Services and How They Connect

```
Internet
    │
    │ HTTPS port 443
    ▼
┌──────────────────────────────────────────────────────┐
│  NGINX container                                      │
│  - handles SSL/TLS                                   │
│  - routes requests:                                  │
│    /          → WordPress (FastCGI port 9000)        │
│    /adminer/  → Adminer (HTTP port 8080)             │
│    /portainer/→ Portainer (HTTP port 9000)           │
│    /portfolio/→ Static site (HTTP port 80)           │
└──────────────────────────────────────────────────────┘
    │ (internal network: dev_net)
    ├─────────────────┬──────────────┬──────────────┐
    ▼                 ▼              ▼              ▼
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│WordPress │   │ Adminer  │   │Portainer │   │  Static  │
│PHP-FPM   │   │  :8080   │   │  :9000   │   │ NGINX:80 │
│  :9000   │   └────┬─────┘   └──────────┘   └──────────┘
└────┬─────┘        │
     │              │ port 3306
     ▼              ▼
┌──────────────────────┐
│       MariaDB        │
│        :3306         │
└──────────────────────┘
     ▲
     │ port 6379
┌──────────┐
│  Redis   │ ← WordPress object cache
│  :6379   │
└──────────┘

FTP (separate port, not through NGINX):
port 21 + 21100-21110 → FTP server → WordPress volume
```

---

## Ports and Services

### External Ports (open to the world)

| Port | Protocol | Container | Purpose |
|---|---|---|---|
| `443` | HTTPS | nginx | All web traffic — main entry point |
| `21` | FTP | ftp | FTP control connection |
| `21100` | FTP passive | ftp | Data transfer |
| `21101` | FTP passive | ftp | Data transfer |
| `...` | FTP passive | ftp | Data transfer |
| `21110` | FTP passive | ftp | Data transfer |

### Internal Ports (only inside Docker network)

| Port | Container | Who Talks to It |
|---|---|---|
| `9000` | wordpress (PHP-FPM) | nginx |
| `3306` | mariadb | wordpress, adminer |
| `6379` | redis | wordpress |
| `80` | static | nginx |
| `8080` | adminer | nginx |
| `9000` | portainer | nginx |

---

## Data Storage

All persistent data is on the host machine at `/home/merilhan/data/`:

```
/home/merilhan/data/
├── wordpress/          ← WordPress files
│   ├── wp-config.php   ← generated on first boot
│   ├── wp-content/     ← themes, plugins, uploads
│   │   ├── themes/
│   │   ├── plugins/
│   │   └── uploads/
│   ├── wp-admin/
│   └── wp-includes/
│
├── mariadb/            ← MariaDB database files
│   ├── wordpress_db/   ← the WordPress database
│   ├── mysql/          ← MariaDB system tables
│   └── ibdata1         ← InnoDB shared tablespace
│
└── portainer/          ← Portainer settings and data
    └── portainer.db
```

### What Happens to Data on Each Command

```bash
make clean
# → docker-compose down -v
# → Containers stop
# → Docker removes volume references (srcs_wp_vol, srcs_db_vol)
# → DATA FILES ARE KEPT at /home/merilhan/data/
# → Next "make" finds existing files → does NOT reinstall WordPress

make fclean
# → make clean runs first
# → sudo rm -rf /home/merilhan/data/wordpress
# → sudo rm -rf /home/merilhan/data/mariadb
# → sudo rm -rf /home/merilhan/data/portainer
# → docker system prune -af  (removes all images)
# → DATA IS GONE
# → Next "make" = completely fresh install
```

---

## Managing the Project

### Start Everything

```bash
make
# Runs:
# mkdir -p /home/merilhan/data/wordpress /home/merilhan/data/mariadb /home/merilhan/data/portainer
# docker-compose -f srcs/docker-compose.yml up -d --build
```

### Check Status

```bash
docker-compose -f srcs/docker-compose.yml ps

# Expected output:
# NAME           COMMAND         SERVICE     STATUS     PORTS
# srcs-nginx-1   /tmp/nginx.sh   nginx       Up         0.0.0.0:443->443/tcp
# srcs-wp-1      sh /wp-...      wordpress   Up
# srcs-db-1      sh /mariadb.sh  mariadb     Up
# srcs-redis-1   redis-server    redis       Up
# ...
```

### View Logs

```bash
# All services at once
docker-compose -f srcs/docker-compose.yml logs -f

# One service
docker-compose -f srcs/docker-compose.yml logs -f wordpress
docker-compose -f srcs/docker-compose.yml logs -f mariadb
docker-compose -f srcs/docker-compose.yml logs -f nginx

# Last 50 lines of one service
docker-compose -f srcs/docker-compose.yml logs --tail 50 wordpress
```

### Enter Containers for Debugging

```bash
# Enter WordPress container
docker exec -it $(docker ps -q -f name=wordpress) sh

# Enter MariaDB container
docker exec -it $(docker ps -q -f name=mariadb) sh

# Enter NGINX container
docker exec -it $(docker ps -q -f name=nginx) sh

# Test NGINX configuration
docker exec $(docker ps -q -f name=nginx) nginx -t

# Connect to MariaDB directly
docker exec -it $(docker ps -q -f name=mariadb) mysql -u wp_manager -p wordpress_db

# Check Redis
docker exec $(docker ps -q -f name=redis) redis-cli ping

# Check PHP-FPM is running
docker exec $(docker ps -q -f name=wordpress) ps aux
```

### Inspect Resources

```bash
# See all volumes
docker volume ls

# See where WordPress data actually is
docker volume inspect srcs_wp_vol

# See what is in the WordPress volume (from host)
ls -la /home/merilhan/data/wordpress/

# See all networks
docker network ls

# See which containers are on dev_net
docker network inspect srcs_dev_net

# See resource usage
docker stats --no-stream
```

---

## Security Best Practices

### Never Put Passwords in Dockerfiles

```dockerfile
# BAD — password visible in image layers forever
RUN mysql -u root -pmypassword -e "CREATE DATABASE mydb"

# GOOD — read at runtime from secret
RUN mysql -u root -p$(cat /run/secrets/db_root_password) -e "CREATE DATABASE mydb"

# ACTUALLY GOOD — do it in entrypoint script, not at build time
# entrypoint.sh reads the secret when container starts
```

### Never Use Root Inside Containers

```dockerfile
# BAD — everything runs as root
RUN apt-get install -y nginx
CMD ["nginx"]

# GOOD — create a user and switch to it
RUN useradd -r -s /bin/false nginx-user
USER nginx-user
CMD ["nginx"]
```

WordPress containers use `www-data` user (already exists in Debian):
```sh
chown -R www-data:www-data /var/www/wordpress
```

### Keep Images Small

```dockerfile
# Use --no-install-recommends to avoid extra packages
RUN apt-get install -y --no-install-recommends nginx

# Clean up apt cache in the same layer
RUN apt-get update && apt-get install -y --no-install-recommends nginx \
    && rm -rf /var/lib/apt/lists/*
```

### Use Specific Version Tags

```dockerfile
# BAD — "latest" can change and break things
FROM nginx:latest

# GOOD — pin to specific version
FROM debian:bookworm
```

### Never Commit Secrets to Git

```bash
# .gitignore must include:
secrets/
srcs/.env

# Verify nothing secret is tracked
git status
git ls-files | grep -E "(\.env|password|secret|key)"
```

### Minimal Port Exposure

Only expose ports that absolutely need to be public:
```yaml
# BAD — exposing MariaDB to the internet
mariadb:
  ports:
    - "3306:3306"  # anyone can try to connect

# GOOD — no ports exposed, only internal network
mariadb:
  networks:
    - dev_net     # only other containers can reach it
```

---

## OWASP Docker Security — Network Architecture

### What is OWASP?

OWASP (Open Web Application Security Project) is a non-profit foundation that publishes security best practices for software. Their Docker Security Cheat Sheet defines guidelines to reduce the attack surface of containerized applications.

### Key OWASP Principle: Network Segmentation

OWASP recommends separating containers into network tiers based on trust level. Services that do not need to communicate should never be on the same network.

> *"Use Docker network features to segment the network. Create different networks for different services and assign containers only to the networks they need."*

### This Project's 3-Tier Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    INTERNET                                  │
└─────────────────────────┬───────────────────────────────────┘
                          │ port 443 only
┌─────────────────────────▼───────────────────────────────────┐
│                  public network                              │
│                                                             │
│                    [ NGINX ]                                │
│              (only container exposed)                       │
└──────────────┬──────────────────────────────────────────────┘
               │ (nginx is on both public + app)
┌──────────────▼──────────────────────────────────────────────┐
│             app network  (internal: yes)                    │
│                                                             │
│   [ WordPress ]  [ Adminer ]  [ Portainer ]  [ Static ]    │
│       [ FTP ]                                               │
└──────────────┬──────────────────────────────────────────────┘
               │ (wordpress + adminer are on both app + data)
┌──────────────▼──────────────────────────────────────────────┐
│             data network  (internal: yes)                   │
│                                                             │
│              [ MariaDB ]        [ Redis ]                   │
│         (no internet access, completely isolated)           │
└─────────────────────────────────────────────────────────────┘
```

### Why 3 Networks?

| Network | internal | Who's on it | Why |
|---|---|---|---|
| `public` | no | nginx | Single entry point, exposed to internet |
| `app` | yes | nginx, wordpress, adminer, portainer, static, ftp | App tier, no internet needed at runtime |
| `data` | yes | mariadb, redis, wordpress, adminer | Database tier, fully isolated |

### What `internal: yes` Actually Does

```yaml
networks:
  data:
    internal: yes
```

A network with `internal: yes` has **no routing to the outside world**. Containers on it can only communicate with other containers on the same network. They cannot reach the internet or any external host.

```bash
# Without internal: yes
docker exec srcs-mariadb-1 curl https://google.com   # works
docker exec srcs-mariadb-1 ping 8.8.8.8             # works — security risk

# With internal: yes
docker exec srcs-mariadb-1 curl https://google.com   # fails — no route
docker exec srcs-mariadb-1 ping 8.8.8.8             # fails — no route
```

This means even if an attacker gets inside the MariaDB container, they cannot make outbound connections to download tools, send data, or reach a command-and-control server.

**Important:** `internal: yes` does NOT affect host port bindings (`ports:` in docker-compose). NGINX can still expose port 443 to the host even if its networks had `internal: yes`. The setting only blocks internet routing, not host-to-container communication.

### Attack Scenario Comparison

**Single network (old setup):**
```
Attacker exploits NGINX vulnerability
    → Gets shell in NGINX container
    → NGINX is on dev_net with MariaDB
    → Attacker runs: mysql -h mariadb -u root -p
    → Direct database access — game over
```

**3-tier network (new setup):**
```
Attacker exploits NGINX vulnerability
    → Gets shell in NGINX container
    → NGINX is only on public + app networks
    → Tries: mysql -h mariadb — network unreachable
    → MariaDB is on data network only, NGINX cannot reach it
    → Attacker is contained in app tier
```

### OWASP Rules Applied in This Project

| OWASP Rule | How We Apply It |
|---|---|
| Use user-defined networks | `public`, `app`, `data` networks defined |
| Never use `--link` | Not used anywhere |
| Never use `network: host` | Not used anywhere |
| Segment by trust level | 3-tier: public → app → data |
| Use `internal` networks | `app` and `data` are `internal: yes` |
| Minimal port exposure | Only NGINX port 443 exposed externally |
| Secrets not in env vars | Docker secrets used for all passwords |
| No passwords in Dockerfile | Passwords read at runtime from `/run/secrets/` |
| Use non-root users | WordPress runs as `www-data`, MariaDB as `mysql` |
| Specific base image versions | `debian:bookworm` (pinned version) |

### Build-Time vs Runtime Internet Access

OWASP recommends that containers should not need internet access at runtime. Any external resource should be fetched at **build time** (in the Dockerfile), not at startup.

**The problem with `wp core download` at runtime:**

```sh
# wp-config.sh — runtime, no internet on internal network
$WP core download   # tries to reach wordpress.org — FAILS
```

If WordPress is on `internal: yes` networks, this line breaks the entire setup.

**The OWASP-compliant fix — move download to Dockerfile (build time):**

```dockerfile
# Dockerfile — build time, internet is available
RUN wp core download --path=/var/www/wordpress --allow-root
```

```sh
# wp-config.sh — runtime, no internet needed
# wp core download is gone — files already exist from build
$WP config create ...   # just configure, no download
```

**Why this is more secure:**

| | Runtime download | Build-time download |
|---|---|---|
| Internet at runtime | Required | Not needed |
| Reproducible build | No (latest WP each time) | Yes (same image = same WP) |
| Attack surface | Container can reach internet | Container fully isolated |
| OWASP compliant | ❌ | ✅ |

The WordPress container now has zero outbound internet access at runtime. Even if it is compromised, the attacker cannot download tools or exfiltrate data.

### Which Containers Can Reach Which

| From → To | MariaDB | Redis | WordPress | NGINX | Internet |
|---|---|---|---|---|---|
| **NGINX** | ❌ | ❌ | ✅ | — | ✅ |
| **WordPress** | ✅ | ✅ | — | ✅ | ✅ |
| **Adminer** | ✅ | ❌ | ❌ | ✅ | ❌ |
| **MariaDB** | — | ❌ | ❌ | ❌ | ❌ |
| **Redis** | ❌ | — | ❌ | ❌ | ❌ |
| **Static** | ❌ | ❌ | ❌ | ✅ | ❌ |
| **Portainer** | ❌ | ❌ | ❌ | ✅ | ❌ |
| **FTP** | ❌ | ❌ | ✅ (volume) | ✅ | ❌ |

This table shows the principle of **least privilege** — every container can only reach what it absolutely needs.

---

## Troubleshooting

### Container Keeps Restarting

```bash
# See why it keeps failing
docker logs --tail 50 container-name

# See exit code
docker ps -a
# STATUS column: "Exited (1)" = crashed, "Exited (0)" = clean exit

# Check if it is a script permission issue
docker exec -it container-name sh
ls -la /entrypoint.sh
# Should have execute permission: -rwxr-xr-x
```

### Cannot Connect to Website

```bash
# Check if port 443 is listening
ss -tlnp | grep 443
netstat -tlnp | grep 443

# Check if NGINX container is running
docker ps | grep nginx

# Check NGINX logs
docker-compose -f srcs/docker-compose.yml logs nginx

# Test NGINX config
docker exec $(docker ps -q -f name=nginx) nginx -t

# Try connecting with curl (ignore SSL warnings)
curl -vk https://merilhan.42.fr
```

### WordPress Shows "Error establishing a database connection"

```bash
# 1. Is MariaDB running?
docker ps | grep mariadb

# 2. Check MariaDB logs
docker-compose -f srcs/docker-compose.yml logs mariadb

# 3. Check if secrets are mounted
docker exec $(docker ps -q -f name=wordpress) cat /run/secrets/db_password

# 4. Try connecting manually
docker exec -it $(docker ps -q -f name=mariadb) \
  mysql -u wp_manager -p$(cat secrets/db_password.txt) wordpress_db

# 5. Check network
docker network inspect srcs_dev_net
```

### WordPress Redirects in a Loop (302)

```bash
# Check the siteurl in the database
docker exec -it $(docker ps -q -f name=mariadb) \
  mysql -u wp_manager -p$(cat secrets/db_password.txt) wordpress_db \
  -e "SELECT option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"

# It should show: https://merilhan.42.fr
# If it shows http:// that is the problem
# Fix:
docker exec -it $(docker ps -q -f name=mariadb) \
  mysql -u wp_manager -p$(cat secrets/db_password.txt) wordpress_db \
  -e "UPDATE wp_options SET option_value='https://merilhan.42.fr' WHERE option_name IN ('siteurl', 'home');"
```

### Port Already in Use

```bash
# Find what is using port 443
sudo lsof -i :443
sudo ss -tlnp | grep 443

# Kill the process using it
sudo kill -9 PID_NUMBER

# Or change the port in docker-compose temporarily for testing
```

### Build Fails — apt-get Errors

```bash
# Clear build cache and rebuild
docker-compose -f srcs/docker-compose.yml build --no-cache

# Or for a specific service
docker-compose -f srcs/docker-compose.yml build --no-cache wordpress
```

### "No space left on device"

```bash
# See disk usage
df -h

# See Docker's disk usage
docker system df

# Clean up Docker resources
docker system prune -a

# Remove unused volumes
docker volume prune
```

### Secret File Not Found in Container

```bash
# Check if secret is mounted
docker exec container-name ls /run/secrets/

# Check file content
docker exec container-name cat /run/secrets/db_password

# If not there, check docker-compose.yml:
# 1. Secret is declared in secrets: section
# 2. Service has the secret listed under secrets:
# 3. File path in secrets: section is correct
```

### FTP Connection Issues

```bash
# Check FTP container
docker ps | grep ftp
docker-compose -f srcs/docker-compose.yml logs ftp

# Test FTP with curl
curl -v ftp://merilhan.42.fr --user ftpuser:$(cat secrets/ftp_password.txt)

# Make sure passive ports are reachable
# In FileZilla: use passive mode and these ports: 21100-21110
```

---

## Quick Reference Card

```bash
# ── THIS PROJECT ──────────────────────────────────────
make                     # start everything
make re                  # full clean rebuild
make clean               # stop containers (keep data)
make fclean              # delete everything

# ── STATUS ───────────────────────────────────────────
docker ps                # running containers
docker ps -a             # all containers
docker stats             # CPU/memory usage
docker-compose -f srcs/docker-compose.yml ps

# ── LOGS ─────────────────────────────────────────────
docker-compose -f srcs/docker-compose.yml logs -f
docker-compose -f srcs/docker-compose.yml logs -f wordpress
docker-compose -f srcs/docker-compose.yml logs -f nginx
docker logs container-name

# ── DEBUGGING ────────────────────────────────────────
docker exec -it $(docker ps -q -f name=wordpress) sh
docker exec -it $(docker ps -q -f name=mariadb) sh
docker exec -it $(docker ps -q -f name=nginx) sh
docker exec $(docker ps -q -f name=nginx) nginx -t
docker exec $(docker ps -q -f name=redis) redis-cli ping

# ── VOLUMES ──────────────────────────────────────────
docker volume ls
docker volume inspect srcs_wp_vol
ls /home/merilhan/data/wordpress/
ls /home/merilhan/data/mariadb/

# ── NETWORKS ─────────────────────────────────────────
docker network ls
docker network inspect srcs_dev_net

# ── IMAGES ───────────────────────────────────────────
docker images
docker image prune -a
docker-compose -f srcs/docker-compose.yml build --no-cache

# ── CLEANUP ──────────────────────────────────────────
docker system prune -a --volumes
docker container prune
docker volume prune
docker image prune -a

# ── DATABASE ─────────────────────────────────────────
docker exec -it $(docker ps -q -f name=mariadb) \
  mysql -u wp_manager -p$(cat secrets/db_password.txt) wordpress_db

# ── REDIS ────────────────────────────────────────────
docker exec -it $(docker ps -q -f name=redis) redis-cli
docker exec $(docker ps -q -f name=redis) redis-cli info stats

# ── WP-CLI ───────────────────────────────────────────
docker exec -it $(docker ps -q -f name=wordpress) \
  wp user list --allow-root
docker exec -it $(docker ps -q -f name=wordpress) \
  wp redis status --allow-root
```

---

## docker-compose.yml — Line by Line

```yaml
services:

  mariadb:
    build: requirements/mariadb   # build image from this Dockerfile directory
    restart: on-failure:6         # restart if it crashes, max 6 times
    env_file: .env                # load all variables from srcs/.env
    secrets:                      # mount these secret files at /run/secrets/
      - db_password
      - db_root_password
    volumes:
      - db_vol:/var/lib/mysql     # named volume → container path
    networks:
      - dev_net                   # join this internal network

  wordpress:
    build: requirements/wordpress
    restart: on-failure:6
    env_file: .env
    secrets:
      - db_password
      - wp_admin_password
      - wp_user_password
    volumes:
      - wp_vol:/var/www/wordpress
    networks:
      - dev_net
    depends_on:                   # start mariadb and redis BEFORE wordpress
      - mariadb                   # WARNING: only means "started", not "ready"
      - redis

  nginx:
    build: requirements/nginx
    restart: on-failure:6
    env_file: .env
    ports:
      - "443:443"                 # HOST:CONTAINER — expose port 443 to outside
    volumes:
      - wp_vol:/var/www/wordpress # needs WordPress files to serve them
    networks:
      - dev_net
    depends_on:
      - wordpress
      - mariadb
      - adminer
      - portainer
      - static

  ftp:
    build: requirements/ftp
    restart: on-failure
    env_file: .env
    secrets:
      - ftp_password
    ports:
      - "21:21"                   # FTP control port
      - "21100-21110:21100-21110" # FTP passive data ports (range)
    volumes:
      - wp_vol:/var/www/wordpress # FTP gives access to WordPress files
    networks:
      - dev_net
    depends_on:
      - wordpress

  redis:
    build: requirements/redis
    restart: on-failure
    networks:
      - dev_net                   # no ports exposed — only internal

  adminer:
    build: requirements/adminer
    restart: on-failure
    networks:
      - dev_net
    depends_on:
      - mariadb

  portainer:
    build: requirements/portainer
    restart: on-failure
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock  # gives portainer access to Docker
      - /home/merilhan/data/portainer:/data        # portainer saves its data here
    networks:
      - dev_net

  static:
    build: requirements/static
    restart: on-failure
    networks:
      - dev_net

networks:
  dev_net:                        # custom bridge network — all containers join this
                                  # empty = use defaults (bridge driver, auto subnet)

volumes:
  db_vol:
    driver: local                 # local driver (host machine storage)
    driver_opts:
      type: none                  # no special filesystem
      device: /home/merilhan/data/mariadb  # store data here on host
      o: bind                     # Linux mount option

  wp_vol:
    driver: local
    driver_opts:
      type: none
      device: /home/merilhan/data/wordpress
      o: bind

secrets:
  db_password:
    file: ../secrets/db_password.txt      # path relative to docker-compose.yml
  db_root_password:
    file: ../secrets/db_root_password.txt
  wp_admin_password:
    file: ../secrets/wp_admin_password.txt
  wp_user_password:
    file: ../secrets/wp_user_password.txt
  ftp_password:
    file: ../secrets/ftp_password.txt
```

---

## Makefile — Explained

```makefile
# Color codes for terminal output
CYAN    = \033[1;36m
PURPLE  = \033[1;35m
GREEN   = \033[1;32m
RED     = \033[1;31m
YELLOW  = \033[1;33m
RESET   = \033[0m

# Variables for paths and compose file
WP_DATA         = /home/merilhan/data/wordpress
DB_DATA         = /home/merilhan/data/mariadb
PORTAINER_DATA  = /home/merilhan/data/portainer
COMPOSE         = srcs/docker-compose.yml

# Default target — runs when you type just "make"
all:
	@echo "$(CYAN)=== [ MERILHAN | Inception ] ===$(RESET)"
	@mkdir -p $(WP_DATA) $(DB_DATA) $(PORTAINER_DATA)  # create data dirs if missing
	@docker-compose -f $(COMPOSE) up -d --build         # build and start
	@echo "$(GREEN)=== [ Done ] ===$(RESET)"

# Stop containers and remove volumes (data files stay)
clean:
	@echo "$(YELLOW)=== [ Stopping containers ] ===$(RESET)"
	@docker-compose -f $(COMPOSE) down -v
	@echo "$(GREEN)=== [ Done ] ===$(RESET)"

# Full cleanup — removes data files and Docker cache too
fclean: clean
	@echo "$(RED)=== [ Wiping all data ] ===$(RESET)"
	@sudo rm -rf $(WP_DATA) $(DB_DATA) $(PORTAINER_DATA)  # delete all data
	@docker system prune -af                               # remove all Docker images/cache

# Full rebuild from zero
re: fclean all

# Tell make these are not real files (prevents conflicts with files named "all", "clean" etc)
.PHONY: all clean fclean re
```

### Why `@` before commands?

By default, `make` prints every command before running it. The `@` suppresses that output.

```makefile
# Without @:
mkdir -p /home/merilhan/data   ← make prints this
# the command also runs

# With @:
@mkdir -p /home/merilhan/data  ← make does NOT print this
# the command still runs
```

### Why `-v` in `docker-compose down -v`?

Without `-v`: removes containers but keeps named volumes in Docker  
With `-v`: also removes the named volume references from Docker

Note: even with `-v`, the actual data files at `/home/merilhan/data/` are NOT deleted. Docker removes the volume metadata, but the files on disk stay. Only `rm -rf` in `fclean` removes the actual data.

---

## Container Lifecycle

A Docker container goes through these states:

```
docker create ──→ CREATED
                     │
docker start ───────→ RUNNING ←──── docker restart
                     │         │
docker pause ───────→ PAUSED   │
docker unpause ─────→ RUNNING  │
                     │         │
docker stop ────────→ STOPPED ──────→ RUNNING (docker start)
docker kill ────────→          │
                     │         │
docker rm ──────────→ DELETED  │
                               │
                    crash ─────→ STOPPED (or RESTARTING if restart policy)
```

### Checking Container State

```bash
# See current state
docker ps -a --format "table {{.Names}}\t{{.Status}}"

# Example output:
# NAMES        STATUS
# srcs-nginx   Up 2 hours
# srcs-wp      Up 2 hours
# srcs-db      Up 2 hours (healthy)
# srcs-redis   Exited (1) 5 minutes ago   ← crashed
```

---

## Restart Policies

Restart policies tell Docker what to do when a container stops or crashes.

```yaml
# docker-compose.yml
services:
  myapp:
    restart: no              # never restart (default)
    restart: always          # always restart, even on clean exit
    restart: on-failure      # restart only if exit code is not 0 (crash)
    restart: on-failure:6    # restart on crash, maximum 6 times
    restart: unless-stopped  # always restart, except when manually stopped
```

### What We Use and Why

```yaml
mariadb:
  restart: on-failure:6   # if MariaDB crashes, try 6 times then give up
                          # prevents infinite restart loop on misconfiguration

portainer:
  restart: on-failure     # no limit — portainer should always come back up
```

### Exit Codes

When a container stops, it has an exit code:
- `0` = clean exit (process finished normally)
- `1` = general error
- `2` = misuse of command
- `137` = killed by SIGKILL (docker kill or OOM killer)
- `143` = killed by SIGTERM (docker stop)

`on-failure` restarts only when exit code is NOT 0.

```bash
# Check exit codes
docker ps -a
# STATUS: "Exited (137) 2 minutes ago" → killed by signal
# STATUS: "Exited (1) 5 minutes ago"   → crashed with error
```

---

## depends_on — Limitations

`depends_on` tells Docker Compose to start services in order. But it only waits for the container to **start** — not for the service inside to be **ready**.

```yaml
wordpress:
  depends_on:
    - mariadb   # Docker starts mariadb container first
                # then starts wordpress immediately after
                # does NOT wait for MariaDB to finish initializing
```

This is why the WordPress entrypoint script uses a retry loop:

```sh
# MariaDB might be starting but not ready yet
# wp core install tries to connect — if it fails, wait and retry
until wp core install ...; do
    echo "MariaDB not ready yet, waiting..."
    sleep 2
done
```

### depends_on with condition (more advanced)

If you add a `healthcheck` to a service, you can use `condition: service_healthy`:

```yaml
services:
  mariadb:
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  wordpress:
    depends_on:
      mariadb:
        condition: service_healthy   # wait until healthcheck passes
```

We do not use this approach in the project to keep things simple, but it is the "proper" solution.

---

## Health Checks

A health check is a command Docker runs periodically to check if a container is working properly. If it fails enough times, the container is marked "unhealthy."

```dockerfile
# In Dockerfile:
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD mysqladmin ping -h localhost || exit 1

# Options:
# --interval   how often to run the check (default 30s)
# --timeout    how long to wait for the check to finish (default 30s)
# --retries    how many failures before marking unhealthy (default 3)
# --start-period  grace period on startup before checks begin
```

```yaml
# In docker-compose.yml:
services:
  mariadb:
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
```

```bash
# See health status
docker ps
# STATUS column: "Up 2 minutes (healthy)" or "Up 2 minutes (unhealthy)"

# See health check history
docker inspect --format='{{json .State.Health}}' container-name | python3 -m json.tool
```

---

## /var/run/docker.sock — How Portainer Works

`/var/run/docker.sock` is a Unix socket file. It is the way to communicate with the Docker daemon (the Docker engine running on the host).

When you run `docker ps` or `docker build`, your Docker client sends commands through this socket to the Docker daemon. The daemon does the actual work.

```
docker CLI  ──→  /var/run/docker.sock  ──→  Docker daemon  ──→  containers
```

Portainer mounts this socket inside its container:

```yaml
portainer:
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
```

This gives Portainer the ability to talk to the Docker daemon directly — to list containers, read logs, start/stop services. Portainer is essentially a web UI wrapper around the Docker API.

**Security note:** Mounting the Docker socket gives the container full control over Docker. A process inside that container can start new containers, delete volumes, do anything Docker can do. Only give this to trusted services.

---

## HTTP Status Codes — For Debugging

When something goes wrong, the HTTP status code tells you where the problem is.

### 2xx — Success

| Code | Meaning | When you see it |
|---|---|---|
| `200 OK` | Everything worked | Normal page load |
| `201 Created` | Resource created | API POST request |
| `204 No Content` | Success, no body | DELETE requests |

### 3xx — Redirects

| Code | Meaning | In this project |
|---|---|---|
| `301 Moved Permanently` | URL changed forever | WordPress migrated to HTTPS |
| `302 Found` | Temporary redirect | WordPress login, wp-admin |
| `304 Not Modified` | Use cached version | Browser cache working |

**302 loop** = WordPress `siteurl` in database is `http://` but NGINX serves `https://` → infinite redirect. Fix: update `siteurl` and `home` options in database to include `https://`.

### 4xx — Client Errors

| Code | Meaning | Common cause |
|---|---|---|
| `400 Bad Request` | Invalid request | Malformed URL or headers |
| `401 Unauthorized` | Login required | Missing authentication |
| `403 Forbidden` | No permission | File permissions wrong (`chmod`) |
| `404 Not Found` | Page does not exist | Wrong URL, missing file |
| `413 Payload Too Large` | Upload too big | WordPress upload limit |

### 5xx — Server Errors

| Code | Meaning | Common cause in this project |
|---|---|---|
| `500 Internal Server Error` | PHP crashed | PHP syntax error, wrong config |
| `502 Bad Gateway` | Upstream error | WordPress/PHP-FPM container is down |
| `503 Service Unavailable` | Server overloaded | Too many requests or container starting |
| `504 Gateway Timeout` | Upstream too slow | PHP-FPM taking too long |

```bash
# Check what status code you get
curl -sk -o /dev/null -w "%{http_code}" https://merilhan.42.fr
# Should print: 200

# See full response headers
curl -Ik https://merilhan.42.fr

# Follow redirects and show each step
curl -Lk -v https://merilhan.42.fr 2>&1 | grep -E "^[<>]"
```

---

## Multi-Stage Builds

Multi-stage builds let you use multiple `FROM` instructions in one Dockerfile. Each stage can be named. You copy files from earlier stages into later ones.

This is useful when you need build tools to compile something, but do not want those tools in the final image.

```dockerfile
# Stage 1 — build stage (has build tools, will be discarded)
FROM debian:bookworm AS builder
RUN apt-get update && apt-get install -y build-essential
COPY src/ /src/
RUN cd /src && make

# Stage 2 — final image (only has the compiled binary)
FROM debian:bookworm
COPY --from=builder /src/myapp /usr/local/bin/myapp
ENTRYPOINT ["myapp"]
```

The final image does not contain `build-essential` or the source code — only the compiled binary. Much smaller and more secure.

This project does not use multi-stage builds because all services use interpreted languages (PHP, shell scripts) that do not need compilation. But for Go, C, or Rust projects it is very useful.

---

## Useful Linux Commands Inside Containers

When you `docker exec -it container sh`, these commands help you debug:

```bash
# File system
ls -la /var/www/wordpress     # list files with permissions
find / -name "wp-config.php"  # find a file
cat /etc/nginx/nginx.conf     # read a file
du -sh /var/www/wordpress     # disk usage of directory

# Processes
ps aux                        # list all running processes
ps -p 1 -o comm=              # what is PID 1?
top                           # live process monitor (if installed)

# Network
ip addr                       # show network interfaces and IPs
ip route                      # show routing table
cat /etc/resolv.conf          # show DNS server (should be 127.0.0.11 in Docker)
cat /etc/hosts                # show hosts file

# Test network connectivity
ping mariadb                  # can we reach mariadb? (if ping installed)
nc -zv mariadb 3306           # test TCP connection to mariadb port 3306
nc -zv redis 6379             # test connection to redis

# Environment
env                           # show all environment variables
echo $DB_NAME                 # show one variable
cat /run/secrets/db_password  # read a secret

# Logs
cat /var/log/nginx/error.log  # nginx error log
cat /var/log/mysql/error.log  # mariadb error log

# PHP
php -v                        # PHP version
php -m                        # installed PHP modules
php -i | grep redis           # check if redis extension is loaded

# Permissions
id                            # current user and groups
whoami                        # current username
stat /var/www/wordpress       # detailed permissions and ownership
```
