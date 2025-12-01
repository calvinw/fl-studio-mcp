# FL Studio MCP Bridge

An MCP (Model Context Protocol) server that enables AI assistants like Claude to interact with FL Studio's piano roll. Create melodies, chord progressions, and musical patterns through natural language conversation.

## Overview

This bridge allows you to:
- Generate chord progressions by name or custom notes
- Create melodies and bass lines
- Modify existing MIDI notes
- Export and analyze piano roll state
- Preview changes before committing

The system uses a request queue pattern where changes accumulate and can be previewed before being applied to your FL Studio project.

## Prerequisites

- **FL Studio** (any recent version with Python scripting support)
- **Python 3.8+**
- **MCP-compatible client** (Claude Desktop, Claude Code CLI, or other MCP client)
- **uv** (Fast Python package manager - [installation guide](https://docs.astral.sh/uv/getting-started/installation/))

## Installation

### 1. Clone or Download This Repository

```bash
git clone https://github.com/calvinw/fl-studio-mcp.git
cd fl-studio-mcp
```

### 2. Set Up Python Environment

Create a virtual environment and install dependencies using `uv`:

```bash
# Create virtual environment
uv venv

# Install the project and its dependencies
uv pip install -e .
```

### 3. Install the MCP Server

Run the installation script to register the MCP server with Claude Code:

```bash
./install_fl_studio_mcp_server.sh
```

This will register the FL Studio MCP server with Claude Code.

### 4. Set Up FL Studio Bridge Script

Copy the bridge script to FL Studio's piano roll scripts directory:

```bash
# macOS/Linux
cp call_llm.pyscript \
  "$HOME/Documents/Image-Line/FL Studio/Settings/Piano roll scripts/"

# Windows
copy call_llm.pyscript \
  "%USERPROFILE%\Documents\Image-Line\FL Studio\Settings\Piano roll scripts\"
```

Access in FL Studio: **Tools → Scripting → call_llm**

**Note:** Whenever you make changes to the script, re-copy it to the FL Studio directory.

### 5. Restart Claude Code

Restart Claude Code to load the newly registered MCP server.

### 6. Configure Communication Files

The system uses JSON files for communication. By default, they're stored in:

**macOS/Linux:**
```
~/Documents/Image-Line/FL Studio/Settings/Piano roll scripts/
```

**Windows:**
```
%USERPROFILE%\Documents\Image-Line\FL Studio\Settings\Piano roll scripts\
```

The following files will be created automatically:
- `mcp_request.json` - Request queue
- `mcp_response.json` - Execution results
- `piano_roll_state.json` - Exported piano roll state

## Usage

### Starting a Session

1. **Open FL Studio** and create or open a project
2. **Open the Piano Roll** for any instrument
3. **Launch the bridge script:**
   - Go to: **Tools → Scripting → call_llm**
   - This exports the current state and clears the request queue

### Working with Your AI Assistant

Once the bridge is running, you can interact with your AI assistant:

```
You: "Create a sad chord progression in Am"

Claude: [Sends chord progression]
"I've created an Am-F-C-G progression. Click 'Regenerate' in FL Studio to preview."

You: [Click Regenerate button]
[Preview the changes]

You: "Add a bass line"

Claude: [Sends bass notes]
"Added bass notes. Click 'Regenerate' again to hear it."

You: [Click Regenerate]
[Preview with bass]

You: [If satisfied] Click "Accept"
[Changes committed to piano roll]
```

### Bridge Script Buttons

- **Regenerate**: Preview all queued changes (doesn't commit)
- **Accept**: Commit changes to piano roll and close dialog
- **Close/Cancel**: Discard all pending changes

### Example Requests

- "Create a I-IV-V-I progression in C major"
- "Add a pentatonic melody over these chords"
- "Generate a drum pattern with kick on 1 and 3, snare on 2 and 4"
- "Change that G note to an A"
- "Add a bass note on the root of each chord"
- "Clear everything and create a jazz progression"

## Available Commands

Your AI assistant has access to these tools:

- `get_piano_roll_state()` - Read current notes
- `send_notes(notes, mode)` - Add/replace notes
- `create_chord_from_name(chord_name, root_note, ...)` - Create chord by name
- `delete_notes(notes)` - Remove specific notes
- `clear_queue()` - Discard pending changes

See [CLAUDE.md](CLAUDE.md) for detailed documentation on how the AI assistant uses these tools.

## How It Works

```
┌─────────┐         ┌────────────┐         ┌──────────────┐
│ Claude  │────────▶│ MCP Server │────────▶│ Request Queue│
└─────────┘         └────────────┘         │ (JSON file)  │
                                           └──────┬───────┘
                                                  │
                                                  ▼
┌─────────────┐         ┌─────────────────────────────────┐
│ Piano Roll  │◀────────│ FL Studio Bridge Script         │
└─────────────┘         │ (reads queue, applies changes)  │
                        └─────────────────────────────────┘
                                     │
                                     ▼
                              ┌─────────────┐
                              │ State Export│
                              │ (JSON file) │
                              └─────────────┘
```

1. AI assistant sends musical requests via MCP tools
2. MCP server writes requests to JSON queue
3. User clicks "Regenerate" in FL Studio
4. Bridge script reads queue and applies changes (preview mode)
5. User clicks "Accept" to commit or continues making changes

## Configuration

### Custom File Locations

By default, communication files are stored in FL Studio's scripts directory. To use a different location, edit `fl_studio_mcp_server.py`:

```python
# Find these lines and update the paths
BASE_DIR = Path.home() / "Documents/Image-Line/FL Studio/Settings/Piano roll scripts"
REQUEST_FILE = BASE_DIR / "mcp_request.json"
STATE_FILE = BASE_DIR / "piano_roll_state.json"
```

**Important:** If you change these paths, you must also update them in `call_llm.pyscript` to match.

### Supported Chord Types

The `create_chord_from_name` tool supports:
- Basic: `major`, `minor`, `dim`, `aug`
- Seventh: `maj7`, `min7`, `dom7`
- Suspended: `sus2`, `sus4`
- Extended: `maj9`, `min9`

## Troubleshooting

### Script Not Appearing in FL Studio

**Problem:** Bridge script doesn't show in Tools menu

**Solutions:**
- Verify the file is in the correct directory (see step 3)
- Ensure file has `.pyscript` extension
- Restart FL Studio
- Check FL Studio version supports Python scripting

### Changes Not Appearing

**Problem:** Sent requests but nothing happens

**Solutions:**
- Make sure you clicked "Regenerate" button
- Check that MCP server is running
- Verify file paths in both the MCP server and bridge script match
- Look at `mcp_request.json` - should contain your requests

### MCP Server Not Connecting

**Problem:** AI assistant doesn't have FL Studio tools

**Solutions:**
- Restart your MCP client (Claude Desktop/Code)
- Verify configuration file has correct path to `fl_studio_mcp_server.py`
- Ensure virtual environment is created: `uv venv` and dependencies installed: `uv pip install -e .`

### Notes at Wrong Positions

**Problem:** Notes appear at incorrect times

**Solutions:**
- Time values should be in quarter notes, not ticks
- `time=0` is beat 1, `time=4` is beat 5 (measure 2 in 4/4)
- Check PPQ value in state export for reference

### Permission Errors

**Problem:** Cannot write to JSON files

**Solutions:**
- Ensure FL Studio scripts directory exists
- Check file permissions (should be read/write)
- On Windows, may need to run FL Studio as administrator

## Development

### Making Changes

1. Edit files in this repository
2. Copy updated `call_llm.pyscript` to FL Studio scripts directory
3. Reload the bridge script in FL Studio

### Debugging

Enable debug output by checking the console/terminal where your MCP client is running. The server logs all requests and responses.

## Architecture

- **MCP Server** (`fl_studio_mcp_server.py`) - Exposes tools to AI assistants
- **Bridge Script** (`call_llm.pyscript`) - Runs inside FL Studio
- **Communication Files** (JSON) - Request queue and state export
- **CLAUDE.md** - AI assistant documentation

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - feel free to use and modify for your projects.

## Support

For issues, questions, or feature requests, please open an issue on GitHub.

## Acknowledgments

Built using the [Model Context Protocol](https://modelcontextprotocol.io/) specification.
