# Quick Installation Guide

## One-Command Setup

After cloning the repository, install everything with:

```bash
uv sync
```

That's it! This single command:
- ✅ Creates a virtual environment with Python 3.11
- ✅ Installs fastmcp (MCP server framework)
- ✅ Installs pynput (keyboard automation for auto-trigger)
- ✅ Installs all other dependencies
- ✅ Sets up the project in editable mode

## Complete Setup Steps

1. **Install uv** (if not already installed):
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

2. **Clone the repository**:
   ```bash
   git clone https://github.com/calvinw/fl-studio-mcp.git
   cd fl-studio-mcp
   ```

3. **Install everything**:
   ```bash
   uv sync
   ```

4. **Register with Claude Code**:
   ```bash
   ./install_fl_studio_mcp_server.sh
   ```

5. **Set up FL Studio integration**:
   ```bash
   ./setup_auto_trigger.sh
   ```

   This copies `ComposeWithLLM.pyscript` to your FL Studio Piano roll scripts directory.

6. **Restart Claude Code**

## How to Use (Automatic Mode)

Once installed, follow this workflow for each session:

1. **Open FL Studio** and create or open a piano roll pattern

2. **Run ComposeWithLLM** (once per session):
   - In FL Studio: Tools → Scripting → ComposeWithLLM
   - No dialog appears - it silently initializes the system
   - This exports the current piano roll state and clears the request queue

3. **Start the auto-trigger watcher** (in a terminal):
   ```bash
   uv run python fl_studio_auto_trigger.py
   ```
   - Leave this running in the background
   - It watches for changes from Claude and automatically triggers FL Studio
   - Uses Cmd+Opt+Y (macOS) or Ctrl+Alt+Y (Windows/Linux)

4. **Talk to Claude** about what notes/chords you want
   - Claude sends requests via MCP tools
   - Auto-trigger detects changes and triggers FL Studio
   - Notes appear automatically in the piano roll (~0.5 seconds)
   - **No buttons to click** - everything is automatic!

5. **Manual edits**: If you edit notes manually in FL Studio
   - Press Cmd+Opt+Y (or Ctrl+Alt+Y) to refresh the state
   - This lets Claude see your manual changes

The `uv run` command automatically uses the virtual environment created by `uv sync`.

## What Gets Installed

From `pyproject.toml`:
- **fastmcp** - MCP server framework
- **pynput** - Keyboard automation (for auto-trigger)
- **Python 3.11** - Managed by uv via `.python-version`

## Troubleshooting

**Q: Do I need to activate the virtual environment?**
A: No! Just use `uv run python <script>` and it will use the virtual environment automatically.

**Q: Where is the virtual environment?**
A: In `.venv/` directory (created by `uv sync`)

**Q: How do I update dependencies?**
A: Run `uv sync` again after modifying `pyproject.toml`

**Q: Can I still use the virtual environment directly?**
A: Yes! Activate it with `source .venv/bin/activate` (macOS/Linux) or `.venv\Scripts\activate` (Windows)
