# Quick Build Guide - OpenCode Split-Screen Docker

## 🎯 TL;DR - Just Build It!

```bash
# 1. Get the latest fixes
git pull origin claude/split-screen-layout-011CUcXUndUWo1T6eT5XW7vt

# 2. Configure API keys
cp .env.example .env
# Edit .env and add your ANTHROPIC_API_KEY and/or OPENAI_API_KEY

# 3. Build (from the opencode repository directory)
./run-docker.sh build

# 4. Run (IMPORTANT: Don't mount opencode repo to /project!)
# Option A: Run without mounting anything (explore OpenCode)
docker run -it --rm --env-file .env opencode-split-screen:latest

# Option B: Mount your actual project directory (recommended)
docker run -it --rm --env-file .env \
  -v ~/my-actual-project:/project \
  opencode-split-screen:latest
```

**⚠️ Important:** The `./run-docker.sh run` script mounts the current directory to `/project`. If you run it from inside the opencode repository, it will cause errors! Use the docker commands above instead, or run from a different directory.

That's it! 🚀

## 📋 What Was Fixed

You encountered two common Docker build errors. Both have been fixed:

### Error 1: Python/tree-sitter-bash ✅ FIXED
```
gyp ERR! find Python
error: install script from "tree-sitter-bash" exited with 1
```

**Fix:** Added Python and build tools to the Dockerfile.

### Error 2: Go mod download ✅ FIXED
```
go.mod: open /build/packages/tui/input/go.mod: no such file or directory
```

**Fix:** Restructured Dockerfile to copy source before downloading Go modules.

## 🔄 Latest Changes Summary

| Commit | What It Fixed |
|--------|--------------|
| `bfd4c49` | Added proper server health check and startup wait (30s timeout) |
| `7b08047` | Bypass TypeScript wrapper and run pre-built TUI binary directly |
| `bdb8dd8` | Use absolute path in ENTRYPOINT and clarify project mounting |
| `64f1d3d` | Remove working directory override to run OpenCode from /app |
| `647b284` | Resolve module resolution errors by changing volume mount path |

## 📦 Files You Now Have

```
opencode/
├── Dockerfile                 # Main Dockerfile (use this)
├── Dockerfile.alternative     # Fallback if main fails
├── docker-compose.yml         # Easy orchestration
├── run-docker.sh             # Helper script (recommended)
├── .env.example              # Template for API keys
├── DOCKER.md                 # Full documentation
└── BUILD_GUIDE.md            # This file
```

## ✅ Verification Steps

After pulling the latest changes, verify everything is ready:

```bash
# Check you're on the right branch
git branch
# Should show: * claude/split-screen-layout-011CUcXUndUWo1T6eT5XW7vt

# Check latest commit
git log --oneline -1
# Should show: bfd4c49 fix: add proper server health check and startup wait

# Check files exist
ls -la Dockerfile run-docker.sh .env.example
```

## 🚀 Build Commands

### Option 1: Using Helper Script (Easiest)

```bash
# Build
./run-docker.sh build

# Run
./run-docker.sh run

# Get help
./run-docker.sh --help
```

### Option 2: Using docker-compose

```bash
# Build
docker-compose build

# Run
docker-compose run --rm opencode
```

### Option 3: Using Docker directly

```bash
# Build
docker build -t opencode-split-screen:latest .

# Run
docker run -it --rm \
  --env-file .env \
  -v ~/.opencode:/root/.opencode \
  -v $(pwd):/workspace \
  -w /workspace \
  opencode-split-screen:latest
```

## 🔧 If You Get Runtime Errors

### Error: "Cannot find module" or "ENOENT while resolving package" ✅ FIXED

If you see errors like:
```
error: ENOENT while resolving package 'zod'
error: Cannot find module '@modelcontextprotocol/sdk/client/streamableHttp.js'
```

**Status:** Fixed in commits `647b284`, `64f1d3d`, `bdb8dd8`

**What was wrong:** The container was trying to run OpenCode from the mounted project directory instead of from `/app` where it was built with all dependencies.

**How it works now:**
- OpenCode runs from `/app` (has all node_modules)
- Your project is mounted at `/project`
- In the terminal pane, run `cd /project` to access your files

### Error: "bun: command not found: go" ✅ FIXED

