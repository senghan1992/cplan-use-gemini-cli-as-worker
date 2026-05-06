#!/usr/bin/env bash
#
# cplan install script
# Usage: bash install.sh
#        curl -fsSL https://raw.githubusercontent.com/senghan1992/cplan-use-gemini-cli-as-worker/main/install.sh | bash
#
# Options:
#   --api-key <KEY>    Set GEMINI_API_KEY non-interactively
#   --no-oauth         Skip OAuth prompt (for headless environments)
#   --unattended       Non-interactive mode (skip all prompts)
#

set -euo pipefail

# ── Colors ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[install]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[install]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[install]${NC} $*"; }
log_error() { echo -e "${RED}[install]${NC} $*"; }

# ── Parse CLI options ────────────────────────────────────
CLI_API_KEY=""
NO_OAUTH=false
UNATTENDED=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-key)
      CLI_API_KEY="$2"
      shift 2
      ;;
    --no-oauth)
      NO_OAUTH=true
      shift
      ;;
    --unattended)
      UNATTENDED=true
      NO_OAUTH=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# ── OS detection ─────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux*)  OS_TYPE="linux" ;;
  Darwin*) OS_TYPE="macos" ;;
  MINGW*|MSYS*|CYGWIN*) OS_TYPE="windows" ;;
  *)       OS_TYPE="unknown" ;;
esac

# ── Detect script location (local clone vs curl|bash) ───
SCRIPT_DIR=""
if [[ -f "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

GITHUB_RAW="https://raw.githubusercontent.com/senghan1992/cplan-use-gemini-cli-as-worker/main"

# ── Paths ────────────────────────────────────────────────
BIN_DIR="$HOME/.local/bin"
CLAUDE_DIR="$HOME/.claude"
PROFILE_DIR="$CLAUDE_DIR/profiles/gemini-worker"
ENV_FILE="$CLAUDE_DIR/env"

# shell RC 파일 탐지 (PATH 및 env 설정용)
detect_shell_rc() {
  local shell_name
  shell_name=$(basename "${SHELL:-bash}")

  case "$shell_name" in
    zsh)
      [[ -f "$HOME/.zshrc" ]] && echo "$HOME/.zshrc" && return
      ;;
    fish)
      local fish_conf="$HOME/.config/fish/config.fish"
      [[ -f "$fish_conf" ]] && echo "$fish_conf" && return
      ;;
    bash|*)
      [[ -f "$HOME/.bashrc" ]] && echo "$HOME/.bashrc" && return
      [[ -f "$HOME/.bash_profile" ]] && echo "$HOME/.bash_profile" && return
      ;;
  esac

  # Fallback
  [[ -f "$HOME/.zshrc" ]] && echo "$HOME/.zshrc" && return
  [[ -f "$HOME/.bashrc" ]] && echo "$HOME/.bashrc" && return
  echo ""
}

SHELL_RC=$(detect_shell_rc)
IS_FISH=false
[[ "$SHELL_RC" == *"config.fish"* ]] && IS_FISH=true

# ── Helper: read input (supports unattended mode) ────────
prompt_input() {
  local prompt_text="$1"
  local default_value="${2:-}"

  if [[ "$UNATTENDED" == true ]]; then
    echo "$default_value"
    return
  fi
  read -rp "$prompt_text" user_input </dev/tty
  echo "${user_input:-$default_value}"
}

# ── Banner ───────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║        cplan installer v1.3            ║${NC}"
echo -e "${BOLD}║  Claude Plan + Gemini Execute          ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${DIM}OS: ${OS} (${ARCH}) | Shell: ${SHELL:-unknown}${NC}"
echo ""

# ── Step 1: Prerequisites check ──────────────────────────
log_info "Step 1/6  Checking prerequisites..."

if ! command -v claude &>/dev/null; then
  log_error "Claude CLI is not installed."
  echo ""
  if [[ "$OS_TYPE" == "macos" ]]; then
    echo "  Install with:"
    echo "    brew install claude-code"
    echo ""
    echo "  Or visit: https://claude.ai/code"
  else
    echo "  Install:"
    echo "    npm install -g @anthropic-ai/claude-code"
    echo ""
    echo "  Or visit: https://claude.ai/code"
  fi
  exit 1
fi
log_ok "Claude CLI: $(claude --version 2>/dev/null | head -1 || echo 'found')"

SKIP_GEMINI_INSTALL=false
if ! command -v npm &>/dev/null; then
  log_warn "npm not found. You'll need to install gemini-cli manually."
  if [[ "$OS_TYPE" == "macos" ]]; then
    echo -e "  ${DIM}Install Node.js: brew install node${NC}"
  else
    echo -e "  ${DIM}Install Node.js: https://nodejs.org${NC}"
  fi
  SKIP_GEMINI_INSTALL=true
else
  log_ok "npm: $(npm --version)"
fi

# ── Step 2: Install gemini-cli ───────────────────────────
log_info "Step 2/6  Installing gemini-cli..."

if [[ "$SKIP_GEMINI_INSTALL" == true ]]; then
  log_warn "npm not available — skipping gemini-cli installation"
