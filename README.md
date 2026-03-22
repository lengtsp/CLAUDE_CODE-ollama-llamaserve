# Claude Code + Local LLM

> Run **[Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)** with fully local models — via **Ollama** or **llama-server** (llama.cpp). No API cost, no internet required.

![Python](https://img.shields.io/badge/Python-3.8%2B-blue?logo=python&logoColor=white)
![LiteLLM](https://img.shields.io/badge/LiteLLM-proxy-green)
![Ollama](https://img.shields.io/badge/Ollama-local%20AI-orange)
![llama.cpp](https://img.shields.io/badge/llama.cpp-local%20AI-red)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

## What is Claude Code?

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) is Anthropic's official CLI tool that turns Claude into an AI coding assistant running directly in your terminal. It can:

- Read and edit files in your project
- Execute shell commands
- Search codebases and answer questions about code
- Run multi-turn conversations with full context of your project

By default, Claude Code connects to Anthropic's cloud API (requires a paid API key). **This project lets you run Claude Code against a local model instead** — completely free and private.

---

## How It Works

Claude Code speaks Anthropic's API format. Local models (Ollama, llama-server) speak OpenAI's API format. **LiteLLM** sits in the middle and translates between them:

```
┌─────────────┐  Anthropic format  ┌─────────────┐  OpenAI format  ┌──────────────────┐
│ Claude Code │ ─────────────────▶ │   LiteLLM   │ ─────────────▶ │  Ollama          │
│ (CLI)       │ ◀───────────────── │   Proxy     │ ◀───────────── │  or llama-server │
└─────────────┘                    └─────────────┘                 └──────────────────┘
```

A single `.env` file controls which backend to use. The wrapper script `claude_ollama.sh` auto-starts LiteLLM, connects everything, and cleans up on exit — **one command to launch**.

---

## Supported Backends

| Backend | Description | When to use |
|---|---|---|
| **Ollama** | Model manager + inference server | Easiest setup, many models available via `ollama pull` |
| **llama-server** (llama.cpp) | Lightweight inference server | Full control over GGUF models, context size, parallel slots |

---

## Prerequisites

| Requirement | Version | Install |
|---|---|---|
| **Claude Code CLI** | latest | `npm install -g @anthropic-ai/claude-code` |
| **Python** | 3.8+ | System package manager or [python.org](https://python.org) |
| **LiteLLM** | latest | `pip install 'litellm[proxy]'` (see below) |
| **Ollama** | latest | [ollama.com](https://ollama.com) (if using Ollama backend) |
| **llama.cpp** | latest | [Build from source](https://github.com/ggerganov/llama.cpp) (if using llama-server backend) |

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

All settings are in a single **`.env`** file. Edit it once, and all scripts read from it automatically.

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
LLAMACPP_NP=5              # parallel slots
LLAMACPP_CTX=8192           # context window size
LLAMACPP_MODELS_MAX=1
LLAMACPP_GUI_PATH="/path/to/gui"

# === LiteLLM proxy settings ===
LITELLM_PORT=4000
```

### Key settings to change

| Setting | What to change |
|---|---|
| `BACKEND` | `ollama` or `llamacpp` — switches the entire pipeline |
| `OLLAMA_PORT` | Default Ollama port is `11434`. Change if yours differs |
| `OLLAMA_MODEL` | The exact model name from `ollama list` |
| `LLAMACPP_BIN` | Absolute path to your `llama-server` binary |
| `LLAMACPP_MODELS_PRESET` | Path to your model's `.ini` preset file |
| `LLAMACPP_CTX` | Context window size (e.g., `8192`, `32768`, `220000`) |
| `LLAMACPP_NP` | Number of parallel inference slots |

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
2. Checks if LiteLLM proxy is already running
3. If not, starts LiteLLM in the background (logs to `/tmp/litellm.log`)
4. Waits for LiteLLM to become healthy (up to 30 seconds)
5. Launches `claude` CLI with `ANTHROPIC_BASE_URL` pointing to LiteLLM
6. When you exit Claude Code, automatically kills the LiteLLM proxy it started

**One command. No manual terminal juggling.**

---

## Project Structure

```
claude_code_ollama/
├── .env                   # All configuration (backend, ports, model, paths)
├── claude_ollama.sh       # Main entry point — launches everything
├── start_litellm.sh       # Generates litellm_config.yaml and starts LiteLLM
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

## Ollama vs llama-server comparison

| | Ollama | llama-server (llama.cpp) |
|---|---|---|
| **Setup** | `ollama pull <model>` | Build llama.cpp + download GGUF |
| **Model management** | Built-in (`ollama list`, `ollama pull`) | Manual (specify file paths) |
| **Context window** | Model default | `-c` flag (fully customizable) |
| **Parallel slots** | Automatic | `-np` flag (fully customizable) |
| **GPU layers** | Automatic | `--n-gpu-layers` flag |
| **Port** | Default `11434` | Any (set in `.env`) |
| **API format** | OpenAI-compatible `/v1` | OpenAI-compatible `/v1` |
| **Best for** | Quick setup, model experimentation | Production, fine-tuned control |

---

## Troubleshooting

### LiteLLM proxy failed to start

```bash
# Check logs
cat /tmp/litellm.log

# Check if port is in use
ss -tlnp | grep 4000
```

### `command not found: litellm`

```bash
# If installed in a venv, activate it first
source ~/venv/litellm/bin/activate

# Verify
which litellm
```

### `No module named uvicorn`

You installed `litellm` instead of `litellm[proxy]`:

```bash
pip install 'litellm[proxy]'
```

### Empty response from thinking models (e.g., Qwen3.5)

Qwen3.5 and similar "thinking" models use tokens for internal reasoning before producing the answer. If `max_tokens` is too low, all tokens are consumed by reasoning and the response appears empty.

The config includes `merge_reasoning_content_in_choices: true` to handle this. If you still see empty responses, the model likely needs more tokens to complete its reasoning chain.

### Claude Code sends an unknown model name

After a Claude Code update, it may request a new model name not in the config.

**Fix:** Add the model name to the `CLAUDE_MODELS` array in `start_litellm.sh`, then restart:

```bash
# In start_litellm.sh, add to CLAUDE_MODELS array:
CLAUDE_MODELS=(
    claude-sonnet-4-6
    claude-opus-4-6
    ...
    new-model-name-here    # add the name from the error message
)
```

### Diagnose each layer

```bash
# 1. Is the backend running?
curl -s http://localhost:8081/health          # llama-server
curl -s http://localhost:7869/api/tags        # Ollama

# 2. Is LiteLLM healthy?
curl -s http://localhost:4000/health | python3 -m json.tool

# 3. Test backend directly
curl -s -X POST http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen3.5-27B","messages":[{"role":"user","content":"hello"}],"max_tokens":200}'

# 4. Test through LiteLLM (Anthropic format, same as Claude Code)
curl -s -X POST http://localhost:4000/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: ollama-local" \
  -H "anthropic-version: 2023-06-01" \
  -d '{"model":"claude-sonnet-4-6","max_tokens":200,"messages":[{"role":"user","content":"hello"}]}'
```

---

## Notes

- `litellm_config.yaml` is **auto-generated** by `start_litellm.sh` from `.env` — do not edit it manually
- `drop_params: true` in LiteLLM config strips Anthropic-only parameters that local backends don't support
- `ANTHROPIC_API_KEY=ollama-local` is a dummy value — any non-empty string works since we're not hitting Anthropic's real API
- Env vars are set only inside the `claude_ollama.sh` process and do not affect other terminals

---

## License

MIT
