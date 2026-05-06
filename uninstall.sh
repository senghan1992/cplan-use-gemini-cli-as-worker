#!/usr/bin/env bash
#
# cplan uninstall script
# Usage: bash uninstall.sh
#        cplan --uninstall (if installed)
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[uninstall]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[uninstall]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[uninstall]${NC} $*"; }
log_skip()  { echo -e "${CYAN}[uninstall]${NC} $* (skipped)"; }

echo ""
echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║        cplan uninstaller v1.1          ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""
echo "  The following will be removed:"
echo "    ~/.local/bin/cplan"
echo "    ~/.claude/profiles/gemini-worker/CLAUDE.md"
echo "    GEMINI_API_KEY from ~/.claude/env"
echo "    GEMINI_API_KEY and PATH entries from shell RC"
echo ""
read -rp "Continue? [y/N] " confirm </dev/tty
if [[ ! "${confirm:-N}" =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 0
fi
echo ""

# ── cplan binary ──────────────────────────────────────────
if [[ -f "$HOME/.local/bin/cplan" ]]; then
  rm -f "$HOME/.local/bin/cplan"
  log_ok "Removed: ~/.local/bin/cplan"
else
  log_skip "~/.local/bin/cplan"
fi

# ── gemini-worker profile ────────────────────────────────
if [[ -f "$HOME/.claude/profiles/gemini-worker/CLAUDE.md" ]]; then
  rm -f "$HOME/.claude/profiles/gemini-worker/CLAUDE.md"
  rmdir "$HOME/.claude/profiles/gemini-worker" 2>/dev/null || true
  log_ok "Removed: ~/.claude/profiles/gemini-worker/"
else
  log_skip "~/.claude/profiles/gemini-worker/CLAUDE.md"
fi

# ── ~/.claude/env — remove GEMINI_API_KEY ─────────────────
ENV_FILE="$HOME/.claude/env"
if [[ -f "$ENV_FILE" ]]; then
  tmp=$(mktemp)
  grep -v "^GEMINI_API_KEY=" "$ENV_FILE" > "$tmp" || true
  if cmp -s "$ENV_FILE" "$tmp"; then
    log_skip "~/.claude/env (no GEMINI_API_KEY entry)"
  else
    mv "$tmp" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    log_ok "Removed GEMINI_API_KEY from ~/.claude/env"
  fi
  rm -f "$tmp" 2>/dev/null || true

  if [[ ! -s "$ENV_FILE" ]]; then
    read -rp "~/.claude/env is now empty. Delete it? [y/N] " del_env </dev/tty
    if [[ "${del_env:-N}" =~ ^[Yy]$ ]]; then
      rm -f "$ENV_FILE"
      log_ok "Removed: ~/.claude/env"
    fi
  fi
else
  log_skip "~/.claude/env"
fi

# ── Shell RC files — remove cplan entries ─────────────────
for RC in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc" "$HOME/.config/fish/config.fish"; do
  [[ -f "$RC" ]] || continue

  if [[ "$RC" == *"config.fish"* ]]; then
    # Fish shell cleanup
    tmp=$(mktemp)
    awk '
      /^# cplan( - Gemini API key)?$/ { skip=1; next }
      /^set -gx GEMINI_API_KEY/ { skip=1; next }
      /^set -gx PATH \$HOME\/\.local\/bin/ && skip { skip=0; next }
      { skip=0; print }
    ' "$RC" > "$tmp"
  else
    # Bash/Zsh cleanup
    tmp=$(mktemp)
    awk '
      /^# cplan( - Gemini API key)?$/ { skip=1; next }
      /^export GEMINI_API_KEY=/ { skip=1; next }
      /^export PATH="\$HOME\/\.local\/bin:\$PATH"/ && skip { skip=0; next }
      { skip=0; print }
    ' "$RC" > "$tmp"
  fi

  if cmp -s "$RC" "$tmp"; then
    log_skip "$RC (no cplan entries)"
    rm -f "$tmp"
  else
    mv "$tmp" "$RC"
    log_ok "Removed cplan entries from $RC"
  fi
done

# ── gemini-cli removal ───────────────────────────────────
echo ""
if command -v gemini &>/dev/null; then
  read -rp "Also remove gemini-cli (npm global package)? [y/N] " del_gemini </dev/tty
  if [[ "${del_gemini:-N}" =~ ^[Yy]$ ]]; then
    npm uninstall -g @google/gemini-cli
    log_ok "gemini-cli removed"
  else
    log_skip "gemini-cli (kept)"
  fi
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD} Uninstall complete!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo ""
echo -e "  ${DIM}Note: .cplan project config files are not removed.${NC}"
echo -e "  ${DIM}Delete them manually if no longer needed.${NC}"
echo ""
