#!/bin/bash
# Reload LiteLLM proxy with current .env settings (without restarting Claude Code)
# Usage: ./reload_litellm.sh
# Called automatically by /preset skill after changing preset

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

# Determine backend settings
if [ "$BACKEND" = "llamacpp" ]; then
    API_BASE="http://${LLAMACPP_HOST}:${LLAMACPP_PORT}/v1"
    API_KEY="${LLAMACPP_API_KEY}"
    MODEL_NAME="openai/${LLAMACPP_MODEL}"
    BACKEND_LABEL="llama-server (${LLAMACPP_HOST}:${LLAMACPP_PORT}) model=${LLAMACPP_MODEL}"
else
    API_BASE="http://${OLLAMA_HOST}:${OLLAMA_PORT}/v1"
    API_KEY="${OLLAMA_API_KEY}"
    MODEL_NAME="openai/${OLLAMA_MODEL}"
    BACKEND_LABEL="Ollama (${OLLAMA_HOST}:${OLLAMA_PORT}) model=${OLLAMA_MODEL}"
fi

# ─── Inference presets ───
case "${PRESET:-instruct-general}" in
    ocr)
        THINKING=false; TEMP=0.4; TOP_P=0.5; TOP_K=20; MIN_P=0.0; PRESENCE_PENALTY=1.5
        PRESET_LABEL="ocr (no-think, temp=0.4, top_p=0.5)"
        ;;
    thinking-coding)
        THINKING=true; TEMP=0.6; TOP_P=0.95; PRESENCE_PENALTY=0.0
        PRESET_LABEL="thinking-coding (think, temp=0.6, top_p=0.95)"
        ;;
    thinking-general)
        THINKING=true; TEMP=1.0; TOP_P=0.95; PRESENCE_PENALTY=1.5
        PRESET_LABEL="thinking-general (think, temp=1.0, top_p=0.95)"
        ;;
    instruct-general)
        THINKING=false; TEMP=0.7; TOP_P=0.8; PRESENCE_PENALTY=1.5
        PRESET_LABEL="instruct-general (no-think, temp=0.7, top_p=0.8)"
        ;;
    instruct-reasoning)
        THINKING=false; TEMP=1.0; TOP_P=0.95; PRESENCE_PENALTY=1.5
        PRESET_LABEL="instruct-reasoning (no-think, temp=1.0, top_p=0.95)"
        ;;
    *)
        echo "ERROR: Unknown PRESET='${PRESET}'"
        exit 1
        ;;
esac

# ─── Build extra_body YAML block ───
EXTRA_BODY="
      extra_body:
        chat_template_kwargs:
          enable_thinking: ${THINKING}"
[ -n "$TOP_K" ] && EXTRA_BODY="${EXTRA_BODY}
        top_k: ${TOP_K}"
[ -n "$MIN_P" ] && EXTRA_BODY="${EXTRA_BODY}
        min_p: ${MIN_P}"

# ─── Generate litellm_config.yaml ───
CLAUDE_MODELS=(
    claude-sonnet-4-6
    claude-opus-4-6
    claude-haiku-4-6
    claude-sonnet-4-5
    claude-opus-4-5
    claude-haiku-4-5-20251001
    claude-3-5-sonnet-20241022
)

CONFIG_FILE="$SCRIPT_DIR/litellm_config.yaml"
cat > "$CONFIG_FILE" <<EOF
model_list:
EOF

for m in "${CLAUDE_MODELS[@]}"; do
    cat >> "$CONFIG_FILE" <<EOF
  - model_name: $m
    litellm_params:
      model: $MODEL_NAME
      api_base: $API_BASE
      api_key: $API_KEY
      temperature: $TEMP
      top_p: $TOP_P
      presence_penalty: $PRESENCE_PENALTY
      merge_reasoning_content_in_choices: true${EXTRA_BODY}

EOF
done

cat >> "$CONFIG_FILE" <<EOF
litellm_settings:
  drop_params: true
  set_verbose: false
EOF

unset TOP_K MIN_P

echo "[reload] Config regenerated: $CONFIG_FILE"
echo "[reload] Preset: $PRESET_LABEL"

# ─── Kill existing LiteLLM on the port ───
LITELLM_PIDS=$(lsof -ti :"${LITELLM_PORT}" 2>/dev/null)
if [ -n "$LITELLM_PIDS" ]; then
    echo "[reload] Stopping LiteLLM (pids: $LITELLM_PIDS)..."
    echo "$LITELLM_PIDS" | xargs kill 2>/dev/null
    sleep 1
    # Force kill if still running
    REMAINING=$(lsof -ti :"${LITELLM_PORT}" 2>/dev/null)
    if [ -n "$REMAINING" ]; then
        echo "$REMAINING" | xargs kill -9 2>/dev/null
        sleep 1
    fi
fi

# ─── Start new LiteLLM ───
echo "[reload] Starting LiteLLM on port ${LITELLM_PORT}..."
litellm --config "$CONFIG_FILE" --port "${LITELLM_PORT}" > /tmp/litellm.log 2>&1 &
NEW_PID=$!

# Wait for proxy to be ready (max 20s)
for i in $(seq 1 20); do
    if curl -s "http://localhost:${LITELLM_PORT}/health" > /dev/null 2>&1; then
        echo "[reload] LiteLLM ready (pid=$NEW_PID)"
        echo "[reload] Done — preset '${PRESET}' is now active."
        exit 0
    fi
    if ! kill -0 "$NEW_PID" 2>/dev/null; then
        echo "ERROR: LiteLLM failed to start. Check /tmp/litellm.log"
        exit 1
    fi
    sleep 1
done

echo "ERROR: LiteLLM did not become ready in 20s. Check /tmp/litellm.log"
exit 1
