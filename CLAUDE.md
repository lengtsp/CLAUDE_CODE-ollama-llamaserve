# Claude Code + Local LLM Integration

Run Claude Code with local models via Ollama or llama-server (llama.cpp). LiteLLM proxy translates Anthropic API format to OpenAI format.

## Architecture

```
Claude Code → LiteLLM proxy (localhost:4000) → Ollama (localhost:7869)      → local model
                                              → llama-server (localhost:8081) → local model
```

Backend selection and inference preset are controlled by `.env`. `litellm_config.yaml` is auto-generated — do not edit manually.

## Files

| File | Purpose |
|---|---|
| `.env` | All configuration: backend, ports, model, paths, inference preset |
| `claude_ollama.sh` | Main entry point — auto-starts LiteLLM, launches Claude Code, cleans up on exit |
| `start_litellm.sh` | Generates `litellm_config.yaml` from `.env` and starts LiteLLM proxy |
| `start_llamacpp.sh` | Starts llama-server from `.env` settings |
| `litellm_config.yaml` | Auto-generated — do not edit manually |
| `reload_litellm.sh` | Regenerate config + restart LiteLLM (hot-reload preset without restarting Claude Code) |
| `.claude/commands/preset.md` | Skill: analyze task and recommend/apply the best inference preset |
| `.claude/commands/status.md` | Skill: show current configuration, active preset, and backend health |

---

## Slash Commands (Skills)

| Command | Description |
|---|---|
| `/preset <task description>` | Analyze a task, recommend preset, auto-update `.env` and hot-reload LiteLLM |
| `/status` | Show current backend config, active preset parameters, and health status |

### Examples

```
/preset อ่านข้อความจากรูปภาพ               → recommends ocr
/preset refactor auth module with tests    → recommends thinking-coding
/preset วิเคราะห์ข้อดีข้อเสียของ design นี้  → recommends thinking-general
/preset สรุปเนื้อหาให้หน่อย                 → recommends instruct-general
/preset เปรียบเทียบ REST vs GraphQL        → recommends instruct-reasoning
/status                                    → shows current config + health
```

---

## Installation

### 1. Python and pip

Requires Python 3.8+:

```bash
python3 --version   # must be >= 3.8
pip3 --version
```

### 2. LiteLLM

**Recommended: always install in a virtual environment:**

```bash
python3 -m venv ~/venv/litellm
source ~/venv/litellm/bin/activate
pip install 'litellm[proxy]'
```

> **Must use `litellm[proxy]`** not just `litellm` — the `[proxy]` extras include uvicorn, fastapi, and other dependencies required for `litellm --config` server.

#### Pin version if latest has issues

```bash
pip install 'litellm[proxy]==1.51.0'
```

#### Verify litellm is ready

```bash
which litellm
litellm --version
```

### 3. Backend: Ollama

```bash
curl -s http://localhost:7869/api/tags    # check running models
ollama pull gpt-oss:120b                  # pull if needed
```

### 4. Backend: llama-server (alternative)

Build llama.cpp and set paths in `.env`.

### 5. Make scripts executable

```bash
chmod +x claude_ollama.sh start_litellm.sh start_llamacpp.sh reload_litellm.sh
```

---

## Configuration (.env)

All settings are in `.env`. Edit once, all scripts read from it.

```bash
# Backend: "ollama" or "llamacpp"
BACKEND=ollama

# === Ollama settings ===
OLLAMA_HOST=localhost
OLLAMA_PORT=7869
OLLAMA_MODEL=gpt-oss:120b
OLLAMA_API_KEY=ollama

# === llama-server settings ===
LLAMACPP_HOST=127.0.0.1
LLAMACPP_PORT=8081
LLAMACPP_MODEL=Qwen3.5-27B
LLAMACPP_API_KEY=none
LLAMACPP_BIN=/path/to/llama-server
LLAMACPP_MODELS_PRESET="/path/to/model.ini"
LLAMACPP_NP=5
LLAMACPP_CTX=8192
LLAMACPP_MODELS_MAX=1
LLAMACPP_GUI_PATH="/path/to/gui"

# === LiteLLM proxy settings ===
LITELLM_PORT=4000

# === Inference preset ===
# ocr              — vision/OCR (no thinking, low temp, precise)
# thinking-coding  — complex coding with reasoning (thinking on, balanced)
# thinking-general — general reasoning (thinking on, creative)
# instruct-general — general chat (no thinking, balanced)
# instruct-reasoning — reasoning without thinking tokens (no thinking, creative)
PRESET=instruct-general
```

