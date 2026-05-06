# cplan

**Claude Plan + Gemini Execute** — Claude Code로 구현 계획을 세우고, Gemini CLI가 실제 코드를 작성합니다.

> 🇰🇷 한국어 README입니다. English version: [README_en.md](README_en.md)

## 어떻게 동작하나요?

```
$ cplan
    ↓
Claude Code 실행 (정상 모드 — /clear, /help 등 모든 기능 사용 가능)
  → 평소처럼 Claude와 대화
  → 구현이 필요한 작업을 요청
    ↓
Claude가 plan 파일 작성 후 자동으로 Gemini CLI 실행
  → Gemini CLI가 plan을 읽고 실제 파일 생성/수정
  → 실시간 진행 상황 출력
    ↓
Claude 세션 유지 — 다음 작업 계속 진행
  → 작업 완료 후 /exit
```

## 왜 cplan인가요?

| 문제 | cplan 해결책 |
|------|-------------|
| AI가 계획은 잘 짜지만 구현은 느림 | Claude가 계획, Gemini가 구현 |
| API 비용 부담 | Gemini CLI 무료 사용 |
| 계획과 구현 사이의 맥락 단절 | plan 파일이 전체 맥락 보존 |
| AI 툴 사이 수동 복사·붙여넣기 | 자동 핸드오프 |

---

## 설치

### 요구사항

- [Claude Code CLI](https://claude.ai/code)
- Node.js + npm
- Google 계정 또는 Gemini API 키 ([AI Studio](https://aistudio.google.com/apikey) — 무료)
- bash / zsh / fish

### 설치하기

```bash
# 원격 설치 (권장)
curl -fsSL https://raw.githubusercontent.com/senghan1992/cplan-use-gemini-cli-as-worker/main/install.sh | bash

# 또는 직접 클론 후 설치
git clone https://github.com/senghan1992/cplan-use-gemini-cli-as-worker.git cplan
cd cplan
bash install.sh
```

### ⚡ 설치 후 필수 — 쉘 설정 반영

설치가 끝나면 **반드시** 아래 명령어를 실행하세요:

```bash
source ~/.bashrc   # bash 사용 시
# 또는
source ~/.zshrc    # zsh 사용 시
```

> 새 터미널을 열어도 됩니다.

### 설치 옵션

```bash
# API 키를 직접 지정
bash install.sh --api-key "YOUR_GEMINI_API_KEY"

# 헤드리스 서버 (OAuth 생략)
bash install.sh --api-key "KEY" --no-oauth

# 완전 자동 (CI/CD)
bash install.sh --api-key "KEY" --unattended
```

---

## 빠른 시작

```bash
# 1. 프로젝트 초기화
cd my-project
cplan --init

# 2. 시작
cplan
```

cplan이 실행되면 Claude Code가 열립니다. 평소처럼 대화하면 됩니다.

**예시:**
```
> 사용자 인증 기능을 추가해줘. JWT 기반으로.
```

Claude가 plan 파일을 작성한 뒤 Gemini CLI를 자동으로 실행합니다.  
Gemini가 실제 코드를 작성하는 동안 진행 상황이 실시간으로 출력됩니다.

---

## 명령어

```bash
# 전체 플로우 (Claude 계획 + Gemini 실행)
cplan

# 기존 plan 파일을 Gemini로 직접 실행
cplan -g
cplan -g docs/superpowers/plans/2026-05-06-auth.md

# plan 목록 및 상태 확인
cplan -l

# 프로젝트 초기화
cplan --init

# 환경 진단
cplan --doctor

# 버전 확인
cplan --version
```

---

## 프로젝트 설정

`cplan --init`을 실행하면 `.cplan` 설정 파일이 생성됩니다:

```ini
# .cplan — 프로젝트 설정
plan_dir = docs/superpowers/plans
log_dir  = docs/superpowers/logs
# gemini_model = gemini-2.5-flash   # 특정 모델 고정 (선택사항)
```

| 설정 | 기본값 | 설명 |
|------|--------|------|
| `plan_dir` | `docs/superpowers/plans` | Claude가 plan 파일을 저장하는 위치 |
| `log_dir` | `docs/superpowers/logs` | Gemini 실행 로그 저장 위치 |
| `gemini_model` | (자동 fallback) | 특정 모델 고정 시 사용 |

---

## 환경 변수

`~/.claude/env` 파일에 저장됩니다:

```bash
# Claude API (커스텀 엔드포인트 사용 시)
ANTHROPIC_AUTH_TOKEN="sk-..."
ANTHROPIC_BASE_URL="https://..."
ANTHROPIC_MODEL="claude-sonnet-4-6"

# Gemini
GEMINI_API_KEY="AIza..."
GEMINI_MODEL="gemini-2.5-flash"   # 선택사항: 모델 고정
```

### Gemini 모델 자동 fallback

`GEMINI_MODEL`이 설정되어 있지 않으면 아래 순서로 자동 시도합니다:
1. `auto-gemini-2.5`
2. `gemini-2.5-flash`
3. `gemini-2.5-flash-lite`
4. `gemini-2.0-flash`

rate limit에 걸리면 다음 모델로 자동 전환됩니다.

---

## Plan 파일 형식

Claude가 `docs/superpowers/plans/YYYY-MM-DD-<topic>.md` 에 자동으로 생성합니다:

```markdown
## Goal
무엇을 만드는가

## Architecture
전체 구조

## Tasks
- [ ] Task 1: 프로젝트 셋업
  - [ ] Step 1.1: 패키지 초기화
  검증: npm test 통과
- [ ] Task 2: 기능 구현
  ...
```

---

## 환경 진단

`cplan --doctor`로 설치 상태를 확인할 수 있습니다:

```
╔════════════════════════════════════════╗
║   cplan doctor — self-diagnostics      ║
╚════════════════════════════════════════╝

  Checking prerequisites...

  ✓ Claude CLI:     2.1.119 (Claude Code)
  ✓ Node.js:        v24.14.1
  ✓ npm:            11.11.0
  ✓ Gemini CLI:     0.38.2

  Checking authentication...

  ✓ Gemini OAuth:   configured
  ✓ Claude API:     token set

  All checks passed! Ready to use.
```

---

## 제거

```bash
# 클론 디렉토리에서
bash uninstall.sh

# 또는 원격으로
curl -fsSL https://raw.githubusercontent.com/senghan1992/cplan-use-gemini-cli-as-worker/main/uninstall.sh | bash
```

---

## License

MIT
