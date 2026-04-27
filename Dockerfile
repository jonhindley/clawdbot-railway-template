# STAGE 1: Build the OpenClaw Engine
FROM node:22-bookworm AS openclaw-build
RUN apt-get update && apt-get install -y git curl python3 make g++
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"
RUN corepack enable
WORKDIR /openclaw
# This pulls the 'main' branch to fix the Pairing Bar issue
RUN git clone --depth 1 --branch "main" https://github.com/openclaw/openclaw.git .
RUN pnpm install --no-frozen-lockfile && pnpm build && pnpm ui:install && pnpm ui:build

# STAGE 2: Runtime
FROM node:22-bookworm
# This installs the Browser inside the Docker container
RUN npx -y playwright install-deps chromium && npx -y playwright install chromium
WORKDIR /app
COPY --from=openclaw-build /openclaw /openclaw
RUN printf '#!/usr/bin/env bash\nexec node /openclaw/dist/entry.js "$@"' > /usr/local/bin/openclaw && chmod +x /usr/local/bin/openclaw
COPY . .
RUN npm install --omit=dev
EXPOSE 8080
CMD ["node", "src/server.js"]