If you see:
```
bun: command not found: go
ShellError: Failed with exit code 1
```

**Status:** Fixed in commit `7b08047`

**What was wrong:** On M2 Mac (ARM64), the TypeScript wrapper was trying to build the Go TUI binary at runtime, but Go wasn't installed in the runtime container.

**How it works now:** The Go TUI binary is pre-built during the Docker build stage and executed directly via `/usr/local/bin/opencode-tui`, bypassing the TypeScript wrapper.

### Error: "dial tcp [::1]:3000: connect: connection refused" ✅ FIXED

If you see:
```
panic: Get "http://localhost:3000/project/current": dial tcp [::1]:3000: connect: connection refused
```

**Status:** Fixed in commit `bfd4c49`

**What was wrong:** The TUI was starting before the server was fully ready to accept connections.

**How it works now:** The entrypoint script now:
1. Starts the server in background
2. Waits up to 30 seconds for server health check to pass
3. Only then starts the TUI client
4. If server fails to start, exits with error message

## 🔧 If Build Still Fails

### Try the alternative Dockerfile:

```bash
./run-docker.sh -f Dockerfile.alternative build
```

This version has:
- Even more comprehensive build dependencies
- No frozen lockfile (more flexible)
- Additional debugging tools

### Check Docker resources:

Ensure Docker has enough resources:
- **RAM**: At least 4GB allocated to Docker
- **Disk**: At least 10GB free space
- **CPU**: At least 2 cores

On Docker Desktop:
- Settings → Resources → Adjust Memory to 4GB+

## 🎨 What You'll Get

Once running, you'll see the split-screen interface:

```
╔════════════════════════╦════════════════════════╗
║  Terminal Pane         ║  OpenCode Pane         ║
║  ──────────────         ║  ──────────────         ║
║                        ║                        ║
║  $ ls                  ║  > How can I help?     ║
║  $ vim code.py         ║                        ║
║  $ git status          ║  [AI Chat Interface]   ║
║                        ║                        ║
║  [Full bash shell]     ║  [Claude AI]           ║
║                        ║                        ║
╚════════════════════════╩════════════════════════╝

Press Ctrl+W to switch between panes
```

## ⌨️ Keyboard Shortcuts

- **Ctrl+W** - Switch between terminal and AI panes
- **Ctrl+C** - Interrupt (works in both panes)
- **Ctrl+D** or type `exit` twice - Exit OpenCode

## 📊 Expected Build Time

- **First build**: 5-10 minutes (downloads and compiles everything)
- **Subsequent builds**: 1-2 minutes (uses Docker cache)

Progress you should see:
```
[+] Building 320.5s (28/28) FINISHED
 => [go-builder]  Download Go dependencies        25.2s
 => [go-builder]  Build TUI binary                58.1s
 => [bun-builder] Install npm dependencies        145.3s
 => [stage-3]     Copy artifacts                   4.5s
 => exporting to image                             7.4s
```

## 🆘 Need More Help?

1. **Quick fixes**: See the warning box at top of `DOCKER.md`
2. **Detailed troubleshooting**: See Troubleshooting section in `DOCKER.md`
3. **All commands**: Run `./run-docker.sh --help`
4. **Latest updates**: `git pull origin claude/split-screen-layout-011CUcXUndUWo1T6eT5XW7vt`

## 🎯 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Build fails with Python error | Fixed - git pull latest changes |
| Build fails with go.mod error | Fixed - git pull latest changes |
| Module resolution errors (ENOENT) | Fixed in commit `647b284` - git pull |
| "command not found: go" error | Fixed in commit `7b08047` - git pull |
| Connection refused on port 3000 | Fixed in commit `bfd4c49` - git pull |
| Build still fails | Use `./run-docker.sh -f Dockerfile.alternative build` |
| Container exits immediately | Make sure you use `-it` flags |
| Terminal looks weird | Set `-e TERM=xterm-256color` |
| Permission denied | Run with `--user $(id -u):$(id -g)` |

## ✨ You're Ready!

Everything is fixed and ready to go. Just run:

```bash
git pull origin claude/split-screen-layout-011CUcXUndUWo1T6eT5XW7vt
./run-docker.sh build
./run-docker.sh run
```

Enjoy your split-screen OpenCode! 🎉
