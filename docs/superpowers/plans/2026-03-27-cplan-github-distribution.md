# cplan GitHub 배포 구조 구성 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** cplan 프로젝트를 독립 GitHub 저장소로 배포 가능하도록 파일 구조를 구성하고, `install.sh` 한 줄로 누구나 동일한 환경을 설치할 수 있게 만든다.

**Architecture:** `/opt/workspace/local/bsh/workspace/cplan` 디렉터리에 독립 git 저장소를 초기화하고, `bin/cplan`, `profiles/plan-only/CLAUDE.md`, `install.sh`, `README.md`, `.gitignore`를 생성한다. install.sh는 대화형 프롬프트로 API 자격증명을 수집하고 gemini-cli를 자동 설치한다.

**Tech Stack:** bash, git, npm (gemini-cli 설치용)

---

## File Map

| 파일 | 역할 | 변경 유형 |
|------|------|-----------|
| `bin/cplan` | 메인 실행 스크립트 (현재 `/root/.local/bin/cplan` 내용) | 생성 |
| `profiles/plan-only/CLAUDE.md` | plan-only 모드 시스템 프롬프트 | 생성 |
| `install.sh` | 자동 설치 스크립트 (prerequisites 체크, 파일 배포, 자격증명 설정) | 생성 |
| `README.md` | 프로젝트 설명 및 설치/사용법 | 생성 |
| `.gitignore` | 민감 파일 제외 (.env, .claude/env, *.log 등) | 생성 |

---

### Task 1: 독립 git 저장소 초기화

**Files:**
- Modify: `/opt/workspace/local/bsh/workspace/cplan/` (git init)

- [ ] **Step 1: cplan 디렉터리에 독립 git 저장소 초기화**

```bash
cd /opt/workspace/local/bsh/workspace/cplan
git init
```

Expected: `Initialized empty Git repository in .../cplan/.git/`

- [ ] **Step 2: 기존 .bkit, .claude 디렉터리는 무시될 것임 — 확인**

```bash
ls -la /opt/workspace/local/bsh/workspace/cplan/
```

Expected: `.bkit/`, `.claude/` 등 숨김 디렉터리 확인

---

### Task 2: .gitignore 생성

**Files:**
- Create: `/opt/workspace/local/bsh/workspace/cplan/.gitignore`

- [ ] **Step 1: .gitignore 파일 생성**

```
# 민감 정보
.env
*.env
.claude/env

# bkit 상태 파일 (로컬 전용)
.bkit/

# Claude Code 로컬 설정
.claude/settings.local.json

# 로그
docs/superpowers/logs/
*.log

# OS
.DS_Store
Thumbs.db
```

파일 경로: `/opt/workspace/local/bsh/workspace/cplan/.gitignore`

- [ ] **Step 2: git status 확인**

```bash
cd /opt/workspace/local/bsh/workspace/cplan && git status
```

Expected: `.bkit/`, `.claude/settings.local.json` 이 untracked에 나타나지 않거나 ignored로 처리됨

---

### Task 3: bin/cplan 스크립트 생성

**Files:**
- Create: `/opt/workspace/local/bsh/workspace/cplan/bin/cplan`

- [ ] **Step 1: bin 디렉터리 생성 후 cplan 스크립트 복사**

```bash
mkdir -p /opt/workspace/local/bsh/workspace/cplan/bin
cp /root/.local/bin/cplan /opt/workspace/local/bsh/workspace/cplan/bin/cplan
```

- [ ] **Step 2: 실행 권한 확인**

```bash
ls -la /opt/workspace/local/bsh/workspace/cplan/bin/cplan
```

Expected: `-rwxr-xr-x` 권한 확인

- [ ] **Step 3: 스크립트 내용 확인 (첫 10줄)**

```bash
head -10 /opt/workspace/local/bsh/workspace/cplan/bin/cplan
```

Expected: `#!/usr/bin/env bash` 및 주석 확인

---

### Task 4: profiles/plan-only/CLAUDE.md 생성

**Files:**
- Create: `/opt/workspace/local/bsh/workspace/cplan/profiles/plan-only/CLAUDE.md`

- [ ] **Step 1: profiles 디렉터리 생성 후 CLAUDE.md 복사**

```bash
mkdir -p /opt/workspace/local/bsh/workspace/cplan/profiles/plan-only
cp /root/.claude/profiles/plan-only/CLAUDE.md \
   /opt/workspace/local/bsh/workspace/cplan/profiles/plan-only/CLAUDE.md
```

- [ ] **Step 2: 복사 확인**

```bash
head -5 /opt/workspace/local/bsh/workspace/cplan/profiles/plan-only/CLAUDE.md
```

Expected: `## PLAN-ONLY MODE` 헤더 확인

---

### Task 5: install.sh 생성

**Files:**
- Create: `/opt/workspace/local/bsh/workspace/cplan/install.sh`

