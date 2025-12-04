#!/bin/bash
# FL Studio MCP - Prerequisites Installation
# Installs uv and sets up Python virtual environment

set -e  # Exit on error

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installing Prerequisites"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Define paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV_PYTHON="$SCRIPT_DIR/.venv/bin/python"

# Check if uv is installed, install if needed
if ! command -v uv &> /dev/null; then
    echo "📦 uv not found, installing automatically..."

    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        echo "   Detected macOS, installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        echo "   Detected Linux, installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows
        echo "   Detected Windows, installing uv..."
        powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
    else
        echo "❌ Unsupported OS: $OSTYPE"
        echo "   Please install uv manually: https://docs.astral.sh/uv/"
        exit 1
    fi

    # Add uv to PATH for current session (try both possible locations)
    export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

    # Verify installation
    if ! command -v uv &> /dev/null; then
        echo "❌ uv installation failed"
        echo "   Please install manually: https://docs.astral.sh/uv/"
        exit 1
    fi

    echo "✅ uv installed successfully"
else
    echo "✅ uv is already installed"
fi

# Check if virtual environment exists, create if needed
if [ ! -f "$VENV_PYTHON" ]; then
    echo "📦 Virtual environment not found, creating with uv sync..."

    # Run uv sync to create venv and install dependencies
    if uv sync; then
        echo "✅ Virtual environment created successfully"
    else
        echo "❌ Failed to create virtual environment"
        exit 1
    fi
else
    echo "✅ Virtual environment found"
fi

echo
echo "✅ Prerequisites installed successfully"
echo
