# Vanilla Terraria dedicated server
# The official Linux server binary is x86_64 only.
FROM debian:bookworm-slim AS download

ARG TERRARIA_VERSION=1461

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/server.zip \
        "https://terraria.org/api/download/pc-dedicated-server/terraria-server-${TERRARIA_VERSION}.zip" \
    && unzip -q /tmp/server.zip -d /tmp/server \
    && mv "/tmp/server/${TERRARIA_VERSION}/Linux" /opt/terraria \
    && chmod +x /opt/terraria/TerrariaServer.bin.x86_64 \
    && rm -rf /tmp/server /tmp/server.zip

FROM debian:bookworm-slim

ARG TERRARIA_VERSION=1461

LABEL org.opencontainers.image.title="terraria" \
      org.opencontainers.image.description="Vanilla Terraria dedicated server" \
      org.opencontainers.image.source="https://github.com/bfcoder/terraria" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${TERRARIA_VERSION}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates tini procps \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --uid 1000 --create-home --home-dir /home/terraria terraria \
    && mkdir -p /data/worlds \
    && chown -R terraria:terraria /data

COPY --from=download /opt/terraria /opt/terraria
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY terraria-cmd /usr/local/bin/terraria-cmd
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/terraria-cmd

ENV TERRARIA_VERSION=${TERRARIA_VERSION} \
    WORLD_NAME=world \
    WORLD_SIZE=2 \
    DIFFICULTY=0 \
    MAX_PLAYERS=8 \
    PORT=7777 \
    PASSWORD="" \
    MOTD="" \
    SEED="" \
    SECURE=1 \
    LANGUAGE=en-US \
    NPC_STREAM=60 \
    PRIORITY=1 \
    UPNP=0

USER terraria
WORKDIR /data
VOLUME ["/data"]
EXPOSE 7777/tcp

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
