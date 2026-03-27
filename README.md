# cplan

**Claude Plan + Gemini Execute** — Use Claude (Sonnet) to write implementation plans, then Gemini CLI automatically executes them.

> 🇰🇷 [한국어 README](README_ko.md)

## How It Works

```
$ cplan
    ↓
Claude Code opens (plan-only mode)
  → Describe what you want to build
  → Claude writes a structured plan file
  → Type /execute-gemini
    ↓
Gemini CLI reads the plan and executes step by step
  (real-time progress streaming)
    ↓
Claude session stays open
  → Describe the next task
  → /execute-gemini to repeat
  → /exit when done
```

## Why cplan?

| Challenge | cplan Solution |
|-----------|---------------|
| AI tools that plan well but execute poorly | Sonnet plans, Gemini executes |
| Expensive API calls for routine coding | Gemini CLI is free (with limits) |
| Lost context between planning and coding | Plan files preserve full context |
| Manual copy-paste between AI tools | Automated handoff via CLI |

## Installation

### Requirements

- [Claude Code CLI](https://claude.ai/code) (planning agent)
- Node.js + npm (for gemini-cli)
- Gemini API key ([Google AI Studio](https://aistudio.google.com/apikey) — free) or Google account
- bash / zsh / fish

### One-line Install

```bash
curl -fsSL https://raw.githubusercontent.com/senghan1992/cplan-use-gemini-cli-as-worker/main/install.sh | bash
```

### Or Clone & Install

```bash
git clone https://github.com/senghan1992/cplan-use-gemini-cli-as-worker.git cplan
cd cplan
bash install.sh
```

### Advanced Install Options

```bash
# Non-interactive with API key
bash install.sh --api-key "YOUR_GEMINI_API_KEY"

# Headless server (skip OAuth)
bash install.sh --api-key "KEY" --no-oauth

# Fully unattended (CI/CD)
bash install.sh --api-key "KEY" --unattended
```

## Quick Start

```bash
# 1. Initialize your project
cd my-project
cplan --init

# 2. Start planning + executing
cplan
```

## Usage

```bash
# Full flow: Claude plans → Gemini executes
cplan

# Execute latest plan directly
cplan -g

# Execute specific plan
cplan -g docs/superpowers/plans/2026-03-27-my-feature.md

# List plans and status
cplan -l

# Initialize project in current directory
cplan --init

# Self-diagnostics
cplan --doctor

# Show version
cplan --version
```

## Project Configuration

Run `cplan --init` in your project root to create a `.cplan` config file:

```ini
# .cplan - project configuration
plan_dir = docs/superpowers/plans
log_dir  = docs/superpowers/logs
# gemini_model = auto-gemini-2.5
```

| Key | Default | Description |
|-----|---------|-------------|
| `plan_dir` | `docs/superpowers/plans` | Where Claude saves plan files |
| `log_dir` | `docs/superpowers/logs` | Where Gemini writes execution logs |
| `gemini_model` | (auto fallback) | Lock to a specific Gemini model |

## Environment Variables

Stored in `~/.claude/env`:

```bash
# Claude API (only if using custom endpoint)
ANTHROPIC_AUTH_TOKEN="sk-..."
ANTHROPIC_BASE_URL="https://..."
ANTHROPIC_MODEL="claude-sonnet-4-6"

# Gemini
GEMINI_API_KEY="AIza..."
GEMINI_MODEL="gemini-2.5-flash"   # optional: lock model
```

### Gemini Model Fallback

When `GEMINI_MODEL` is not set, cplan tries models in this order:
1. `auto-gemini-2.5`
2. `gemini-2.5-flash`
3. `gemini-2.5-flash-lite`

If a model hits capacity limits, cplan automatically falls back to the next one.

## Plan File Format

Claude auto-generates structured plans in `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`:

```markdown
## Goal
What to build

## Architecture
High-level approach

## File Map
| File | Role | Change Type |
|------|------|-------------|
| src/index.ts | Entry point | Create |

## Tasks
- [ ] Task 1: Setup project
  - [ ] Step 1.1: Initialize npm
  - [ ] Verify: npm test passes
- [ ] Task 2: Implement feature
  ...
```

## Self-Diagnostics

Run `cplan --doctor` to check your environment:

```
╔════════════════════════════════════════╗
║   cplan doctor — self-diagnostics      ║
╚════════════════════════════════════════╝

  Checking prerequisites...

  ✓ Claude CLI:     2.1.85 (Claude Code)
  ✓ Node.js:        v24.14.1
  ✓ npm:            10.9.2
  ✓ Gemini CLI:     0.35.2

  Checking authentication...

  ✓ GEMINI_API_KEY: set (AIzaSyD5...)
  ℹ Claude API:     using default login

  All checks passed! Ready to use.
```

## Uninstall

```bash
# If installed from clone
bash uninstall.sh

# Or download and run
curl -fsSL https://raw.githubusercontent.com/senghan1992/cplan-use-gemini-cli-as-worker/main/uninstall.sh | bash
```

## License

MIT