- [ ] **Step 1: install.sh 파일 작성**

파일 내용 (`/opt/workspace/local/bsh/workspace/cplan/install.sh`):

```bash
#!/usr/bin/env bash
#
# cplan install script
# Usage: bash install.sh
#        curl -fsSL https://raw.githubusercontent.com/<user>/cplan/main/install.sh | bash
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

# ── Detect script location (local install vs pipe) ──────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-install.sh}")" 2>/dev/null && pwd || echo "")"

# pipe 방식 (curl | bash)이면 GitHub에서 직접 파일 다운로드
GITHUB_RAW="https://raw.githubusercontent.com/YOUR_GITHUB_USER/cplan/main"

# ── Paths ────────────────────────────────────────────────
BIN_DIR="$HOME/.local/bin"
CLAUDE_DIR="$HOME/.claude"
PROFILE_DIR="$CLAUDE_DIR/profiles/plan-only"
ENV_FILE="$CLAUDE_DIR/env"

# ── Step 1: Prerequisites check ──────────────────────────
echo ""
echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║        cplan installer v1.0            ║${NC}"
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
  # 로컬 repo에서 설치
  cp "$SCRIPT_DIR/bin/cplan" "$BIN_DIR/cplan"
else
  # GitHub에서 직접 다운로드
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

# ── Step 5: API credentials setup ────────────────────────
echo ""
echo -e "${CYAN}────────────────────────────────────────${NC}"
echo -e "${BOLD} API 자격증명 설정${NC}"
echo -e "${CYAN}────────────────────────────────────────${NC}"
echo ""

if [[ -f "$ENV_FILE" ]]; then
  log_warn "$ENV_FILE 이 이미 존재합니다."
  read -rp "덮어쓸까요? [y/N] " overwrite
  if [[ ! "${overwrite:-N}" =~ ^[Yy]$ ]]; then
    log_info "자격증명 설정을 건너뜁니다."
    SKIP_CREDS=true
  else
    SKIP_CREDS=false
  fi
else
  SKIP_CREDS=false
fi

if [[ "${SKIP_CREDS:-false}" == false ]]; then
  echo ""
  echo "Claude API 설정 (claude.ai 기본 로그인 사용 시 Enter로 건너뛰기):"
  echo ""

  read -rp "  ANTHROPIC_AUTH_TOKEN (API 키, 없으면 Enter): " auth_token
  read -rp "  ANTHROPIC_BASE_URL   (커스텀 URL, 없으면 Enter): " base_url
  read -rp "  ANTHROPIC_MODEL      (모델명, 없으면 Enter): " model

  echo ""
  echo "Gemini API 설정:"
  read -rp "  GEMINI_API_KEY (Google AI Studio 키): " gemini_key

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

# ── Step 6: PATH setup ───────────────────────────────────
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
echo "    cplan         - Claude로 plan 작성 → Gemini로 자동 실행"
echo "    cplan -g      - 최근 plan을 Gemini로만 실행"
echo "    cplan -l      - plan 목록 확인"
echo ""

if [[ -n "$SHELL_RC" ]]; then
  echo "  PATH를 즉시 적용하려면:"
  echo "    source $SHELL_RC"
  echo ""
fi
```

- [ ] **Step 2: 실행 권한 부여**

```bash
chmod +x /opt/workspace/local/bsh/workspace/cplan/install.sh
```

- [ ] **Step 3: syntax 확인 (실행하지 않고 문법만)**

```bash
bash -n /opt/workspace/local/bsh/workspace/cplan/install.sh && echo "syntax OK"
```

Expected: `syntax OK`

---

### Task 6: README.md 생성

**Files:**
- Create: `/opt/workspace/local/bsh/workspace/cplan/README.md`

- [ ] **Step 1: README.md 작성**

파일 내용 (`/opt/workspace/local/bsh/workspace/cplan/README.md`):

```markdown
# cplan

**Claude Plan + Gemini Execute** — Claude Code로 실행 계획을 작성하고, Gemini CLI로 자동 실행합니다.

## 동작 방식

```
cplan 실행
  ↓
Claude Code (plan-only 모드)
  → 원하는 작업 설명
  → Claude가 docs/superpowers/plans/YYYY-MM-DD-*.md 생성
  ↓
Gemini CLI가 plan 파일을 읽고 단계별 실행
```

## 설치

### 요구사항

- [Claude Code CLI](https://claude.ai/code)
- Node.js + npm (gemini-cli 설치용)
- bash

### 한 줄 설치

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USER/cplan/main/install.sh | bash
```

### 또는 직접 클론 후 설치

```bash
git clone https://github.com/YOUR_GITHUB_USER/cplan.git
cd cplan
bash install.sh
```

## 사용법

