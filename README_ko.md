# cplan

**Claude Plan + Gemini Execute** — Claude Code(Sonnet)로 실행 계획을 작성하고, Gemini CLI로 자동 실행합니다.

> 🇬🇧 [English README](README.md)

## 동작 방식

```
$ cplan
    ↓
Claude Code 열림 (plan-only 모드)
  → 원하는 작업 설명
  → Claude가 구조화된 plan 파일 생성
  → /execute-gemini 입력
    ↓
Gemini CLI가 plan을 읽고 단계별 실행
  (실시간 진행 상황 스트리밍)
    ↓
Claude 세션 유지
  → 다음 작업을 바로 설명
  → /execute-gemini 로 반복 실행
  → 모두 끝나면 /exit
```

## 왜 cplan인가?

| 문제 | cplan 해결책 |
|------|-------------|
| 계획은 잘 세우지만 실행이 약한 AI | Sonnet이 계획, Gemini가 실행 |
| 비싼 API 비용 | Gemini CLI 무료 (한도 있음) |
| 계획과 코딩 사이의 컨텍스트 손실 | Plan 파일이 전체 맥락 보존 |
| AI 도구 간 수동 복사-붙여넣기 | CLI로 자동 핸드오프 |

## 설치

### 요구사항

- [Claude Code CLI](https://claude.ai/code) (계획 에이전트)
- Node.js + npm (gemini-cli 설치용)
- Gemini API 키 ([Google AI Studio](https://aistudio.google.com/apikey) — 무료) 또는 Google 계정
- bash / zsh / fish

### 한 줄 설치

```bash
curl -fsSL https://raw.githubusercontent.com/senghan1992/cplan-use-gemini-cli-as-worker/main/install.sh | bash
```

### 또는 클론 후 설치

```bash
git clone https://github.com/senghan1992/cplan-use-gemini-cli-as-worker.git cplan
cd cplan
bash install.sh
```

### 고급 설치 옵션

```bash
# API 키로 비대화 설치
bash install.sh --api-key "YOUR_GEMINI_API_KEY"

# 헤드리스 서버 (OAuth 건너뛰기)
bash install.sh --api-key "KEY" --no-oauth

# 완전 비대화 (CI/CD 용)
bash install.sh --api-key "KEY" --unattended
```

## 빠른 시작

```bash
# 1. 프로젝트 초기화
cd my-project
cplan --init

# 2. 계획 작성 + 실행 시작
cplan
```

## 사용법

```bash
# 전체 흐름: Claude가 계획 → Gemini가 실행
cplan

# 최근 plan 바로 실행
cplan -g

# 특정 plan 실행
cplan -g docs/superpowers/plans/2026-03-27-my-feature.md

# plan 목록 및 상태 확인
cplan -l

# 현재 디렉터리를 cplan 프로젝트로 초기화
cplan --init

# 환경 자가 진단
cplan --doctor

# 버전 확인
cplan --version
```

## 프로젝트 설정

프로젝트 루트에서 `cplan --init` 실행하면 `.cplan` 설정 파일이 생성됩니다:

```ini
# .cplan - 프로젝트 설정
plan_dir = docs/superpowers/plans
log_dir  = docs/superpowers/logs
# gemini_model = auto-gemini-2.5
```

| 키 | 기본값 | 설명 |
|----|--------|------|
| `plan_dir` | `docs/superpowers/plans` | Claude가 plan 파일을 저장하는 위치 |
| `log_dir` | `docs/superpowers/logs` | Gemini 실행 로그 위치 |
| `gemini_model` | (자동 폴백) | 특정 Gemini 모델 고정 |

## 환경 변수

`~/.claude/env`에 저장:

```bash
# Claude API (커스텀 엔드포인트 사용 시만)
ANTHROPIC_AUTH_TOKEN="sk-..."
ANTHROPIC_BASE_URL="https://..."
ANTHROPIC_MODEL="claude-sonnet-4-6"

# Gemini
GEMINI_API_KEY="AIza..."
GEMINI_MODEL="gemini-2.5-flash"   # 선택: 모델 고정
```

### Gemini 모델 폴백 순서

`GEMINI_MODEL` 미설정 시 다음 순서로 시도:
1. `auto-gemini-2.5`
2. `gemini-2.5-flash`
3. `gemini-2.5-flash-lite`

모델이 용량 초과 시 자동으로 다음 모델로 전환됩니다.

## 자가 진단

`cplan --doctor`로 환경 점검:

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

## 삭제

```bash
# 클론에서 설치한 경우
bash uninstall.sh

# 또는 다운로드 후 실행
curl -fsSL https://raw.githubusercontent.com/senghan1992/cplan-use-gemini-cli-as-worker/main/uninstall.sh | bash
```

## 라이선스

MIT
