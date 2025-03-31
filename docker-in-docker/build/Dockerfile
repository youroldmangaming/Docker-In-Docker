FROM docker:dind

# Install docker-compose v2 directly from GitHub releases
RUN apk add --no-cache curl \
    && curl -SL https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-$(uname -m) -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Verify installations
RUN docker --version && docker-compose --version

# Configure Docker daemon to avoid the ulimit issue
RUN mkdir -p /etc/docker \
    && echo '{"default-ulimits": {}}' > /etc/docker/daemon.json

# Start Docker in the background
CMD ["dockerd"]
