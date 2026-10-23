FROM node:26-bookworm

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gosu \
    procps \
    python3 \
    tini \
    build-essential \
    zip \
    unzip \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g \
    --allow-scripts=openclaw \
    openclaw@2026.10.6 \
  && node --version | grep -Eq '^v26\.' \
  && openclaw --version | grep -Eq '^OpenClaw 2026\.10\.6( |$)'

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm@11.24.0 \
  && pnpm install --frozen-lockfile --prod

COPY src ./src
COPY --chmod=755 entrypoint.sh ./entrypoint.sh

RUN useradd -m -s /bin/bash openclaw \
  && chown -R openclaw:openclaw /app \
  && mkdir -p /data && chown openclaw:openclaw /data

ENV PORT=8080
ENV OPENCLAW_ENTRY=/usr/local/lib/node_modules/openclaw/dist/entry.js
ENV OPENCLAW_SUPERVISOR_MODE=external
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD curl -f http://localhost:8080/setup/healthz || exit 1

USER root
ENTRYPOINT ["tini", "--", "./entrypoint.sh"]