elif command -v gemini &>/dev/null; then
  log_ok "Gemini CLI: already installed"
else
  log_info "Installing @google/gemini-cli..."
  npm install -g @google/gemini-cli || {
    log_error "Failed to install gemini-cli."
    if [[ "$OS_TYPE" == "linux" ]]; then
      echo -e "  ${DIM}Try: sudo npm install -g @google/gemini-cli${NC}"
    fi
    exit 1
  }
  # 설치 직후 명령어를 찾을 수 있도록 해시 테이블 갱신
  hash -r 2>/dev/null || true
  log_ok "gemini-cli installed"
fi

# ── Step 3: Install cplan files ──────────────────────────
log_info "Step 3/6  Installing cplan files..."
mkdir -p "$BIN_DIR" "$PROFILE_DIR"

_install_file() {
  local src_rel="$1" dst="$2"
  if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/$src_rel" ]]; then
    cp "$SCRIPT_DIR/$src_rel" "$dst"
  else
    curl -fsSL "$GITHUB_RAW/$src_rel" -o "$dst"
  fi
}

_install_file "bin/cplan"                        "$BIN_DIR/cplan"
chmod +x "$BIN_DIR/cplan"
log_ok "cplan → $BIN_DIR/cplan"

_install_file "profiles/gemini-worker/CLAUDE.md"  "$PROFILE_DIR/CLAUDE.md"
log_ok "gemini-worker profile → $PROFILE_DIR/CLAUDE.md"

# ── Step 4: Gemini authentication ─────────────────────────
echo ""
echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
log_info "Step 4/6  Gemini authentication"
echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
echo ""

# Check for CLI arg first
gemini_key=""
if [[ -n "$CLI_API_KEY" ]]; then
  gemini_key="$CLI_API_KEY"
  log_info "Using API key from --api-key argument"
elif [[ "$UNATTENDED" == true ]]; then
  log_warn "Unattended mode — skipping Gemini auth. Set GEMINI_API_KEY manually."
else
  echo "  Gemini CLI requires authentication."
  echo ""
  echo -e "  ${BOLD}Option A (recommended) — API Key${NC}"
  echo "    Works immediately without a browser"
  echo "    Get one at: https://aistudio.google.com/apikey"
  echo ""
  echo -e "  ${BOLD}Option B — Google OAuth${NC}"
  echo "    Authenticate via browser (one-time)"
  echo "    Just press Enter without a key"
  echo ""
  gemini_key=$(prompt_input "  GEMINI_API_KEY (or Enter for OAuth): " "")
fi

# Existing OAuth check
EXISTING_OAUTH=false
if [[ -f "$HOME/.gemini/oauth_creds.json" || -f "$HOME/.gemini/google_accounts.json" ]]; then
  EXISTING_OAUTH=true
fi

if [[ -n "${gemini_key:-}" ]]; then
  # ── Option A: API key ──────────────────────────────────
  export GEMINI_API_KEY="$gemini_key"

  # Persist to shell RC
  if [[ -n "$SHELL_RC" ]]; then
    if [[ "$IS_FISH" == true ]]; then
      if grep -q "GEMINI_API_KEY" "$SHELL_RC" 2>/dev/null; then
        sed -i "s|^set -gx GEMINI_API_KEY.*|set -gx GEMINI_API_KEY \"$gemini_key\"|" "$SHELL_RC"
      else
        echo "" >> "$SHELL_RC"
        echo "# cplan - Gemini API key" >> "$SHELL_RC"
        echo "set -gx GEMINI_API_KEY \"$gemini_key\"" >> "$SHELL_RC"
      fi
    else
      if grep -q "GEMINI_API_KEY" "$SHELL_RC" 2>/dev/null; then
        sed -i "s|^export GEMINI_API_KEY=.*|export GEMINI_API_KEY=\"$gemini_key\"|" "$SHELL_RC"
      else
        echo "" >> "$SHELL_RC"
        echo "# cplan - Gemini API key" >> "$SHELL_RC"
        echo "export GEMINI_API_KEY=\"$gemini_key\"" >> "$SHELL_RC"
      fi
    fi
    log_ok "GEMINI_API_KEY → $SHELL_RC"
  fi

  # Test connection
  log_info "Testing Gemini API key..."
  if gemini --model gemini-2.0-flash -p "say: ok" 2>/dev/null | grep -qi "ok"; then
    log_ok "Gemini connection successful!"
  else
    log_warn "Could not verify API key — check at https://aistudio.google.com/apikey"
  fi
else
  # ── Option B: OAuth ────────────────────────────────────
  if [[ "$EXISTING_OAUTH" == true ]]; then
    log_ok "Existing Gemini CLI OAuth credentials found. (reusing)"
  elif [[ "$NO_OAUTH" == true ]]; then
    log_warn "OAuth skipped. Set GEMINI_API_KEY manually or run: gemini"
  else
    log_info "Starting Google OAuth (browser will open)..."
    echo ""
    if gemini -p "say: authentication complete" --model gemini-1.5-flash </dev/tty; then
      echo ""
      log_ok "OAuth authentication complete"
    else
      log_error "OAuth failed. This may require a browser."
      log_warn "Try using an API key instead (Option A)."
    fi
  fi
