# Docker Deployment Guide for OpenCode Split-Screen

This guide explains how to deploy OpenCode with the split-screen terminal feature using Docker.

## ⚠️ Common Build Issues - Quick Fix

### Build Error 1: Python/tree-sitter-bash

If you encounter a **Python/tree-sitter-bash build error**, use the alternative Dockerfile:

```bash
./run-docker.sh -f Dockerfile.alternative build
# or
docker build -f Dockerfile.alternative -t opencode-split-screen:latest .
```

### Build Error 2: Go mod download error

If you see an error about `go.mod: no such file or directory`, make sure you have the latest Dockerfile:

```bash
git pull origin claude/split-screen-layout-011CUcXUndUWo1T6eT5XW7vt
./run-docker.sh build
```

See [Troubleshooting](#troubleshooting) section for more details.

## Features

The Docker deployment includes:
- **Split-screen TUI**: Terminal on the left, OpenCode chat interface on the right
- **Full shell integration**: `/bin/bash` or `/bin/sh` running in the terminal pane
- **Persistent storage**: Your OpenCode data is saved between container restarts
- **Easy pane switching**: Use `Ctrl+W` to switch between terminal and chat panes

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+ (optional, for easier management)
- At least 2GB RAM
- Terminal with good Unicode/ANSI support (for best TUI experience)

## Quick Start

### Option 1: Using Docker Compose (Recommended)

1. **Set up environment variables**

Create a `.env` file in the project root:

```bash
cat > .env << 'EOF'
ANTHROPIC_API_KEY=your_anthropic_api_key_here
OPENAI_API_KEY=your_openai_api_key_here
EOF
```

2. **Build the image**

```bash
docker-compose build
```

3. **Run OpenCode**

```bash
docker-compose run --rm opencode
```

This will start the split-screen TUI with your current directory mounted at `/workspace`.

### Option 2: Using Docker directly

1. **Build the image**

```bash
docker build -t opencode-split-screen:latest .
```

2. **Run OpenCode**

```bash
docker run -it --rm \
  -v ~/.opencode:/root/.opencode \
  -v $(pwd):/workspace \
  -w /workspace \
  -e ANTHROPIC_API_KEY=your_key \
  opencode-split-screen:latest
```

## Usage

### Starting OpenCode TUI

Once the container is running, you'll see the split-screen interface:

```
┌─────────────────────────┬─────────────────────────┐
│   Terminal Pane         │   OpenCode Pane         │
│   (bash/sh shell)       │   (AI chat interface)   │
│                         │                         │
│   $ ls                  │   > Ask me anything     │
│   $ vim file.txt        │                         │
│                         │                         │
└─────────────────────────┴─────────────────────────┘
```

### Keyboard Shortcuts

- **Ctrl+W**: Switch between terminal and OpenCode panes
- **Ctrl+C**: In terminal pane, interrupts running process
- **Ctrl+C**: In OpenCode pane, interrupts AI response
- All standard OpenCode keybindings work in the OpenCode pane

### Working with Projects

The OpenCode application runs from `/app` (where all dependencies are installed), and your project directory is mounted to `/project`:

```bash
# Using docker-compose (mounts current directory to /project)
docker-compose run --rm opencode

# Mount a specific project directory
docker-compose run --rm -v /path/to/project:/project opencode

# Using docker directly
docker run -it --rm \
  --env-file .env \
  -v /path/to/project:/project \
  opencode-split-screen:latest
```

**Important:**
- OpenCode runs from `/app` (don't change working directory!)
- Your project is accessible in the terminal pane at `/project`
- In the terminal pane, run `cd /project` to access your files
- Don't mount to `/app` as this will overwrite the built application!

### Persisting Configuration

OpenCode stores configuration in `/root/.opencode`. This is automatically persisted using a Docker volume when using docker-compose, or you can mount it:

```bash
docker run -it --rm \
  -v ~/.opencode:/root/.opencode \
  opencode-split-screen:latest
```

## Advanced Configuration

### Custom Server Port

```bash
docker run -it --rm \
  -p 3000:3000 \
  -e OPENCODE_SERVER=http://localhost:3000 \
  opencode-split-screen:latest
```

### Using Different Shell

```bash
docker run -it --rm \
  -e SHELL=/bin/zsh \
  opencode-split-screen:latest
```

### Development Mode

For development with live reload:

```bash
docker-compose run --rm \
  -v $(pwd)/packages:/app/packages \
  opencode
```

## Troubleshooting

### Runtime Error: Cannot find module / ENOENT while resolving package

If you see errors like:
```
error: ENOENT while resolving package 'zod' from '/project/packages/opencode/src/mcp/index.ts'
error: Cannot find module '@modelcontextprotocol/sdk/client/streamableHttp.js'
```

**Cause:** OpenCode is trying to run from the mounted project directory instead of from `/app` where it was built with all dependencies.

**Solution:** Make sure you have the latest version and don't specify a working directory:

```bash
git pull origin claude/split-screen-layout-011CUcXUndUWo1T6eT5XW7vt
./run-docker.sh run
```

**Key points:**
- OpenCode must run from `/app` (where it was built)
- Your project is mounted at `/project` (accessible in terminal pane)
- Don't use `-w` or `working_dir` flags that change to `/project`

**Correct usage:**
```bash
# ✅ Good - Let OpenCode run from /app
docker run -it --rm \
  --env-file .env \
  -v $(pwd):/project \
  opencode-split-screen:latest

# ❌ Bad - Don't change working directory
docker run -it --rm \
  --env-file .env \
  -v $(pwd):/project \
  -w /project \
  opencode-split-screen:latest
```

**In the container:**
- OpenCode runs from `/app` (has all dependencies)
- Terminal pane starts in `/app`
- Run `cd /project` in terminal to access your files

### Build Error: Go mod download fails (input/go.mod: no such file or directory)

If you encounter an error like:
```
go: github.com/charmbracelet/x/input@v0.3.7 (replaced by ./input):
reading input/go.mod: open /build/packages/tui/input/go.mod: no such file or directory
```

**Cause:** The Go module system needs local directories for replace directives before downloading dependencies.

**Solution:** This has been fixed in the latest Dockerfile. Update and rebuild:

```bash
git pull origin claude/split-screen-layout-011CUcXUndUWo1T6eT5XW7vt
./run-docker.sh build
```

The updated Dockerfile now copies all source code before running `go mod download`, which resolves local replace directives properly.

### Build Error: Python not found / tree-sitter-bash fails

If you encounter an error like:
```
gyp ERR! find Python
gyp ERR! find Python Python is not set from command line or npm configuration
error: install script from "tree-sitter-bash" exited with 1
```

**Solution 1: Use the updated Dockerfile**

The issue has been fixed in the latest Dockerfile which includes Python and build tools. Make sure you have the latest version:

```bash
git pull origin claude/split-screen-layout-011CUcXUndUWo1T6eT5XW7vt
./run-docker.sh build
```

**Solution 2: Use the alternative Dockerfile**

If the main Dockerfile still fails, use the alternative version which has more comprehensive build dependencies:

```bash
# Using the helper script
./run-docker.sh -f Dockerfile.alternative build

# Using docker directly
docker build -f Dockerfile.alternative -t opencode-split-screen:latest .
```

**Solution 3: Build without frozen lockfile**

If you're still having issues, the alternative Dockerfile doesn't use `--frozen-lockfile`, which can help with dependency resolution issues.

### Terminal doesn't render properly

Ensure your terminal supports:
- UTF-8 encoding
- ANSI color codes
- Proper TERM environment variable

Try:
```bash
docker run -it --rm \
  -e TERM=xterm-256color \
  opencode-split-screen:latest
```

### Split-screen is not showing

The split-screen mode is enabled by default in this build. If you see only the standard interface, check:

1. Container was built with the latest code from branch `claude/split-screen-layout-011CUcXUndUWo1T6eT5XW7vt`
2. Terminal window is wide enough (minimum 80 columns recommended)

### Container exits immediately

Make sure you're running with `-it` flags for interactive mode:

```bash
docker run -it opencode-split-screen:latest
```

### Permission issues with mounted volumes

On Linux, you may need to adjust permissions:

```bash
docker run -it --rm \
  --user $(id -u):$(id -g) \
  -v $(pwd):/workspace \
  opencode-split-screen:latest
```

### Build takes too long

The Docker build includes compiling native modules which can take time. To speed up:

1. Use Docker BuildKit (enabled by default in newer Docker versions)
2. Ensure you have enough RAM allocated to Docker (4GB recommended)
3. On first build, it downloads all dependencies - subsequent builds use cache

### Architecture-specific issues (ARM64/Apple Silicon)

If you're on Apple Silicon (M1/M2/M3) or ARM64:

1. The build should work but may take longer
2. If you encounter issues, try building with platform specification:

```bash
docker build --platform linux/arm64 -t opencode-split-screen:latest .
```

3. Some dependencies might need Rosetta 2 on macOS - ensure it's installed

## Building from Source

To build with custom modifications:

1. Make your changes to the code
2. Rebuild the image:

```bash
docker build --no-cache -t opencode-split-screen:custom .
```

3. Run your custom build:

```bash
docker run -it --rm opencode-split-screen:custom
```

## Production Deployment

For production deployments:

1. Use specific version tags instead of `latest`
2. Set up proper secrets management for API keys
3. Configure resource limits:

```yaml
services:
  opencode:
    # ... other config ...
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
```

## Support

For issues specific to the Docker deployment, please check:
- [OpenCode Documentation](https://github.com/sst/opencode)
- [Docker Documentation](https://docs.docker.com/)

For issues with the split-screen feature, refer to the implementation in branch `claude/split-screen-layout-011CUcXUndUWo1T6eT5XW7vt`.
