#!/bin/bash
# Tmux startup script for OpenCode split-screen

# Create a new tmux session with split panes
tmux new-session -d -s opencode

# Split the window vertically (left and right panes)
tmux split-window -h -t opencode:0

# Left pane (0): Run bash shell
tmux send-keys -t opencode:0.0 'cd /project 2>/dev/null || cd /app' C-m
tmux send-keys -t opencode:0.0 'clear' C-m
tmux send-keys -t opencode:0.0 'echo "OpenCode Terminal (Pane 0)"' C-m
tmux send-keys -t opencode:0.0 'echo "Press Ctrl+B then O to switch panes"' C-m
tmux send-keys -t opencode:0.0 'echo "Press Ctrl+B then [ for scroll mode"' C-m
tmux send-keys -t opencode:0.0 'echo ""' C-m

# Right pane (1): Run OpenCode TUI
tmux send-keys -t opencode:0.1 'sleep 2 && /usr/local/bin/opencode-tui' C-m

# Select left pane as default
tmux select-pane -t opencode:0.0

# Attach to the session
tmux attach-session -t opencode