---

## Inference Presets

| Preset | Thinking | Temp | top_p | presence_penalty | Best for |
|---|---|---|---|---|---|
| `ocr` | off | 0.4 | 0.5 | 1.5 | Vision/OCR, image text extraction |
| `thinking-coding` | on | 0.6 | 0.95 | 0.0 | Complex coding, debugging, refactoring |
| `thinking-general` | on | 1.0 | 0.95 | 1.5 | General reasoning, analysis |
| `instruct-general` | off | 0.7 | 0.8 | 1.5 | General chat, Q&A, simple coding |
| `instruct-reasoning` | off | 1.0 | 0.95 | 1.5 | Reasoning without thinking overhead |

**Thinking on** = model uses `reasoning_content` for chain-of-thought before answering. Slower but deeper reasoning. Requires `merge_reasoning_content_in_choices: true` in LiteLLM config (auto-generated).

**Thinking off** = model writes directly to `content`. Faster, vision/OCR works correctly, but less complex reasoning.

> After changing `PRESET` in `.env`, run `./reload_litellm.sh` to apply — no need to restart Claude Code. The `/preset` skill does this automatically.

---

## Usage

### Ollama backend

```bash
# Set BACKEND=ollama in .env
./claude_ollama.sh
```

### llama-server backend

```bash
# Set BACKEND=llamacpp in .env

# Terminal 1: start llama-server
./start_llamacpp.sh

# Terminal 2: start Claude Code (auto-starts LiteLLM)
./claude_ollama.sh
```

### Pass arguments

```bash
./claude_ollama.sh -p "explain this codebase"
./claude_ollama.sh --dangerously-skip-permissions
```

---

## Common Pitfalls

### litellm[proxy] vs litellm

- `pip install litellm` — library only, `litellm --config` may error
- `pip install 'litellm[proxy]'` — includes all proxy server dependencies

### Thinking presets: empty responses and vision failure

When using `thinking-coding` or `thinking-general` presets:
1. Model may use all `max_tokens` for reasoning → `content` returns empty `[]`
2. Vision/OCR fails — LiteLLM cannot translate `reasoning_content` back to Anthropic format

**Fix:** Use a non-thinking preset (`ocr`, `instruct-general`, `instruct-reasoning`).

### Port 4000 conflict

Change `LITELLM_PORT` in `.env`.

### Model name must match exactly

```bash
curl -s http://localhost:7869/api/tags | python3 -m json.tool    # Ollama
curl -s http://localhost:8081/v1/models | python3 -m json.tool   # llama-server
```

### Claude Code sends unknown model name after update

Add the new name to `CLAUDE_MODELS` array in `start_litellm.sh`, then restart.

---

## Troubleshooting

### Diagnose each layer

```bash
# Layer 1: Backend running?
curl -s http://localhost:7869/api/tags            # Ollama
curl -s http://localhost:8081/health              # llama-server

# Layer 2: LiteLLM healthy?
curl -s http://localhost:4000/health | python3 -m json.tool

# Layer 3: Test backend directly
curl -s -X POST http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen3.5-27B","messages":[{"role":"user","content":"hello"}],"max_tokens":200}'

# Layer 4: Test through LiteLLM (Anthropic format)
curl -s -X POST http://localhost:4000/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: ollama-local" \
  -H "anthropic-version: 2023-06-01" \
  -d '{"model":"claude-sonnet-4-6","max_tokens":200,"messages":[{"role":"user","content":"hello"}]}'
```

### LiteLLM logs

```bash
cat /tmp/litellm.log
```

---

## Model Mappings

Claude Code sends these model names — all map to the single local model set in `.env`:

`claude-sonnet-4-6`, `claude-opus-4-6`, `claude-haiku-4-6`, `claude-sonnet-4-5`, `claude-opus-4-5`, `claude-haiku-4-5-20251001`, `claude-3-5-sonnet-20241022`

---

## Notes

- `litellm_config.yaml` is auto-generated — do not edit manually
- `drop_params: true` — LiteLLM strips Anthropic-only parameters the backend doesn't support
- `ANTHROPIC_API_KEY=ollama-local` — any non-empty string, not sent to Anthropic
- env vars are set only in `claude_ollama.sh` process, other terminals are unaffected
- `merge_reasoning_content_in_choices: true` — merges thinking model reasoning into content
- Preset parameters (`temperature`, `top_p`, `presence_penalty`, `extra_body`) are injected per-model in the generated config
