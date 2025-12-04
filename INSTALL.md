# Installation Guide

## Platform Support

**⚠️ macOS Only** - This project currently only supports macOS. The auto-trigger system uses AppleScript to send keystrokes to FL Studio, which is a macOS-specific technology.

## Quick Start

Clone the repository, then run these scripts in order:

```bash
git clone https://github.com/calvinw/fl-studio-mcp.git
cd fl-studio-mcp

./install_prerequisites.sh    # Install uv and Python environment
./install_mcp_for_claude.sh   # Register with Claude Code (recommended)
./install_mcp_for_gemini.sh   # Register with Gemini CLI (optional)
./install_and_run.sh          # Set up FL Studio and start auto-trigger
```

That's it! Skip to [Usage](#usage) below.

## macOS Accessibility Permissions

The auto-trigger needs permission to send keystrokes to FL Studio. You must enable Accessibility access for **Terminal** (or your terminal app) and **Claude Code** (if using Claude Code CLI):

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Click the **+** button to add applications
3. Add **Terminal** (or iTerm, Warp, etc.)
4. Add **Claude** (Claude Code CLI) if you're using it
5. Ensure the toggles are **enabled** for each app

Without these permissions, the auto-trigger cannot send the Cmd+Opt+Y keystroke to FL Studio.

## Detailed Setup Steps

### 1. Install Prerequisites

Install `uv` (fast Python package manager) and create the virtual environment:

```bash
./install_prerequisites.sh
```

This will:
- ✅ Install `uv` if not already present (auto-detects your OS)
- ✅ Create a virtual environment with Python 3.11+
- ✅ Install all dependencies (fastmcp, pynput, etc.)

### 2. Register with Claude Code (Recommended)

Register the MCP server with Claude Code:

```bash
./install_mcp_for_claude.sh
```

This will:
- ✅ Check if `fl-studio-mcp` is already registered
- ✅ Register the MCP server with Claude Code if needed
- ✅ Provide feedback on success

Then **restart Claude Code** to load the newly registered server.

### 3. Register with Gemini CLI (Optional)

If you use Gemini CLI, register the MCP server:

```bash
./install_mcp_for_gemini.sh
```

This will:
- ✅ Check if Gemini CLI is installed
- ✅ Check if `fl-studio-mcp` is already registered
- ✅ Register the MCP server with Gemini CLI if needed

### 4. Set Up FL Studio and Start Auto-Trigger

Set up FL Studio integration and start the auto-trigger watcher:

```bash
./install_and_run.sh
```

This will:
- ✅ Copy `ComposeWithLLM.pyscript` to FL Studio's scripts directory
- ✅ Create initial JSON communication files
- ✅ Start the auto-trigger watcher in the background

**Verify installation:**
```bash
ls ~/Documents/Image-Line/FL\ Studio/Settings/Piano\ roll\ scripts/
```

Should show:
- `ComposeWithLLM.pyscript`
- `mcp_request.json`
- `mcp_response.json`
- `piano_roll_state.json`

## How to Use (Automatic Mode)

The auto-trigger script should already be running in the background after `install_and_run.sh`. For each session:

1. **Open FL Studio** and create or open a piano roll pattern

2. **Detach the piano roll window** - Click the detach icon or drag the piano roll out of the main FL Studio window. This is required for the auto-trigger to target the correct window.

3. **Run ComposeWithLLM** (once per session):
   - In FL Studio: Tools → Scripting → ComposeWithLLM
   - No dialog appears - it silently initializes the system
   - This exports the current piano roll state and clears the request queue

4. **Talk to Claude/Gemini** about what notes/chords you want
   - They send requests via MCP tools
   - Auto-trigger detects changes and automatically triggers FL Studio
   - Notes appear automatically in the piano roll (~0.5 seconds)
   - **No buttons to click** - everything is automatic!

5. **Manual edits**: If you edit notes manually in FL Studio
   - Press Cmd+Opt+Y (macOS) or Ctrl+Alt+Y (Windows/Linux) to refresh the state
   - This lets Claude/Gemini see your manual changes

### Managing the Auto-Trigger

**Check if auto-trigger is running:**
```bash
ps aux | grep "fl_studio_auto_trigger.py" | grep -v grep
```

**View logs:**
```bash
tail -f /path/to/fl-studio-mcp/auto_trigger.log
```

**Restart the auto-trigger:**
```bash
./run_auto_trigger.sh
```

**Stop the auto-trigger:**
```bash
./stop_auto_trigger.sh
```

## What Gets Installed

From `pyproject.toml`:
- **fastmcp** - MCP server framework
- **pynput** - Keyboard automation (for auto-trigger)
- **Python 3.11** - Managed by uv via `.python-version`

## Installation Scripts Overview

| Script | Purpose | When to Run |
|--------|---------|-------------|
| `install_prerequisites.sh` | Install uv and Python environment | First time only |
| `install_mcp_for_claude.sh` | Register with Claude Code | Once, then restart Claude Code |
| `install_mcp_for_gemini.sh` | Register with Gemini CLI | Once (optional) |
| `install_and_run.sh` | Setup FL Studio & start auto-trigger | First time, or to restart auto-trigger |
| `run_auto_trigger.sh` | Just start/restart the auto-trigger | Anytime you need to restart it |
| `stop_auto_trigger.sh` | Stop the auto-trigger | When you want to stop the watcher |

All scripts are:
- ✅ **Idempotent** - Safe to run multiple times
- ✅ **Smart** - Check before making changes (won't register duplicates)
- ✅ **Independent** - Can be run in any order after prerequisites

## Troubleshooting

**Q: Auto-trigger isn't running**
A: Run `./run_auto_trigger.sh` to restart it, or check logs with `tail -f auto_trigger.log`

**Q: Claude/Gemini don't see the MCP server**
A: Restart Claude Code or Gemini CLI after running the registration scripts

**Q: Notes aren't appearing**
A: Make sure you ran `ComposeWithLLM` in FL Studio first (Tools → Scripting → ComposeWithLLM). Also ensure the piano roll window is **detached** and that Terminal/Claude has **Accessibility permissions** (System Settings → Privacy & Security → Accessibility).

**Q: Virtual environment issues**
A: Run `./install_prerequisites.sh` again to rebuild it

**Q: Do I need to activate the virtual environment?**
A: No! The scripts handle it automatically. The installation scripts all use the `.venv` directly.
