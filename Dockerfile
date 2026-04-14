# Dockerfile for production release
# Based on Phoenix 1.8 multi-stage build

# ---- Build Stage ----
ARG ELIXIR_VERSION=1.17.3
ARG OTP_VERSION=27.3.4.9
ARG DEBIAN_VERSION=trixie-20260223-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV="prod"

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy compile-time config
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

# Compile the project first (generates phoenix-colocated hooks)
RUN mix compile

# Then compile assets (needs colocated hooks from build path)
RUN mix assets.deploy

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

# ---- Runner Stage ----
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses6 locales ca-certificates \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app
RUN mkdir -p /app/logs /app/uploads && chown nobody:root /app/logs /app/uploads

ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/ho_mon_radeau ./

USER nobody

# If using an environment that doesn't automatically reap zombie processes,
# it is advised to add an init process such as tini via `apt-get install`
# above and adding an pointpoint. See https://github.com/krallin/tini.
# RUN apt-get install -y tini
# ENTRYPOINT ["/sbin/tini", "--"]

CMD ["/app/bin/server"]
