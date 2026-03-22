# 🦙 Claude Code + Ollama

> Run Claude Code CLI with **fully local AI models** via Ollama — no API cost, no internet required.

![Python](https://img.shields.io/badge/Python-3.8%2B-blue?logo=python&logoColor=white)
![LiteLLM](https://img.shields.io/badge/LiteLLM-proxy-green)
![Ollama](https://img.shields.io/badge/Ollama-local%20AI-orange)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

## ✨ Features

- 🔒 **Privacy-first** — all inference runs locally, no data leaves your machine
- 💸 **Zero API cost** — bypass Anthropic API billing entirely
- 🔄 **Non-conflicting** — runs independently from your Claude Pro account; both can be active at the same time in separate terminals
- 🧩 **Drop-in replacement** — uses the same `claude` CLI you already have installed
- ⚡ **Any Ollama model** — swap to any model you have pulled locally by editing one config file
- 🛠️ **Full Claude Code features** — tools, file editing, bash execution, multi-turn — all work as normal

---

## 🏗️ How It Works

```
┌─────────────────┐   Anthropic API format   ┌──────────────────┐   OpenAI format   ┌─────────────────┐
│                 │ ───────────────────────▶  │                  │ ────────────────▶ │                 │
│   Claude Code   │                           │  LiteLLM Proxy   │                   │  Ollama (local) │
│   (CLI)         │ ◀───────────────────────  │  localhost:4000  │ ◀──────────────── │  localhost:7869 │
│                 │   Anthropic API format     │                  │   OpenAI format   │                 │
└─────────────────┘                           └──────────────────┘                   └─────────────────┘
```

Claude Code sends requests in Anthropic's format. LiteLLM translates them to OpenAI-compatible format that Ollama understands — completely transparent to Claude Code.

---

## 🆚 Claude Pro vs Claude Code + Ollama

| | Claude Pro (normal) | Claude Code + Ollama |
|---|---|---|
| **Model** | Claude Sonnet / Opus (Anthropic cloud) | Local model via Ollama |
| **API cost** | Billed to your account | Free |
| **Internet** | Required | Not required |
| **Privacy** | Data sent to Anthropic | Stays on your machine |
| **Speed** | Depends on network | Depends on your hardware |
| **Can run simultaneously** | ✅ Yes | ✅ Yes |

> **Both sessions are fully independent.** `ANTHROPIC_BASE_URL` and `ANTHROPIC_API_KEY` are set only inside `claude_ollama.sh` as local env vars — they do not affect other terminals or your Claude Pro session running elsewhere.

---

## 📋 Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| [Claude Code CLI](https://claude.ai/code) | latest | `npm install -g @anthropic-ai/claude-code` |
| [Ollama](https://ollama.com) | latest | Must be running on `localhost:7869` |
| Python | 3.8+ | Required for LiteLLM |
| pip | latest | Used to install LiteLLM |

### Check prerequisites

```bash
# Claude Code
claude --version

# Ollama
curl -s http://localhost:7869/api/tags

# Python
python3 --version

# pip
pip3 --version
```

---

## 🚀 Quick Start

### 1. Clone this repo

```bash
git clone <repo-url>
cd claude_code_ollama
```

### 2. Install LiteLLM

> ⚠️ **Important:** Install `litellm[proxy]`, not just `litellm`. The `[proxy]` extras include server dependencies required to run `litellm --config`.

**Recommended — virtual environment (prevents dependency conflicts):**

```bash
python3 -m venv ~/venv/litellm
source ~/venv/litellm/bin/activate
pip install 'litellm[proxy]'
```

**Or global install:**

```bash
pip install 'litellm[proxy]'
# or on systems where pip3 is separate
pip3 install 'litellm[proxy]'
```

**Verify the install:**

```bash
which litellm
litellm --version
```

### 3. Pull a model in Ollama

```bash
# Pull the model used in this setup
ollama pull gpt-oss:120b

# Or list models you already have
curl -s http://localhost:7869/api/tags | python3 -m json.tool
```

### 4. Configure your model

Edit `litellm_config.yaml` — change `gpt-oss:120b` to match the Ollama model you pulled:

```yaml
model_list:
  - model_name: claude-sonnet-4-6      # name Claude Code sends (do not change)
    litellm_params:
      model: openai/gpt-oss:120b        # ← change this to your Ollama model
      api_base: http://localhost:7869/v1
      api_key: ollama
```

### 5. Make scripts executable

```bash
chmod +x start_litellm.sh claude_ollama.sh
```

### 6. Start LiteLLM proxy — Terminal 1

```bash
# If installed in venv, activate first
source ~/venv/litellm/bin/activate

./start_litellm.sh
```

Wait until you see `Application startup complete` or `LiteLLM Proxy: ✅` before proceeding.

### 7. Run Claude Code with Ollama — Terminal 2

```bash
./claude_ollama.sh
```

---

## 📂 Project Structure

```
claude_code_ollama/
├── claude_ollama.sh       # Wrapper: sets env vars and launches Claude Code
├── start_litellm.sh       # Starts LiteLLM proxy on port 4000
├── litellm_config.yaml    # Model name mappings (Claude → Ollama)
├── CLAUDE.md              # In-session instructions for Claude Code
└── README.md              # This file
```

---

## ⚙️ Configuration

### `litellm_config.yaml`

Maps every model name that Claude Code might request to your local Ollama model. Claude Code sends a specific model name (e.g. `claude-sonnet-4-6`) — LiteLLM looks it up here and forwards to Ollama.

```yaml
model_list:
  - model_name: claude-sonnet-4-6
    litellm_params:
      model: openai/gpt-oss:120b
      api_base: http://localhost:7869/v1
      api_key: ollama

  - model_name: claude-opus-4-6
    litellm_params:
      model: openai/gpt-oss:120b
      api_base: http://localhost:7869/v1
      api_key: ollama

  # Add more entries if Claude Code uses other model names
  # (see Troubleshooting below)

litellm_settings:
  drop_params: true    # strips Anthropic-only params Ollama doesn't understand
  set_verbose: false
```

### Model Mappings

All Claude model names currently map to `gpt-oss:120b`:

| Claude model name | Ollama model |
|---|---|
| `claude-sonnet-4-6` | `gpt-oss:120b` |
| `claude-opus-4-6` | `gpt-oss:120b` |
| `claude-haiku-4-6` | `gpt-oss:120b` |
| `claude-sonnet-4-5` | `gpt-oss:120b` |
| `claude-opus-4-5` | `gpt-oss:120b` |
| `claude-haiku-4-5-20251001` | `gpt-oss:120b` |
| `claude-3-5-sonnet-20241022` | `gpt-oss:120b` |

### Using a different Ollama model

Change `openai/<model-name>` to any model you have in Ollama:

```yaml
model: openai/qwen2.5-coder:32b
# or
model: openai/llama3.3:70b
# or
model: openai/mistral:latest
```

---

## 🔄 Running Both Sessions Simultaneously

You can run your **normal Claude Pro session** and **Claude Code + Ollama** at the same time without conflict:

```
Terminal A                          Terminal B              Terminal C
──────────────────────────          ──────────────────      ──────────────────────
$ claude                            $ ./start_litellm.sh    $ ./claude_ollama.sh
▶ Uses Anthropic API (Pro)          ▶ LiteLLM proxy         ▶ Uses local Ollama
```

**Why they don't interfere:**
- `ANTHROPIC_BASE_URL` and `ANTHROPIC_API_KEY` are set as local `export` inside `claude_ollama.sh`
- These env vars only apply to that specific shell process and its child processes
- Your other terminals retain their original env (pointing to Anthropic's real API)

---

## ⚠️ Common Pitfalls

### `litellm` vs `litellm[proxy]`

| Install command | Result |
|---|---|
| `pip install litellm` | Library only — `litellm --config` may fail with missing modules |
| `pip install 'litellm[proxy]'` | ✅ Full proxy server with all dependencies |

Always use `pip install 'litellm[proxy]'`.

### venv not activated before running `start_litellm.sh`

If you installed LiteLLM in a virtual environment, you must activate it before running the proxy:

```bash
source ~/venv/litellm/bin/activate
./start_litellm.sh
```

Or set the full path to litellm in `start_litellm.sh`:

```bash
~/venv/litellm/bin/litellm --config "$CONFIG_DIR/litellm_config.yaml" --port 4000
```

### Ollama port is not default

This setup uses Ollama on port **7869** (not the default `11434`). If your Ollama runs on the default port, update `api_base` in `litellm_config.yaml`:

```yaml
api_base: http://localhost:11434/v1
```

### Port 4000 conflict

Check if another process is using port 4000:

```bash
ss -tlnp | grep 4000
# or
lsof -i :4000
```

If conflicting, change the port in `start_litellm.sh` and update `ANTHROPIC_BASE_URL` in `claude_ollama.sh` to match.

### Model name in Ollama must match exactly

Get the exact model name from Ollama:

```bash
curl -s http://localhost:7869/api/tags | python3 -m json.tool
```

The name in `litellm_config.yaml` must match the `name` field in this output character-for-character.

---

## 🛠️ Troubleshooting

### `Invalid model name passed in model=claude-sonnet-4-6`

Claude Code is requesting a model name not listed in your config (this happens after Claude Code updates).

**Fix:** Add the missing entry to `litellm_config.yaml`:

```yaml
- model_name: claude-sonnet-4-6   # the exact name shown in the error
  litellm_params:
    model: openai/gpt-oss:120b
    api_base: http://localhost:7869/v1
    api_key: ollama
```

Then restart LiteLLM:

```bash
pkill -f "litellm --config"
./start_litellm.sh
```

### `ERROR: LiteLLM proxy is not running on port 4000`

```bash
# Check if it's running
curl -s http://localhost:4000/health

# Start it
./start_litellm.sh
```

### `command not found: litellm`

```bash
# If installed in venv
source ~/venv/litellm/bin/activate

# Reinstall if needed
pip install 'litellm[proxy]'
```

### `No module named uvicorn` or other import errors

```bash
# Must use proxy extras
pip install 'litellm[proxy]'
```

### Dependency conflict during pip install

```bash
# Install in a clean venv
python3 -m venv ~/venv/litellm-fresh
source ~/venv/litellm-fresh/bin/activate
pip install 'litellm[proxy]'
```

### Diagnose each layer independently

```bash
# Layer 1: Is Ollama running?
curl -s http://localhost:7869/api/tags | python3 -m json.tool

# Layer 2: Is LiteLLM proxy healthy?
curl -s http://localhost:4000/health | python3 -m json.tool

# Layer 3: Test Ollama directly (OpenAI format)
curl -s -X POST http://localhost:7869/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-oss:120b","messages":[{"role":"user","content":"hello"}],"stream":false}' \
  | python3 -m json.tool

# Layer 4: Test LiteLLM proxy (Anthropic format)
curl -s -X POST http://localhost:4000/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: ollama-local" \
  -H "anthropic-version: 2023-06-01" \
  -d '{"model":"claude-sonnet-4-6","max_tokens":50,"messages":[{"role":"user","content":"hello"}]}' \
  | python3 -m json.tool
```

### View LiteLLM logs

```bash
# Foreground mode: logs appear in the terminal running start_litellm.sh
# Background mode:
cat /tmp/litellm.log
```

---

## 📝 Notes

- `drop_params: true` — LiteLLM automatically strips Anthropic-only parameters that Ollama doesn't support
- `ANTHROPIC_API_KEY=ollama-local` — any non-empty string works; it's not validated since we're not hitting Anthropic's real API
- `ANTHROPIC_BASE_URL=http://localhost:4000` — redirects Claude Code to LiteLLM instead of Anthropic
- When Claude Code updates, it may use new model names — just add them to `litellm_config.yaml` and restart

---

## 📝 License

MIT