```bash
# Claude로 plan 작성 → Gemini로 자동 실행 (전체 흐름)
cplan

# 최근 plan 파일을 Gemini로 실행만
cplan -g

# 특정 plan 파일 실행
cplan -g docs/superpowers/plans/2026-03-27-my-feature.md

# plan 목록 및 상태 확인
cplan -l
```

## 환경 변수

`~/.claude/env` 파일로 설정:

```bash
# Claude API (커스텀 엔드포인트 사용 시)
ANTHROPIC_AUTH_TOKEN="sk-..."
ANTHROPIC_BASE_URL="https://..."
ANTHROPIC_MODEL="claude-sonnet-4-6"

# Gemini (특정 모델 고정 시)
GEMINI_MODEL="gemini-2.0-flash"   # 미설정 시 자동 폴백
```

Gemini 모델 폴백 순서 (GEMINI_MODEL 미설정 시):
`gemini-2.5-flash-latest` → `gemini-2.0-flash`

## Plan 파일 형식

Claude가 `docs/superpowers/plans/YYYY-MM-DD-<topic>.md` 형식으로 자동 생성합니다.

```markdown
## Goal
무엇을 만들 것인가

## Tasks
- [ ] Task 1: ...
  - [ ] Step 1.1: ...
  - [ ] 검증: ...
```

## 라이선스

MIT
```

---

### Task 7: .claude/settings.json 생성 (공개용 최소 설정)

**Files:**
- Create: `/opt/workspace/local/bsh/workspace/cplan/.claude/settings.json`

- [ ] **Step 1: 공개 저장소용 settings.json 생성**

이 파일은 `.gitignore`에서 `settings.local.json`만 제외하므로, 공유 가능한 최소 설정을 `settings.json`에 저장한다.

파일 내용 (`/opt/workspace/local/bsh/workspace/cplan/.claude/settings.json`):

```json
{
  "permissions": {
    "allow": [],
    "deny": []
  }
}
```

---

### Task 8: 초기 git 커밋

**Files:**
- Modify: `/opt/workspace/local/bsh/workspace/cplan/` (git commit)

- [ ] **Step 1: 독립 git 저장소 초기화 (이미 안 되어 있을 경우)**

```bash
cd /opt/workspace/local/bsh/workspace/cplan
# 기존 .git이 부모 레포의 것이므로 독립 초기화 필요
git init
```

- [ ] **Step 2: 모든 파일 스테이징**

```bash
cd /opt/workspace/local/bsh/workspace/cplan
git add bin/cplan profiles/plan-only/CLAUDE.md install.sh README.md .gitignore .claude/settings.json
```

- [ ] **Step 3: 파일 목록 확인**

```bash
git status
```

Expected: 위 6개 파일이 `Changes to be committed`에 표시됨

- [ ] **Step 4: 초기 커밋**

```bash
git commit -m "feat: initial cplan release

- bin/cplan: Claude Plan + Gemini Execute 메인 스크립트
- profiles/plan-only/CLAUDE.md: plan-only 모드 시스템 프롬프트
- install.sh: 자동 설치 스크립트 (gemini-cli 설치 + 자격증명 설정)
- README.md: 설치 및 사용법
"
```

- [ ] **Step 5: GitHub 저장소 연결 안내 출력**

```bash
echo ""
echo "다음 단계: GitHub에서 새 저장소 생성 후 아래 명령 실행:"
echo ""
echo "  git remote add origin https://github.com/<YOUR_USER>/cplan.git"
echo "  git branch -M main"
echo "  git push -u origin main"
echo ""
echo "install.sh의 GITHUB_RAW URL도 업데이트 필요:"
echo "  GITHUB_RAW=\"https://raw.githubusercontent.com/<YOUR_USER>/cplan/main\""
```

---

### Task 9: install.sh GitHub URL 플레이스홀더 검증

**Files:**
- Modify: `/opt/workspace/local/bsh/workspace/cplan/install.sh` (URL 확인)
- Modify: `/opt/workspace/local/bsh/workspace/cplan/README.md` (URL 확인)

- [ ] **Step 1: install.sh에서 YOUR_GITHUB_USER 플레이스홀더 확인**

```bash
grep "YOUR_GITHUB_USER" /opt/workspace/local/bsh/workspace/cplan/install.sh /opt/workspace/local/bsh/workspace/cplan/README.md
```

Expected: 두 파일 모두에서 `YOUR_GITHUB_USER` 발견 — GitHub repo 생성 후 실제 username으로 교체 필요

- [ ] **Step 2: 최종 파일 트리 확인**

```bash
find /opt/workspace/local/bsh/workspace/cplan -not -path '*/.git/*' -not -path '*/.bkit/*' | sort
```

Expected:
```
cplan/
cplan/.claude/settings.json
cplan/.gitignore
cplan/README.md
cplan/bin/cplan
cplan/docs/superpowers/plans/2026-03-27-cplan-github-distribution.md
cplan/install.sh
cplan/profiles/plan-only/CLAUDE.md
```
