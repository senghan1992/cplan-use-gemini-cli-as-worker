#!/usr/bin/env bash
#
# cplan install script
# Usage: bash install.sh
#        curl -fsSL https://raw.githubusercontent.com/senghan1992/cplan-use-gemini-cli-as-worker/main/install.sh | bash
#

set -euo pipefail

# ── Colors ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[install]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[install]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[install]${NC} $*"; }
log_error() { echo -e "${RED}[install]${NC} $*"; }

# ── Detect script location (local clone vs curl|bash) ───
# curl|bash 실행 시: BASH_SOURCE[0]는 빈 문자열이거나 실제 파일이 아님
# bash install.sh 실행 시: BASH_SOURCE[0]는 실제 파일 경로
SCRIPT_DIR=""
if [[ -f "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

GITHUB_RAW="https://raw.githubusercontent.com/senghan1992/cplan-use-gemini-cli-as-worker/main"

# ── Paths ────────────────────────────────────────────────
BIN_DIR="$HOME/.local/bin"
CLAUDE_DIR="$HOME/.claude"
PROFILE_DIR="$CLAUDE_DIR/profiles/plan-only"
ENV_FILE="$CLAUDE_DIR/env"

# ── Step 1: Prerequisites check ──────────────────────────
echo ""
echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║        cplan installer v1.1            ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""

log_info "Prerequisites 확인 중..."

# claude CLI
if ! command -v claude &>/dev/null; then
  log_error "claude CLI가 설치되어 있지 않습니다."
  log_error "설치: https://claude.ai/code"
  exit 1
fi
log_ok "claude CLI: $(claude --version 2>/dev/null | head -1 || echo 'found')"

# node / npm (gemini-cli 설치에 필요)
if ! command -v npm &>/dev/null; then
  log_warn "npm이 없습니다. gemini-cli를 수동으로 설치해야 합니다."
  log_warn "  npm 설치: https://nodejs.org"
  SKIP_GEMINI=true
else
  SKIP_GEMINI=false
  log_ok "npm: $(npm --version)"
fi

# ── Step 2: Install gemini-cli ───────────────────────────
if [[ "${SKIP_GEMINI:-false}" == false ]]; then
  if command -v gemini &>/dev/null; then
    log_ok "gemini CLI: 이미 설치됨 ($(gemini --version 2>/dev/null | head -1 || echo 'found'))"
  else
    log_info "gemini-cli 설치 중..."
    npm install -g @google/gemini-cli
    log_ok "gemini-cli 설치 완료"
  fi
fi

# ── Step 3: Install cplan script ─────────────────────────
log_info "cplan 스크립트 설치 중..."
mkdir -p "$BIN_DIR"

if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/bin/cplan" ]]; then
  cp "$SCRIPT_DIR/bin/cplan" "$BIN_DIR/cplan"
else
  curl -fsSL "$GITHUB_RAW/bin/cplan" -o "$BIN_DIR/cplan"
fi

chmod +x "$BIN_DIR/cplan"
log_ok "cplan → $BIN_DIR/cplan"

# ── Step 4: Install plan-only profile ────────────────────
log_info "plan-only 프로필 설치 중..."
mkdir -p "$PROFILE_DIR"

if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/profiles/plan-only/CLAUDE.md" ]]; then
  cp "$SCRIPT_DIR/profiles/plan-only/CLAUDE.md" "$PROFILE_DIR/CLAUDE.md"
else
  curl -fsSL "$GITHUB_RAW/profiles/plan-only/CLAUDE.md" -o "$PROFILE_DIR/CLAUDE.md"
fi

log_ok "plan-only profile → $PROFILE_DIR/CLAUDE.md"

# ── Step 5: Install /execute-gemini command ───────────────
log_info "/execute-gemini 명령어 설치 중..."
mkdir -p "$HOME/.claude/commands"

if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/commands/execute-gemini.md" ]]; then
  cp "$SCRIPT_DIR/commands/execute-gemini.md" "$HOME/.claude/commands/execute-gemini.md"
else
  curl -fsSL "$GITHUB_RAW/commands/execute-gemini.md" -o "$HOME/.claude/commands/execute-gemini.md"
fi

log_ok "/execute-gemini → $HOME/.claude/commands/execute-gemini.md"

# ── Step 6: API credentials setup ────────────────────────
echo ""
echo -e "${CYAN}────────────────────────────────────────${NC}"
echo -e "${BOLD} API 자격증명 설정${NC}"
echo -e "${CYAN}────────────────────────────────────────${NC}"
echo ""

SKIP_CREDS=false
if [[ -f "$ENV_FILE" ]]; then
  log_warn "$ENV_FILE 이 이미 존재합니다."
  read -rp "덮어쓸까요? [y/N] " overwrite </dev/tty
  if [[ ! "${overwrite:-N}" =~ ^[Yy]$ ]]; then
    log_info "자격증명 설정을 건너뜁니다."
    SKIP_CREDS=true
  fi
fi

if [[ "$SKIP_CREDS" == false ]]; then
  echo ""
  echo "Claude API 설정 (claude.ai 기본 로그인 사용 시 Enter로 건너뛰기):"
  echo ""

  read -rp "  ANTHROPIC_AUTH_TOKEN (API 키, 없으면 Enter): " auth_token </dev/tty
  read -rp "  ANTHROPIC_BASE_URL   (커스텀 URL, 없으면 Enter): " base_url </dev/tty
  read -rp "  ANTHROPIC_MODEL      (모델명, 없으면 Enter): " model </dev/tty

  echo ""
  echo "Gemini API 설정:"
  read -rp "  GEMINI_API_KEY (Google AI Studio 키, 없으면 Enter): " gemini_key </dev/tty

  mkdir -p "$CLAUDE_DIR"
  {
    [[ -n "${auth_token:-}" ]] && echo "ANTHROPIC_AUTH_TOKEN=\"$auth_token\""
    [[ -n "${base_url:-}" ]]   && echo "ANTHROPIC_BASE_URL=\"$base_url\""
    [[ -n "${model:-}" ]]      && echo "ANTHROPIC_MODEL=\"$model\""
    [[ -n "${gemini_key:-}" ]] && echo "GEMINI_API_KEY=\"$gemini_key\""
  } > "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  log_ok "자격증명 저장: $ENV_FILE"
fi

# ── Step 7: PATH setup ───────────────────────────────────
echo ""
log_info "PATH 설정 확인 중..."

SHELL_RC=""
if [[ -f "$HOME/.zshrc" ]]; then
  SHELL_RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
  SHELL_RC="$HOME/.bashrc"
fi

PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

if [[ -n "$SHELL_RC" ]]; then
  if grep -qF "$HOME/.local/bin" "$SHELL_RC"; then
    log_ok "PATH에 $HOME/.local/bin 이미 포함됨"
  else
    echo "" >> "$SHELL_RC"
    echo "# cplan" >> "$SHELL_RC"
    echo "$PATH_LINE" >> "$SHELL_RC"
    log_ok "PATH 추가됨 → $SHELL_RC"
  fi
else
  log_warn "shell RC 파일을 찾지 못했습니다. 수동으로 PATH를 추가하세요:"
  log_warn "  $PATH_LINE"
fi

# ── Done ─────────────────────────────────────────────────
echo ""
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD} 설치 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo ""
echo "  사용법:"
echo "    cplan         - Claude로 plan 작성 → /execute-gemini 로 실행"
echo "    cplan -g      - 최근 plan을 Gemini로 직접 실행"
echo "    cplan -l      - plan 목록 확인"
echo ""

if [[ -n "$SHELL_RC" ]]; then
  echo "  PATH를 즉시 적용하려면:"
  echo "    source $SHELL_RC"
  echo ""
fi
