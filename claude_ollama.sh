#!/bin/bash
# Run Claude Code using local model via LiteLLM proxy
# Auto-starts LiteLLM proxy if not already running
# Usage: ./claude_ollama.sh [any claude arguments]

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

export ANTHROPIC_BASE_URL="http://localhost:${LITELLM_PORT}"
export ANTHROPIC_API_KEY=ollama-local

# Auto-start LiteLLM proxy if not running
if ! curl -s "http://localhost:${LITELLM_PORT}/health" > /dev/null 2>&1; then
    echo "[*] LiteLLM proxy not running — starting in background..."
    "$SCRIPT_DIR/start_litellm.sh" > /tmp/litellm.log 2>&1 &
    LITELLM_PID=$!

    # Wait for proxy to be ready (max 30s)
    for i in $(seq 1 30); do
        if curl -s "http://localhost:${LITELLM_PORT}/health" > /dev/null 2>&1; then
            echo "[*] LiteLLM proxy ready (pid=$LITELLM_PID)"
            break
        fi
        if ! kill -0 "$LITELLM_PID" 2>/dev/null; then
            echo "ERROR: LiteLLM proxy failed to start. Check /tmp/litellm.log"
            exit 1
        fi
        sleep 1
    done

    if ! curl -s "http://localhost:${LITELLM_PORT}/health" > /dev/null 2>&1; then
        echo "ERROR: LiteLLM proxy did not become ready in 30s. Check /tmp/litellm.log"
        kill "$LITELLM_PID" 2>/dev/null
        exit 1
    fi

    # Cleanup LiteLLM when this script exits
    trap "kill $LITELLM_PID 2>/dev/null; wait $LITELLM_PID 2>/dev/null" EXIT
    STARTED_LITELLM=true
else
    echo "[*] LiteLLM proxy already running on port ${LITELLM_PORT}"
    STARTED_LITELLM=false
fi

if [ "$BACKEND" = "llamacpp" ]; then
    echo "[*] Backend: llama-server (${LLAMACPP_HOST}:${LLAMACPP_PORT}) model=${LLAMACPP_MODEL}"
else
    echo "[*] Backend: Ollama (${OLLAMA_HOST}:${OLLAMA_PORT}) model=${OLLAMA_MODEL}"
fi
echo "[*] Preset: ${PRESET:-instruct-general}"
echo ""
claude "$@"

# If we started LiteLLM, trap will clean it up on exit
