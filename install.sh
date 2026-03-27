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
# curl|bash 실행 시: BASH_SOURCE[0]는 실제 파일이 아님 → SCRIPT_DIR=""
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

# shell RC 파일 탐지 (PATH 및 env 설정용)
SHELL_RC=""
if [[ -f "$HOME/.zshrc" ]]; then
  SHELL_RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
  SHELL_RC="$HOME/.bashrc"
fi

# ── Banner ───────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║        cplan installer v1.2            ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""

# ── Step 1: Prerequisites check ──────────────────────────
log_info "Step 1/6  Prerequisites 확인 중..."

if ! command -v claude &>/dev/null; then
  log_error "claude CLI가 설치되어 있지 않습니다."
  log_error "설치: https://claude.ai/code"
  exit 1
fi
log_ok "claude CLI: $(claude --version 2>/dev/null | head -1 || echo 'found')"

SKIP_GEMINI_INSTALL=false
if ! command -v npm &>/dev/null; then
  log_warn "npm이 없습니다. gemini-cli를 수동으로 설치해야 합니다: https://nodejs.org"
  SKIP_GEMINI_INSTALL=true
else
  log_ok "npm: $(npm --version)"
fi

# ── Step 2: Install gemini-cli ───────────────────────────
log_info "Step 2/6  gemini-cli 설치 중..."

if [[ "$SKIP_GEMINI_INSTALL" == true ]]; then
  log_warn "npm 없음 — gemini-cli 설치 건너뜀"
elif command -v gemini &>/dev/null; then
  log_ok "gemini CLI: 이미 설치됨"
else
  npm install -g @google/gemini-cli
  log_ok "gemini-cli 설치 완료"
fi

# ── Step 3: Install cplan files ──────────────────────────
log_info "Step 3/6  cplan 파일 설치 중..."
mkdir -p "$BIN_DIR" "$PROFILE_DIR" "$HOME/.claude/commands"

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

_install_file "profiles/plan-only/CLAUDE.md"    "$PROFILE_DIR/CLAUDE.md"
log_ok "plan-only profile → $PROFILE_DIR/CLAUDE.md"

_install_file "commands/execute-gemini.md"       "$HOME/.claude/commands/execute-gemini.md"
log_ok "/execute-gemini → $HOME/.claude/commands/execute-gemini.md"

# ── Step 4: Gemini 인증 ───────────────────────────────────
echo ""
echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
log_info "Step 4/6  Gemini 인증 설정"
echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
echo ""
echo "  Gemini CLI를 사용하려면 인증이 필요합니다."
echo ""
echo -e "  ${BOLD}방법 A (권장) — API 키${NC}"
echo "    브라우저 없이 즉시 사용 가능"
echo "    발급: https://aistudio.google.com/apikey"
echo ""
echo -e "  ${BOLD}방법 B — Google OAuth${NC}"
echo "    지금 브라우저로 인증 (한 번만 필요)"
echo "    API 키 없이 Enter"
echo ""
read -rp "  GEMINI_API_KEY (없으면 Enter → OAuth 진행): " gemini_key </dev/tty

if [[ -n "${gemini_key:-}" ]]; then
  # ── 방법 A: API 키 ────────────────────────────────────
  export GEMINI_API_KEY="$gemini_key"

  # shell RC에 영구 등록 (gemini 직접 실행 시에도 동작)
  if [[ -n "$SHELL_RC" ]]; then
    if grep -q "GEMINI_API_KEY" "$SHELL_RC" 2>/dev/null; then
      # 기존 항목 교체
      sed -i "s|^export GEMINI_API_KEY=.*|export GEMINI_API_KEY=\"$gemini_key\"|" "$SHELL_RC"
    else
      echo "" >> "$SHELL_RC"
      echo "# cplan - Gemini API key" >> "$SHELL_RC"
      echo "export GEMINI_API_KEY=\"$gemini_key\"" >> "$SHELL_RC"
    fi
    log_ok "GEMINI_API_KEY → $SHELL_RC"
  fi

  # 동작 확인
  log_info "Gemini API 키 연결 테스트 중..."
  if gemini --model gemini-2.0-flash -p "say: ok" 2>/dev/null | grep -qi "ok"; then
    log_ok "Gemini 연결 성공!"
  else
    log_warn "응답 확인 실패 — API 키가 올바른지 https://aistudio.google.com/apikey 에서 확인하세요"
  fi
else
  # ── 방법 B: OAuth ─────────────────────────────────────
  log_info "Google OAuth 인증을 시작합니다 (브라우저가 열립니다)..."
  echo ""
  gemini -p "say: authentication complete" --model gemini-2.0-flash </dev/tty || true
  echo ""
  log_ok "OAuth 인증 완료 — 인증 정보가 저장되었습니다"
  gemini_key=""
fi

# ── Step 5: Claude API 설정 (선택) ───────────────────────
echo ""
echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
log_info "Step 5/6  Claude API 설정 (선택 — claude.ai 기본 로그인이면 Enter)"
echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
echo ""

SKIP_CLAUDE_CREDS=false
if [[ -f "$ENV_FILE" ]]; then
  log_warn "$ENV_FILE 이 이미 존재합니다."
  read -rp "  덮어쓸까요? [y/N] " overwrite </dev/tty
  [[ ! "${overwrite:-N}" =~ ^[Yy]$ ]] && SKIP_CLAUDE_CREDS=true
fi

if [[ "$SKIP_CLAUDE_CREDS" == false ]]; then
  read -rp "  ANTHROPIC_AUTH_TOKEN (없으면 Enter): " auth_token </dev/tty
  read -rp "  ANTHROPIC_BASE_URL   (없으면 Enter): " base_url   </dev/tty
  read -rp "  ANTHROPIC_MODEL      (없으면 Enter): " model       </dev/tty

  mkdir -p "$CLAUDE_DIR"
  {
    [[ -n "${auth_token:-}" ]] && echo "ANTHROPIC_AUTH_TOKEN=\"$auth_token\""
    [[ -n "${base_url:-}" ]]   && echo "ANTHROPIC_BASE_URL=\"$base_url\""
    [[ -n "${model:-}" ]]      && echo "ANTHROPIC_MODEL=\"$model\""
    [[ -n "${gemini_key:-}" ]] && echo "GEMINI_API_KEY=\"$gemini_key\""
  } > "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  log_ok "설정 저장: $ENV_FILE"
fi

# ── Step 6: PATH 설정 ────────────────────────────────────
log_info "Step 6/6  PATH 설정 확인 중..."

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
  log_warn "shell RC 파일 없음. 수동으로 추가하세요: $PATH_LINE"
fi

# ── Done ─────────────────────────────────────────────────
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD} 설치 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "  사용법:"
echo "    cplan         - Claude로 plan 작성 → /execute-gemini 로 실행"
echo "    cplan -g      - 최근 plan을 Gemini로 직접 실행"
echo "    cplan -l      - plan 목록 확인"
echo ""
if [[ -n "$SHELL_RC" ]]; then
  echo "  지금 바로 사용하려면:"
  echo "    source $SHELL_RC"
  echo ""
fi
