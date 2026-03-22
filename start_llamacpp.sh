#!/bin/bash
# Start llama-server using settings from .env
# Usage: ./start_llamacpp.sh

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ENV_FILE="$SCRIPT_DIR/.env"

# Load .env
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: .env not found at $ENV_FILE"
    exit 1
fi
set -a
source "$ENV_FILE"
set +a

if [ ! -f "$LLAMACPP_BIN" ]; then
    echo "ERROR: llama-server not found at $LLAMACPP_BIN"
    exit 1
fi

# Kill orphan llama-server processes before starting
ORPHAN_PIDS=$(pgrep -f "$(basename "$LLAMACPP_BIN")" 2>/dev/null)
if [ -n "$ORPHAN_PIDS" ]; then
    echo "[*] Killing orphan llama-server processes: $ORPHAN_PIDS"
    kill $ORPHAN_PIDS 2>/dev/null
    sleep 1
    # Force kill if still alive
    REMAINING=$(pgrep -f "$(basename "$LLAMACPP_BIN")" 2>/dev/null)
    if [ -n "$REMAINING" ]; then
        echo "[*] Force killing: $REMAINING"
        kill -9 $REMAINING 2>/dev/null
        sleep 1
    fi
fi

echo "Starting llama-server on ${LLAMACPP_HOST}:${LLAMACPP_PORT}..."
echo "Model preset: $LLAMACPP_MODELS_PRESET"
echo "Context: $LLAMACPP_CTX, Parallel slots: $LLAMACPP_NP"
echo ""

"$LLAMACPP_BIN" \
    --models-preset "$LLAMACPP_MODELS_PRESET" \
    --host "$LLAMACPP_HOST" \
    --port "$LLAMACPP_PORT" \
    --models-max "$LLAMACPP_MODELS_MAX" \
    -np "$LLAMACPP_NP" \
    -c "$LLAMACPP_CTX" \
    --path "$LLAMACPP_GUI_PATH"
