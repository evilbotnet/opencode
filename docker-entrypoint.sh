#!/bin/bash
# Docker entrypoint script for OpenCode split-screen

set -e

# Start the OpenCode server in the background
cd /app
echo "Starting OpenCode server..."
bun run packages/opencode/src/server/server.ts &
SERVER_PID=$!

# Wait for server to be ready
sleep 2

# Set server URL for TUI
export OPENCODE_SERVER="http://localhost:3000"

# Run the pre-built TUI binary with split-screen support
echo "Starting OpenCode TUI with split-screen..."
exec /usr/local/bin/opencode-tui "$@"
