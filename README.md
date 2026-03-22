# Claude Code + Local LLM

> Run **[Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)** with fully local models — via **Ollama** or **llama-server** (llama.cpp). No API cost, no internet required. Supports **vision/OCR** with multimodal models.

![Python](https://img.shields.io/badge/Python-3.8%2B-blue?logo=python&logoColor=white)
![LiteLLM](https://img.shields.io/badge/LiteLLM-proxy-green)
![Ollama](https://img.shields.io/badge/Ollama-local%20AI-orange)
![llama.cpp](https://img.shields.io/badge/llama.cpp-local%20AI-red)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

## What is Claude Code?

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) is Anthropic's official CLI tool that turns Claude into an AI coding assistant running directly in your terminal. It can:

- Read, search, and edit files in your project
- Execute shell commands
- Read images and perform OCR (with multimodal models)
- Run multi-turn conversations with full context of your project

By default, Claude Code connects to Anthropic's cloud API (requires a paid API key). **This project lets you run Claude Code against a local model instead** — completely free and private.

---

## How It Works

Claude Code speaks Anthropic's API format. Local models (Ollama, llama-server) speak OpenAI's API format. **[LiteLLM](https://github.com/BerriAI/litellm)** sits in the middle and translates between them:

```
┌─────────────┐  Anthropic format  ┌─────────────┐  OpenAI format  ┌──────────────────┐
│ Claude Code │ ─────────────────▶ │   LiteLLM   │ ─────────────▶ │  Ollama          │
│ (CLI)       │ ◀───────────────── │   Proxy     │ ◀───────────── │  or llama-server │
└─────────────┘                    └─────────────┘                 └──────────────────┘
```

A single **`.env`** file controls which backend to use, model settings, and thinking mode. The wrapper script `claude_ollama.sh` auto-starts LiteLLM, connects everything, and cleans up on exit — **one command to launch**.

---

## Supported Backends

| Backend | Description | When to use |
|---|---|---|
| **[Ollama](https://ollama.com)** | Model manager + inference server | Easiest setup, many models available via `ollama pull` |
| **[llama-server](https://github.com/ggerganov/llama.cpp)** (llama.cpp) | Lightweight inference server | Full control over GGUF models, context size, parallel slots, vision (mmproj) |

---

## Prerequisites

| Requirement | Version | Install |
|---|---|---|
| **Claude Code CLI** | latest | `npm install -g @anthropic-ai/claude-code` |
| **Python** | 3.8+ | System package manager or [python.org](https://python.org) |
| **LiteLLM** | latest | `pip install 'litellm[proxy]'` (see below) |
| **Ollama** | latest | [ollama.com](https://ollama.com) — if using Ollama backend |
| **llama.cpp** | latest | [Build from source](https://github.com/ggerganov/llama.cpp) — if using llama-server backend |

---

## Installation

### 1. Clone this repo

```bash
git clone <repo-url>
cd claude_code_ollama
```

### 2. Install LiteLLM

> **Important:** Install `litellm[proxy]`, not just `litellm`. The `[proxy]` extras include server dependencies (uvicorn, fastapi, etc.) required to run the proxy.

**Recommended — use a virtual environment:**

```bash
python3 -m venv ~/venv/litellm
source ~/venv/litellm/bin/activate
pip install 'litellm[proxy]'
```

**Or global install:**

```bash
pip install 'litellm[proxy]'
```

**Verify:**

```bash
which litellm
litellm --version
```

> If `command not found` after installing in a venv, activate it first: `source ~/venv/litellm/bin/activate`

### 3. Make scripts executable

```bash
chmod +x claude_ollama.sh start_litellm.sh start_llamacpp.sh
```

---

## Configuration (.env)

All settings are in a single **`.env`** file. Edit it once, and all scripts read from it automatically. `litellm_config.yaml` is **auto-generated** — do not edit it manually.

```bash
# Backend: "ollama" or "llamacpp"
BACKEND=ollama

# === Ollama settings ===
OLLAMA_HOST=localhost
OLLAMA_PORT=7869
OLLAMA_MODEL=gpt-oss:120b
OLLAMA_API_KEY=ollama

# === llama-server (llama.cpp) settings ===
LLAMACPP_HOST=127.0.0.1
LLAMACPP_PORT=8081
LLAMACPP_MODEL=Qwen3.5-27B
LLAMACPP_API_KEY=none
LLAMACPP_BIN=/path/to/llama.cpp/build/bin/llama-server
LLAMACPP_MODELS_PRESET="/path/to/model-preset.ini"
LLAMACPP_NP=5              # parallel inference slots
LLAMACPP_CTX=8192           # context window size
LLAMACPP_MODELS_MAX=1
LLAMACPP_GUI_PATH="/path/to/gui"

# === LiteLLM proxy settings ===
LITELLM_PORT=4000

# === Thinking model settings ===
# "true"  = disable thinking (recommended: faster, vision/OCR works correctly)
# "false" = keep thinking enabled (better for complex reasoning, but slower)
DISABLE_THINKING=true
```

### Key settings

| Setting | What to change |
|---|---|
| `BACKEND` | `ollama` or `llamacpp` — switches the entire pipeline |
| `OLLAMA_PORT` | Default Ollama port is `11434`. Change if yours differs |
| `OLLAMA_MODEL` | Exact model name from `ollama list` |
| `LLAMACPP_BIN` | Absolute path to your `llama-server` binary |
| `LLAMACPP_MODELS_PRESET` | Path to your model's `.ini` preset file |
| `LLAMACPP_CTX` | Context window size (e.g., `8192`, `32768`, `220000`) |
| `LLAMACPP_NP` | Number of parallel inference slots |
| `DISABLE_THINKING` | `true` to disable thinking mode (see [Pitfalls](#-thinking-models-empty-responses-and-visionocr-failure)) |

---

## Usage

### Option A: Ollama backend

```bash
# 1. Set BACKEND=ollama in .env (one-time)

# 2. Make sure Ollama is running with your model
ollama pull gpt-oss:120b    # if not already pulled

# 3. Launch Claude Code (auto-starts LiteLLM proxy)
./claude_ollama.sh
```

### Option B: llama-server backend

```bash
# 1. Set BACKEND=llamacpp in .env (one-time)

# 2. Start llama-server (Terminal 1)
./start_llamacpp.sh

# 3. Launch Claude Code (Terminal 2 — auto-starts LiteLLM proxy)
./claude_ollama.sh
```

### Passing arguments to Claude Code

```bash
./claude_ollama.sh -p "explain this codebase"
./claude_ollama.sh --dangerously-skip-permissions
```

### Running without the wrapper script

```bash
ANTHROPIC_BASE_URL=http://localhost:4000 ANTHROPIC_API_KEY=ollama-local claude
```

---

## What happens when you run `./claude_ollama.sh`

1. Loads settings from `.env`
2. Checks if LiteLLM proxy is already running on the configured port
3. If not running, starts LiteLLM in the background (logs to `/tmp/litellm.log`)
4. Waits for LiteLLM to become healthy (up to 30 seconds)
5. Launches `claude` CLI with `ANTHROPIC_BASE_URL` pointing to LiteLLM
6. When you exit Claude Code, automatically kills the LiteLLM proxy it started

**One command. No manual terminal juggling.**

---

## Project Structure

```
claude_code_ollama/
├── .env                   # All configuration (backend, ports, model, paths, thinking)
├── claude_ollama.sh       # Main entry point — auto-starts LiteLLM, launches Claude Code
├── start_litellm.sh       # Generates litellm_config.yaml from .env and starts LiteLLM
├── start_llamacpp.sh      # Starts llama-server from .env settings
├── litellm_config.yaml    # Auto-generated by start_litellm.sh (do not edit manually)
├── CLAUDE.md              # In-session instructions for Claude Code
└── README.md              # This file
```

---

## How the proxy translates models

Claude Code requests specific Anthropic model names. LiteLLM maps **all of them** to your single local model:

| Claude Code requests | Your local model |
|---|---|
| `claude-sonnet-4-6` | Whatever is set in `.env` |
| `claude-opus-4-6` | Whatever is set in `.env` |
| `claude-haiku-4-6` | Whatever is set in `.env` |
| `claude-sonnet-4-5` | Whatever is set in `.env` |
| `claude-opus-4-5` | Whatever is set in `.env` |
| `claude-haiku-4-5-20251001` | Whatever is set in `.env` |
| `claude-3-5-sonnet-20241022` | Whatever is set in `.env` |

The mapping is auto-generated by `start_litellm.sh` from your `.env` — no need to edit `litellm_config.yaml` manually.

> If Claude Code updates and sends a new model name, add it to the `CLAUDE_MODELS` array in `start_litellm.sh`.

---

## Running alongside Claude Pro

You can run your **normal Claude Pro session** and the **local model session** simultaneously without conflict:

```
Terminal A                    Terminal B                    Terminal C
────────────────────          ────────────────────          ────────────────────
$ claude                      $ ./start_llamacpp.sh         $ ./claude_ollama.sh
→ Uses Anthropic API (Pro)    → llama-server                → Uses local model
```

Why they don't interfere: `ANTHROPIC_BASE_URL` and `ANTHROPIC_API_KEY` are set **only** inside `claude_ollama.sh` as local env vars. Other terminals are unaffected.

---

## Ollama vs llama-server

| | Ollama | llama-server (llama.cpp) |
|---|---|---|
| **Setup** | `ollama pull <model>` | Build llama.cpp + download GGUF |
| **Model management** | Built-in (`ollama list`, `ollama pull`) | Manual (specify file paths / `.ini` presets) |
| **Context window** | Model default | `-c` flag (fully customizable) |
| **Parallel slots** | Automatic | `-np` flag (fully customizable) |
| **GPU layers** | Automatic | `--n-gpu-layers` flag |
| **Vision/Multimodal** | Depends on model | `mmproj` GGUF for vision support |
| **Port** | Default `11434` | Any (set in `.env`) |
| **API format** | OpenAI-compatible `/v1` | OpenAI-compatible `/v1` |
| **Best for** | Quick setup, experimentation | Production, fine-tuned control |

---

## Common Pitfalls

### `litellm[proxy]` vs `litellm`

| Install command | Result |
|---|---|
| `pip install litellm` | Library only — `litellm --config` fails with missing modules (`uvicorn`, `fastapi`) |
| `pip install 'litellm[proxy]'` | Full proxy server with all dependencies |

Always use `pip install 'litellm[proxy]'`.

### Thinking models: empty responses and vision/OCR failure

**This is the most common issue** when using models like Qwen3.5, QwQ, DeepSeek-R1, or any model with built-in "thinking" mode.

**Symptoms:**
- Claude Code gets empty responses (`content: []`)
- Vision/OCR requests return nothing even though the model supports images
- The model appears to "think" for a long time but produces no output

**Root cause:** Thinking models split output into two fields:
- `reasoning_content` — internal chain-of-thought (can consume thousands of tokens)
- `content` — the actual answer

When thinking is enabled, the model may use **all** `max_tokens` for reasoning and never produce any `content`. Additionally, LiteLLM cannot properly translate `reasoning_content` back to Anthropic Messages API format, so Claude Code always sees empty `content: []`.

**Fix:** Set `DISABLE_THINKING=true` in `.env` (this is the default). This sends `chat_template_kwargs: {enable_thinking: false}` to the backend, forcing the model to write directly to `content`.

```bash
# .env
DISABLE_THINKING=true    # recommended for general use, OCR, and vision
DISABLE_THINKING=false   # only if you need deep reasoning and accept empty-response risk
```

**Trade-off:** Disabling thinking makes responses faster and fixes vision/OCR, but may slightly reduce quality on complex multi-step reasoning tasks.

### Port conflict

```bash
# Check if port 4000 is already in use
ss -tlnp | grep 4000
```

If conflicting, change `LITELLM_PORT` in `.env`. All scripts will pick up the new port automatically.

### Ollama port is not default

This setup uses Ollama on port **7869** (not the default `11434`). Make sure `OLLAMA_PORT` in `.env` matches your Ollama configuration.

### Model name must match exactly

The model name in `.env` must match the backend's model name character-for-character:

```bash
# Check Ollama model names
curl -s http://localhost:7869/api/tags | python3 -m json.tool

# Check llama-server model names
curl -s http://localhost:8081/v1/models | python3 -m json.tool
```

### venv not activated before running scripts

If LiteLLM was installed in a virtual environment, activate it first:

```bash
source ~/venv/litellm/bin/activate
./claude_ollama.sh
```

Or set the full path to litellm in `start_litellm.sh`:

```bash
~/venv/litellm/bin/litellm --config "$CONFIG_FILE" --port "$LITELLM_PORT"
```

### Claude Code sends a new model name after update

When Claude Code updates, it may request a model name not in the config. **Fix:** Add the name to the `CLAUDE_MODELS` array in `start_litellm.sh`:

```bash
CLAUDE_MODELS=(
    claude-sonnet-4-6
    claude-opus-4-6
    ...
    new-model-name-here    # add the name from the error message
)
```

Then restart Claude Code (`./claude_ollama.sh` — it will regenerate the config automatically).

### Vision/OCR not working with llama-server

If your model supports vision but images aren't being processed:

1. Ensure your `.ini` preset includes the `mmproj` (multimodal projector) GGUF file
2. Ensure `DISABLE_THINKING=true` in `.env` (thinking mode blocks vision output)
3. Test vision directly against llama-server to isolate the issue:

```bash
# Create a test payload with a base64 image
python3 -c "
from PIL import Image
import io, base64, json
img = Image.open('your_image.png')
img.thumbnail((600, 600))
buf = io.BytesIO()
img.save(buf, format='PNG')
b64 = base64.b64encode(buf.getvalue()).decode()
payload = {
    'model': 'Qwen3.5-27B',
    'max_tokens': 2000,
    'chat_template_kwargs': {'enable_thinking': False},
    'messages': [{'role': 'user', 'content': [
        {'type': 'image_url', 'image_url': {'url': f'data:image/png;base64,{b64}'}},
        {'type': 'text', 'text': 'Extract text from this image.'}
    ]}]
}
with open('/tmp/vision_test.json', 'w') as f:
    json.dump(payload, f)
"

curl -s -X POST http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d @/tmp/vision_test.json | python3 -m json.tool
```

---

## Troubleshooting

### Diagnose each layer

```bash
# Layer 1: Is the backend running?
curl -s http://localhost:7869/api/tags            # Ollama
curl -s http://localhost:8081/health              # llama-server

# Layer 2: Is LiteLLM healthy?
curl -s http://localhost:4000/health | python3 -m json.tool

# Layer 3: Test backend directly (OpenAI format)
curl -s -X POST http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen3.5-27B","messages":[{"role":"user","content":"hello"}],"max_tokens":200}'

# Layer 4: Test through LiteLLM (Anthropic format — same as Claude Code)
curl -s -X POST http://localhost:4000/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: ollama-local" \
  -H "anthropic-version: 2023-06-01" \
  -d '{"model":"claude-sonnet-4-6","max_tokens":200,"messages":[{"role":"user","content":"hello"}]}'
```

### View LiteLLM logs

```bash
cat /tmp/litellm.log
```

### Common errors

| Error | Cause | Fix |
|---|---|---|
| `command not found: litellm` | venv not activated or not installed | `source ~/venv/litellm/bin/activate` then `pip install 'litellm[proxy]'` |
| `No module named uvicorn` | Installed `litellm` instead of `litellm[proxy]` | `pip install 'litellm[proxy]'` |
| `Invalid model name passed in model=...` | Claude Code sent a model name not in config | Add the name to `CLAUDE_MODELS` in `start_litellm.sh` |
| `LiteLLM proxy failed to start` | Port conflict or config error | Check `cat /tmp/litellm.log` and `ss -tlnp \| grep 4000` |
| Empty response / `content: []` | Thinking model used all tokens for reasoning | Set `DISABLE_THINKING=true` in `.env` |
| Vision returns empty | Thinking mode blocks vision output | Set `DISABLE_THINKING=true` in `.env` |

---

## Notes

- `litellm_config.yaml` is **auto-generated** by `start_litellm.sh` from `.env` — do not edit it manually, changes will be overwritten on next start
- `drop_params: true` — LiteLLM strips Anthropic-only parameters the backend doesn't support
- `ANTHROPIC_API_KEY=ollama-local` — dummy value, any non-empty string works
- `ANTHROPIC_BASE_URL` — redirects Claude Code to LiteLLM instead of Anthropic's cloud
- Env vars are scoped to the `claude_ollama.sh` process only — other terminals are unaffected
- `merge_reasoning_content_in_choices: true` — merges thinking model reasoning into content for OpenAI format pass-through
- `extra_body.chat_template_kwargs.enable_thinking` — controls whether the backend model uses thinking mode

---

## License

MIT
