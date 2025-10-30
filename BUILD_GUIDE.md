# Quick Build Guide - OpenCode Split-Screen Docker

## 🎯 TL;DR - Just Build It!

```bash
# 1. Get the latest fixes
git pull origin claude/split-screen-layout-011CUcXUndUWo1T6eT5XW7vt

# 2. Configure API keys
cp .env.example .env
# Edit .env and add your ANTHROPIC_API_KEY and/or OPENAI_API_KEY

# 3. Build
./run-docker.sh build

# 4. Run
./run-docker.sh run
```

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
| `a8cacfb` | Added Python, g++, make for tree-sitter-bash compilation |
| `012700e` | Fixed Go module local replace directives issue |

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
# Should show: 012700e fix: resolve Go mod download error...

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

### Error: "Cannot find module" or "ENOENT while resolving package"

If you see errors like:
```
error: ENOENT while resolving package 'zod'
error: Cannot find module '@modelcontextprotocol/sdk/client/streamableHttp.js'
```

**Fix:** Pull the latest changes (this was fixed):
```bash
git pull origin claude/split-screen-layout-011CUcXUndUWo1T6eT5XW7vt
./run-docker.sh run
```

The issue was that the project directory was mounted to `/workspace`, overwriting the built application. It now mounts to `/project` instead.

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
| Build fails with Python error | Fixed in commit `a8cacfb` - git pull |
| Build fails with go.mod error | Fixed in commit `012700e` - git pull |
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
