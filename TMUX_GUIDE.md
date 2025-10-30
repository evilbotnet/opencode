# OpenCode with Tmux Split-Screen

This guide explains how the tmux-based split-screen implementation works.

## Overview

Instead of implementing a custom split-screen TUI in Go, we now use **tmux** (terminal multiplexer) to provide split-screen functionality. This gives you:

- **Mature, battle-tested** terminal multiplexing
- **Full tmux features**: resize panes, scroll mode, copy mode, etc.
- **Simpler implementation**: less custom code to maintain
- **Better terminal emulation**: tmux handles all PTY complexity

## Layout

```
╔══════════════════════════╦══════════════════════════╗
║   Terminal Pane (0)      ║   OpenCode TUI (1)       ║
║                          ║                          ║
║   $ ls                   ║   > How can I help?      ║
║   $ git status           ║                          ║
║   $ vim code.py          ║   [AI Chat Interface]    ║
║                          ║                          ║
║   [Full bash shell]      ║   [Claude AI]            ║
║                          ║                          ║
╚══════════════════════════╩══════════════════════════╝
```

## Tmux Keyboard Shortcuts

### Basic Navigation
- **Ctrl+B then O** - Switch between panes (left ↔ right)
- **Ctrl+B then Arrow** - Navigate to specific pane (←↑↓→)
- **Ctrl+B then ;** - Toggle between last two active panes

### Pane Management
- **Ctrl+B then %** - Split pane vertically (add another pane)
- **Ctrl+B then "** - Split pane horizontally (add another pane)
- **Ctrl+B then x** - Close current pane (confirm with 'y')
- **Ctrl+B then z** - Zoom current pane (toggle fullscreen)

### Resizing Panes
- **Ctrl+B then Ctrl+Arrow** - Resize pane (hold Ctrl and press arrow keys)
- **Ctrl+B then Alt+Arrow** - Resize in larger increments

### Scrolling and Copy Mode
- **Ctrl+B then [** - Enter scroll/copy mode
  - Use arrow keys or Page Up/Down to scroll
  - Press **q** to exit scroll mode
  - Press **Space** to start selection, **Enter** to copy
  - **Ctrl+B then ]** - Paste copied text

### Session Management
- **Ctrl+B then d** - Detach from session (keeps running in background)
- **Ctrl+B then ?** - Show all keybindings
- **Ctrl+D** (in shell) - Exit shell/pane

## How It Works

### 1. Server Startup (`docker-entrypoint.sh`)
```bash
# Start OpenCode server
bun run packages/opencode/src/index.ts serve --port 3000 --hostname 0.0.0.0 &

# Wait for health check
while [ $WAITED -lt $MAX_WAIT ]; do
  curl -s http://localhost:3000/health && break
  sleep 1
done
```

### 2. Tmux Session Creation (`tmux-start.sh`)
```bash
# Create session with two panes
tmux new-session -d -s opencode
tmux split-window -h -t opencode:0

# Left pane: bash shell
tmux send-keys -t opencode:0.0 'cd /project && bash' C-m

# Right pane: OpenCode TUI
tmux send-keys -t opencode:0.1 '/usr/local/bin/opencode-tui' C-m

# Attach to session
tmux attach-session -t opencode
```

## Customization

### Custom Tmux Config

Create a `.tmux.conf` file in your project:

```tmux
# ~/.tmux.conf or /project/.tmux.conf

# Use Ctrl+A instead of Ctrl+B
set-option -g prefix C-a
unbind C-b
bind C-a send-prefix

# Enable mouse support
set -g mouse on

# Improve colors
set -g default-terminal "screen-256color"

# Easier pane switching (Alt+Arrow without prefix)
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1
```

Mount it in Docker:
```bash
docker run -it --rm \
  -v ~/.tmux.conf:/root/.tmux.conf \
  opencode-split-screen:latest
```

### Adjust Pane Sizes

Edit `tmux-start.sh` to change split ratios:

```bash
# Equal split (50/50) - default
tmux split-window -h -t opencode:0

# 60/40 split (terminal gets 60%)
tmux split-window -h -p 40 -t opencode:0

# 40/60 split (OpenCode gets 60%)
tmux split-window -h -p 60 -t opencode:0
```

## Advantages Over Custom Implementation

| Feature | Custom Go Split | Tmux |
|---------|----------------|------|
| Terminal emulation | Custom PTY handling | Battle-tested |
| Scrollback | Limited buffer | Unlimited scrollback |
| Copy/paste | Would need to implement | Built-in |
| Pane resizing | Would need to implement | Built-in |
| Multiple panes | Only 2 panes | Unlimited |
| Session persistence | Lost on disconnect | Detach/reattach |
| Code complexity | ~300 lines Go code | ~20 lines bash |
| User customization | Would need to implement | Full tmux config |

## Troubleshooting

### Tmux showing "no sessions"
This means the session exited. Check if:
- Server failed to start
- TUI crashed
- You exited both panes

### Can't see cursor in OpenCode pane
- Make sure you're in the right pane (Ctrl+B then O)
- Tmux might be in copy mode (press 'q' to exit)

### Terminal colors look wrong
Add to your Docker run command:
```bash
docker run -it --rm \
  -e TERM=screen-256color \
  opencode-split-screen:latest
```

### Want to start without split screen
Run OpenCode TUI directly:
```bash
docker run -it --rm \
  -e ANTHROPIC_API_KEY=xxx \
  opencode-split-screen:latest \
  /usr/local/bin/opencode-tui
```

## Advanced Usage

### Detach and Reattach
```bash
# Inside container, press Ctrl+B then d to detach
# Session keeps running in background

# Reattach from another terminal
docker exec -it <container-id> tmux attach -t opencode
```

### Multiple OpenCode Sessions
```bash
# Create additional pane with another OpenCode instance
# Press Ctrl+B then %
tmux send-keys '/usr/local/bin/opencode-tui' C-m
```

### Custom Layout Scripts

Create your own layout script:
```bash
#!/bin/bash
tmux new-session -d -s dev
tmux split-window -h
tmux split-window -v

# Pane 0: terminal
tmux select-pane -t 0
tmux send-keys 'bash' C-m

# Pane 1: OpenCode
tmux select-pane -t 1
tmux send-keys 'opencode-tui' C-m

# Pane 2: logs
tmux select-pane -t 2
tmux send-keys 'tail -f /app/logs/*.log' C-m

tmux attach -t dev
```

## Resources

- [Tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [Tmux Book](https://pragprog.com/titles/bhtmux2/tmux-2/)
- [Awesome Tmux](https://github.com/rothgar/awesome-tmux)
