FROM node:24-bookworm-slim

WORKDIR /app

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    procps hostname curl git lsof openssl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN corepack enable

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY openclaw.mjs ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

RUN NODE_OPTIONS=--max-old-space-size=2048 pnpm install --frozen-lockfile

COPY . .

RUN pnpm build:docker || true
RUN pnpm ui:build || true

ENV NODE_ENV=production

HEALTHCHECK --interval=3m --timeout=10s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:18789/healthz').then((r)=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured"]
