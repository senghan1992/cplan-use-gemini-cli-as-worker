#!/usr/bin/env bash
#
# cplan uninstall script
# Usage: bash uninstall.sh
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[uninstall]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[uninstall]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[uninstall]${NC} $*"; }
log_skip()  { echo -e "${CYAN}[uninstall]${NC} $* (건너뜀)"; }

echo ""
echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║        cplan uninstaller v1.0          ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""
echo "  제거 항목:"
echo "    ~/.local/bin/cplan"
echo "    ~/.claude/profiles/plan-only/CLAUDE.md"
echo "    ~/.claude/commands/execute-gemini.md"
echo "    ~/.claude/env 의 GEMINI_API_KEY 항목"
echo "    ~/.bashrc / ~/.zshrc 의 GEMINI_API_KEY 및 PATH 항목"
echo ""
read -rp "계속할까요? [y/N] " confirm </dev/tty
if [[ ! "${confirm:-N}" =~ ^[Yy]$ ]]; then
  echo "취소됨."
  exit 0
fi
echo ""

# ── cplan 실행 파일 ───────────────────────────────────────
if [[ -f "$HOME/.local/bin/cplan" ]]; then
  rm -f "$HOME/.local/bin/cplan"
  log_ok "삭제: ~/.local/bin/cplan"
else
  log_skip "~/.local/bin/cplan"
fi

# ── plan-only 프로필 ──────────────────────────────────────
if [[ -f "$HOME/.claude/profiles/plan-only/CLAUDE.md" ]]; then
  rm -f "$HOME/.claude/profiles/plan-only/CLAUDE.md"
  rmdir "$HOME/.claude/profiles/plan-only" 2>/dev/null || true
  log_ok "삭제: ~/.claude/profiles/plan-only/"
else
  log_skip "~/.claude/profiles/plan-only/CLAUDE.md"
fi

# ── execute-gemini 명령어 ─────────────────────────────────
if [[ -f "$HOME/.claude/commands/execute-gemini.md" ]]; then
  rm -f "$HOME/.claude/commands/execute-gemini.md"
  log_ok "삭제: ~/.claude/commands/execute-gemini.md"
else
  log_skip "~/.claude/commands/execute-gemini.md"
fi

# ── ~/.claude/env 에서 cplan 관련 항목 제거 ──────────────
ENV_FILE="$HOME/.claude/env"
if [[ -f "$ENV_FILE" ]]; then
  # GEMINI_API_KEY만 제거, 나머지 항목은 유지
  tmp=$(mktemp)
  grep -v "^GEMINI_API_KEY=" "$ENV_FILE" > "$tmp" || true
  if cmp -s "$ENV_FILE" "$tmp"; then
    log_skip "~/.claude/env (GEMINI_API_KEY 항목 없음)"
  else
    mv "$tmp" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    log_ok "~/.claude/env 에서 GEMINI_API_KEY 제거"
  fi
  rm -f "$tmp" 2>/dev/null || true

  # env 파일이 비어있으면 삭제 여부 확인
  if [[ ! -s "$ENV_FILE" ]]; then
    read -rp "~/.claude/env 가 비어 있습니다. 삭제할까요? [y/N] " del_env </dev/tty
    if [[ "${del_env:-N}" =~ ^[Yy]$ ]]; then
      rm -f "$ENV_FILE"
      log_ok "삭제: ~/.claude/env"
    fi
  fi
else
  log_skip "~/.claude/env"
fi

# ── shell RC 파일에서 cplan 관련 항목 제거 ───────────────
for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [[ -f "$RC" ]] || continue

  # cplan PATH 주석 블록 및 GEMINI_API_KEY 제거
  tmp=$(mktemp)
  awk '
    /^# cplan( - Gemini API key)?$/ { skip=1; next }
    /^export GEMINI_API_KEY=/ { skip=1; next }
    /^export PATH="\$HOME\/.local\/bin:\$PATH"/ && skip { skip=0; next }
    { skip=0; print }
  ' "$RC" > "$tmp"

  if cmp -s "$RC" "$tmp"; then
    log_skip "$RC (cplan 항목 없음)"
    rm -f "$tmp"
  else
    mv "$tmp" "$RC"
    log_ok "$RC 에서 cplan 항목 제거"
  fi
done

# ── gemini-cli 제거 여부 확인 ─────────────────────────────
echo ""
if command -v gemini &>/dev/null; then
  read -rp "gemini-cli (npm 전역 패키지)도 제거할까요? [y/N] " del_gemini </dev/tty
  if [[ "${del_gemini:-N}" =~ ^[Yy]$ ]]; then
    npm uninstall -g @google/gemini-cli
    log_ok "gemini-cli 제거 완료"
  else
    log_skip "gemini-cli (유지)"
  fi
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD} 제거 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo ""
