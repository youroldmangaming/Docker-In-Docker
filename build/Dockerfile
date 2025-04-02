FROM docker:dind

# Install essential dependencies including pip for Python
RUN apk add --no-cache \
    python3 \
    py3-pip \
    nodejs \
    npm \
    curl \
    git \
    bash

# Install Docker Compose v2 (official binary method)
RUN mkdir -p /usr/libexec/docker/cli-plugins && \
    curl -SL https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-$(uname -m) -o /usr/libexec/docker/cli-plugins/docker-compose && \
    chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# Configure Docker daemon
RUN mkdir -p /etc/docker && \
    echo '{"default-ulimits": {}}' > /etc/docker/daemon.json

# Verify installations
RUN docker --version && \
    docker compose version && \
    python3 --version && \
    pip3 --version && \
    node --version && \
    npm --version

# Create symbolic link for pip command only if it doesn't exist
RUN if [ ! -e /usr/bin/pip ]; then ln -s /usr/bin/pip3 /usr/bin/pip; fi

# Health check to ensure Docker is running
HEALTHCHECK --interval=5s --timeout=3s \
    CMD docker info > /dev/null 2>&1 || exit 1

# Start Docker properly
CMD ["sh", "-c", "dockerd --host=tcp://0.0.0.0:2375 --host=unix:///var/run/docker.sock & while ! docker info > /dev/null 2>&1; do sleep 1; done && /bin/sh"]
