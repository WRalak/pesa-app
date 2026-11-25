# syntax=docker/dockerfile:1.7
# ---- deps: production dependencies only (argon2 ships prebuilt binaries) ----
FROM node:26-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts=false && npm cache clean --force

# ---- runtime: minimal, non-root, read-only friendly ----
FROM node:26-alpine AS runtime
ENV NODE_ENV=production \
    NODE_OPTIONS="--enable-source-maps --max-old-space-size=768"
# No extra OS packages: smaller attack surface. Signal handling is done in
# src/server.js; run with an init (compose `init: true`, ECS initProcessEnabled).
RUN addgroup -S pesa && adduser -S pesa -G pesa
WORKDIR /app
COPY --from=deps --chown=pesa:pesa /app/node_modules ./node_modules
COPY --chown=pesa:pesa package.json ./
COPY --chown=pesa:pesa src ./src
COPY --chown=pesa:pesa scripts ./scripts
USER pesa
EXPOSE 4000
ARG APP_VERSION=dev
ENV APP_VERSION=$APP_VERSION
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=3 \
  CMD wget -qO- http://127.0.0.1:4000/health/live || exit 1
# Same image runs the API (default) or the worker: `node src/worker.js`.
CMD ["node", "src/server.js"]
