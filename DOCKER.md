# Docker Deployment Guide for OpenCode Split-Screen

This guide explains how to deploy OpenCode with the split-screen terminal feature using Docker.

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

Mount your project directory when running:

```bash
# Using docker-compose
docker-compose run --rm -v /path/to/project:/workspace opencode

# Using docker directly
docker run -it --rm \
  -v /path/to/project:/workspace \
  -w /workspace \
  opencode-split-screen:latest
```

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
