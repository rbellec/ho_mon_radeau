# Dockerfile for Phoenix development

FROM elixir:1.17-alpine

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    nodejs \
    npm \
    postgresql-client \
    inotify-tools

# Set working directory
WORKDIR /app

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install Phoenix
RUN mix archive.install hex phx_new --force

# Expose Phoenix port
EXPOSE 4000

# Default command (can be overridden in docker-compose)
CMD ["mix", "phx.server"]