fi

# ── Step 5: Claude API settings (optional) ───────────────
echo ""
echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
log_info "Step 5/6  Claude API settings (optional)"
echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
echo ""

DETECTED_TOKEN="${ANTHROPIC_AUTH_TOKEN:-}"
DETECTED_URL="${ANTHROPIC_BASE_URL:-}"
DETECTED_MODEL="${ANTHROPIC_MODEL:-}"

SKIP_CLAUDE_CREDS=false
if [[ "$UNATTENDED" == true ]]; then
  SKIP_CLAUDE_CREDS=true
elif [[ -f "$ENV_FILE" ]]; then
  log_warn "$ENV_FILE already exists."
  overwrite=$(prompt_input "  Overwrite? [y/N] " "N")
  [[ ! "${overwrite:-N}" =~ ^[Yy]$ ]] && SKIP_CLAUDE_CREDS=true
fi

if [[ "$SKIP_CLAUDE_CREDS" == false ]]; then
  echo "  (Press Enter to skip if using default Claude login)"
  echo ""

  token_prompt="  ANTHROPIC_AUTH_TOKEN"
  [[ -n "$DETECTED_TOKEN" ]] && token_prompt+=" [existing detected]"
  auth_token=$(prompt_input "$token_prompt (or Enter to skip): " "$DETECTED_TOKEN")

  url_prompt="  ANTHROPIC_BASE_URL"
  [[ -n "$DETECTED_URL" ]] && url_prompt+=" [existing detected]"
  base_url=$(prompt_input "$url_prompt (or Enter to skip): " "$DETECTED_URL")

  model_prompt="  ANTHROPIC_MODEL"
  [[ -n "$DETECTED_MODEL" ]] && model_prompt+=" [detected: $DETECTED_MODEL]"
  model=$(prompt_input "$model_prompt (default: claude-3-7-sonnet-latest): " "${DETECTED_MODEL:-claude-3-7-sonnet-latest}")

  mkdir -p "$(dirname "$ENV_FILE")"
  {
    [[ -n "${auth_token:-}" ]] && echo "ANTHROPIC_AUTH_TOKEN=\"$auth_token\""
    [[ -n "${base_url:-}" ]]   && echo "ANTHROPIC_BASE_URL=\"$base_url\""
    [[ -n "${model:-}" ]]      && echo "ANTHROPIC_MODEL=\"$model\""
    [[ -n "${gemini_key:-}" ]] && echo "GEMINI_API_KEY=\"$gemini_key\""
  } > "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  log_ok "Credentials saved: $ENV_FILE"
fi

# ── Step 6: PATH setup ───────────────────────────────────
log_info "Step 6/6  Checking PATH..."

if [[ -n "$SHELL_RC" ]]; then
  if [[ "$IS_FISH" == true ]]; then
    PATH_LINE='set -gx PATH $HOME/.local/bin $PATH'
    if grep -qF '$HOME/.local/bin' "$SHELL_RC" || fish -c 'echo $PATH' 2>/dev/null | grep -q "$HOME/.local/bin"; then
      log_ok "PATH already includes ~/.local/bin"
    else
      echo "" >> "$SHELL_RC"
      echo "# cplan" >> "$SHELL_RC"
      echo "$PATH_LINE" >> "$SHELL_RC"
      log_ok "PATH added → $SHELL_RC"
    fi
  else
    PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
    if grep -qF '$HOME/.local/bin' "$SHELL_RC"; then
      log_ok "PATH already includes ~/.local/bin"
    else
      echo "" >> "$SHELL_RC"
      echo "# cplan" >> "$SHELL_RC"
      echo "$PATH_LINE" >> "$SHELL_RC"
      log_ok "PATH added → $SHELL_RC"
    fi
  fi
else
  log_warn "No shell RC file found. Add to PATH manually:"
  log_warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# ── Done ─────────────────────────────────────────────────
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD} Installation complete!${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

if [[ -n "$SHELL_RC" ]]; then
  echo -e "${YELLOW}${BOLD}  ⚡ 필수: 지금 바로 아래 명령어를 실행하세요!${NC}"
  echo ""
  echo -e "    ${BOLD}source $SHELL_RC${NC}"
  echo ""
  echo -e "  (새 터미널을 열어도 됩니다)"
  echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
  echo ""
fi

echo "  Quick start:"
echo ""
echo "    1. 쉘 설정 반영 (위에서 아직 안 했다면):"
if [[ -n "$SHELL_RC" ]]; then
  echo -e "       ${BOLD}source $SHELL_RC${NC}"
else
  echo -e "       ${BOLD}(새 터미널을 여세요)${NC}"
fi
echo ""
echo "    2. 프로젝트 초기화:"
echo -e "       ${BOLD}cd my-project && cplan --init${NC}"
echo ""
echo "    3. 시작:"
echo -e "       ${BOLD}cplan${NC}"
echo ""
echo "  기타 명령:"
echo "    cplan -g      최신 plan을 Gemini로 실행"
echo "    cplan -l      plan 목록 보기"
echo "    cplan --doctor 환경 진단"
echo ""
