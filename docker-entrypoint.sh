#!/bin/bash
# Docker entrypoint script for OpenCode split-screen

set -e

# Start the OpenCode server in the background
cd /app
echo "Starting OpenCode server..."
bun run packages/opencode/src/index.ts serve --port 3000 --hostname 0.0.0.0 &
SERVER_PID=$!

# Wait for server to be ready (check health endpoint)
echo "Waiting for server to be ready..."
MAX_WAIT=30
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
  if curl -s http://localhost:3000/health > /dev/null 2>&1 || curl -s http://localhost:3000/ > /dev/null 2>&1; then
    echo "Server is ready!"
    break
  fi
  sleep 1
  WAITED=$((WAITED + 1))
  echo "Waiting... ($WAITED/$MAX_WAIT)"
done

if [ $WAITED -eq $MAX_WAIT ]; then
  echo "ERROR: Server failed to start within $MAX_WAIT seconds"
  kill $SERVER_PID 2>/dev/null || true
  exit 1
fi

# Set server URL for TUI
export OPENCODE_SERVER="http://localhost:3000"

# Run the pre-built TUI binary with split-screen support
echo "Starting OpenCode TUI with split-screen..."
exec /usr/local/bin/opencode-tui "$@"
