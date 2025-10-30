# Multi-stage Dockerfile for OpenCode with Split-Screen TUI
# Stage 1: Build Go TUI binary
FROM golang:1.24-bookworm AS go-builder

WORKDIR /build

# Copy all Go source code (needed for local replace directives)
COPY packages/tui ./packages/tui
COPY packages/sdk/go ./packages/sdk/go

# Download Go dependencies
WORKDIR /build/packages/tui
RUN go mod download

# Build the TUI binary with split-screen support
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /tui \
    ./cmd/opencode/main.go

# Stage 2: Build TypeScript server
FROM oven/bun:1.3.0 AS bun-builder

# Install build dependencies for native modules
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy package files
COPY package.json bun.lock bunfig.toml ./
COPY packages ./packages
COPY sdks ./sdks
COPY patches ./patches
COPY turbo.json ./

# Install dependencies
RUN bun install --frozen-lockfile

# Build packages
RUN bun run typecheck || true

# Stage 3: Runtime image
FROM oven/bun:1.3.0-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    git \
    bash \
    procps \
    curl \
    tmux \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy TUI binary from go-builder
COPY --from=go-builder /tui /usr/local/bin/opencode-tui
RUN chmod +x /usr/local/bin/opencode-tui

# Copy TypeScript application from bun-builder
COPY --from=bun-builder /build/package.json ./
COPY --from=bun-builder /build/bun.lock ./
COPY --from=bun-builder /build/bunfig.toml ./
COPY --from=bun-builder /build/node_modules ./node_modules
COPY --from=bun-builder /build/packages ./packages
COPY --from=bun-builder /build/sdks ./sdks
COPY --from=bun-builder /build/turbo.json ./

# Copy other necessary files
COPY opencode.json ./
COPY sst.config.ts ./
COPY sst-env.d.ts ./
COPY tsconfig.json ./

# Copy entrypoint and tmux scripts
COPY docker-entrypoint.sh /usr/local/bin/
COPY tmux-start.sh /app/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /app/tmux-start.sh

# Set environment variables
ENV NODE_ENV=production
ENV OPENCODE_SERVER=http://localhost:3000
ENV PATH="/usr/local/bin:${PATH}"

# Create volume for persistent data
VOLUME ["/root/.opencode"]

# Expose server port
EXPOSE 3000

# Ensure we always start in /app
WORKDIR /app

# Use the entrypoint script that starts server + TUI
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD []
