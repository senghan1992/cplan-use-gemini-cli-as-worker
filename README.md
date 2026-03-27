# cplan

**Claude Plan + Gemini Execute** — Claude Code로 실행 계획을 작성하고, Gemini CLI로 자동 실행합니다.

## 동작 방식

```
cplan 실행
  ↓
Claude Code 열림 (plan-only 모드)
  → 원하는 작업 설명
  → Claude가 plan 파일 생성
  → /execute-gemini 입력
  ↓
Gemini CLI가 plan 실행 (진행 상황 실시간 표시)
  ↓
완료 후 Claude Code 세션 유지
  → 다음 작업을 바로 설명 가능
  → /execute-gemini 로 반복 실행
  → 모두 끝나면 /exit
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

Gemini 모델 폴백 순서 (`GEMINI_MODEL` 미설정 시):
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
