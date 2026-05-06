# cplan Overhaul Design
Date: 2026-05-06

## Goal

cplan의 핵심 가치를 유지하면서 UX를 개선한다:
- Claude Code가 plan 문서를 작성
- Gemini CLI가 그 문서를 읽고 구현
- 사용자는 Claude Code를 정상 모드로 사용 (모든 기능 사용 가능)
- `/execute-gemini` 같은 수동 트리거 없이 자동 오케스트레이션

## Architecture

```
cplan
  ↓
claude (정상 모드, 모든 기능 사용 가능)
  + system prompt: gemini-worker 가이드
  │
  ├─ 분석: Read / Grep / Glob (Claude 직접)
  │
  └─ 구현 요청 시:
       1. Claude → plan 파일 작성 (docs/superpowers/plans/)
       2. Claude → Bash로 cplan -g <plan_file> 실행
       3. Gemini CLI → plan 읽고 구현
       4. Claude → Read로 결과 검증
```

## Changed Files

| 파일 | 변경 유형 | 내용 |
|------|-----------|------|
| `bin/cplan` | 수정 | 프로필 교체, Gemini exec 버그 수정, API fallback 제거 |
| `profiles/gemini-worker/CLAUDE.md` | 신규 | Claude의 위임 행동 지침 |
| `profiles/plan-only/CLAUDE.md` | 삭제 | 더 이상 사용 안 함 |
| `commands/execute-gemini.md` | 삭제 | 더 이상 필요 없음 |

## Detailed Design

### 1. `bin/cplan` 변경

#### 1a. Phase 1 (Claude 세션) 변경
```bash
# 변경 전
PROFILE_DIR="$HOME/.claude/profiles/plan-only"
command claude \
  --tools "Read,Glob,Grep,Write,Bash(gemini *,cplan *,nohup *)" \
  --disallowedTools "Edit" \
  --append-system-prompt "$system_prompt"

# 변경 후
PROFILE_DIR="$HOME/.claude/profiles/gemini-worker"
command claude \
  --append-system-prompt "$system_prompt"
  # 도구 제한 없음 — 정상 모드
```

#### 1b. Gemini exec 버그 수정 (`run_gemini_execute`)
```bash
# 변경 전 (버그: 플랜 내용이 전달 안 됨)
gemini --model "$model" --yolo -p "..."

# 변경 후
local plan_prompt
plan_prompt="You are an implementation agent. Execute the following plan step by step. Complete all tasks:\n\n$(cat "$plan_file")"

gemini --model "$model" --yolo -p "$plan_prompt"
```

#### 1c. 제거
- `run_gemini_api_fallback` 함수 전체 제거 (복잡하고 불안정한 REST API 방식)

### 2. `profiles/gemini-worker/CLAUDE.md` (신규)

Claude에게 전달되는 system prompt. 핵심 내용:

```markdown
## GEMINI-WORKER MODE

모든 Claude Code 기능을 정상적으로 사용 가능 (/clear, /help 등).

### 구현 요청 시 규칙

코드를 작성하거나 파일을 수정해야 할 때:

1. Read/Grep/Glob으로 코드베이스 분석
2. docs/superpowers/plans/YYYY-MM-DD-<topic>.md 에 plan 파일 작성
3. Bash로 실행: cplan -g docs/superpowers/plans/<filename>.md
4. 완료 후 Read로 결과 검증

### Plan 파일 형식

- Goal: 무엇을 만드는가
- Tasks: 체크박스 형식의 numbered 작업 목록
- 각 작업에 검증 단계 포함

### Write/Edit 직접 사용 금지

파일 수정은 항상 Gemini CLI를 통해.
Read/Grep/Glob은 직접 사용 가능.
```

### 3. `install.sh` / `uninstall.sh` 변경

- `plan-only` 프로필 설치 → `gemini-worker` 프로필 설치로 교체
- `commands/execute-gemini.md` 설치 제거

## Error Handling

| 상황 | 처리 |
|------|------|
| Gemini rate limit | 기존 모델 fallback 로직 유지 |
| 모든 Gemini 모델 실패 | Claude가 사용자에게 알리고 재시도 여부 확인 |
| plan 파일 없음 | cplan -g 가 오류 메시지 출력 |

## What Stays the Same

- `cplan -g <file>` — 수동 실행 (기존 그대로)
- `cplan -l` — plan 목록
- `cplan --init` — 프로젝트 초기화
- `cplan --doctor` — 진단
- Gemini 모델 fallback 순서
- `.cplan` 프로젝트 설정 파일

## What Is Removed

- `profiles/plan-only/CLAUDE.md` — plan-only 모드 전체
- `commands/execute-gemini.md` — 수동 실행 슬래시 커맨드
- `run_gemini_api_fallback` — REST API fallback
