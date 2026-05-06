# cplan Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Claude Code를 정상 모드로 실행하되, 구현이 필요할 때 plan 파일을 작성하고 Gemini CLI가 그 파일을 읽어 실행하는 구조로 전환한다.

**Architecture:** `cplan`이 Claude Code를 system prompt(`gemini-worker`)만 추가한 정상 모드로 실행한다. Claude는 분석에 Read/Grep/Glob을 직접 쓰고, 구현 요청 시 plan 파일을 작성한 뒤 `cplan -g` 를 Bash로 호출해 Gemini CLI에 위임한다. Gemini exec는 plan 파일 내용을 `-p` 인자로 정확히 전달하도록 버그를 수정한다.

**Tech Stack:** bash, Claude Code CLI (`claude`), Gemini CLI (`gemini --yolo`)

---

## File Map

| 파일 | 역할 | 변경 유형 |
|------|------|-----------|
| `profiles/gemini-worker/CLAUDE.md` | Claude에게 Gemini 위임 행동 지침 제공 | 신규 |
| `bin/cplan` | 메인 CLI — 프로필·도구 제한 변경, Gemini exec 버그 수정, API fallback 제거 | 수정 |
| `install.sh` | 설치 스크립트 — gemini-worker 프로필 설치, execute-gemini 제거 | 수정 |
| `uninstall.sh` | 제거 스크립트 — gemini-worker 경로로 업데이트 | 수정 |
| `profiles/plan-only/CLAUDE.md` | (삭제) | 삭제 |
| `commands/execute-gemini.md` | (삭제) | 삭제 |

---

### Task 1: `profiles/gemini-worker/CLAUDE.md` 생성

**Files:**
- Create: `profiles/gemini-worker/CLAUDE.md`

- [ ] **Step 1: 파일 생성**

```bash
mkdir -p profiles/gemini-worker
```

파일 내용 (`profiles/gemini-worker/CLAUDE.md`):

```markdown
## GEMINI-WORKER MODE

모든 Claude Code 기능을 정상적으로 사용 가능 (/clear, /help, /compact 등).

### 구현 요청 시 규칙

코드를 작성하거나 파일을 수정해야 할 때:

1. Read / Grep / Glob으로 코드베이스 분석
2. `docs/superpowers/plans/YYYY-MM-DD-<topic>.md` 에 plan 파일 작성
3. Bash로 실행:
   ```
   cplan -g docs/superpowers/plans/<filename>.md
   ```
4. 완료 후 Read로 결과 검증하고 사용자에게 보고

### Plan 파일 필수 구조

```markdown
## Goal
무엇을 만드는가

## Tasks
- [ ] Task 1: ...
  - [ ] Step 1.1: ...
  검증: <확인 방법>
```

### 핵심 규칙

- **Write / Edit 도구로 직접 파일 수정 금지** — 반드시 Gemini를 통해
- Read / Grep / Glob은 직접 사용 가능
- cplan -g 실행 후 Gemini 출력이 완료될 때까지 대기
- 실패 시 사용자에게 알리고 다음 지시 요청
```

- [ ] **Step 2: 파일 생성 확인**

```bash
cat profiles/gemini-worker/CLAUDE.md
```

Expected: 위 내용이 출력됨.

- [ ] **Step 3: Commit**

```bash
git add profiles/gemini-worker/CLAUDE.md
git commit -m "feat: add gemini-worker profile to replace plan-only"
```

---

### Task 2: `bin/cplan` — PROFILE_DIR 변경

**Files:**
- Modify: `bin/cplan:24`

- [ ] **Step 1: PROFILE_DIR 상수 변경**

`bin/cplan` 의 24번째 줄 근방:
```bash
# 변경 전
PROFILE_DIR="$HOME/.claude/profiles/plan-only"

# 변경 후
PROFILE_DIR="$HOME/.claude/profiles/gemini-worker"
```

- [ ] **Step 2: 확인**

```bash
grep "PROFILE_DIR" bin/cplan
```

Expected: `PROFILE_DIR="$HOME/.claude/profiles/gemini-worker"` 만 출력.

---

### Task 3: `bin/cplan` — Claude 세션 실행 변경 (도구 제한 제거)

**Files:**
- Modify: `bin/cplan:671-675`

- [ ] **Step 1: `--tools`, `--disallowedTools` 제거**

`bin/cplan` 의 claude 실행 부분:
```bash
# 변경 전
command claude \
  --tools "Read,Glob,Grep,Write,Bash(gemini *,cplan *,nohup *)" \
  --disallowedTools "Edit" \
  --append-system-prompt "$system_prompt" \
  || true

# 변경 후
command claude \
  --append-system-prompt "$system_prompt" \
  || true
```

- [ ] **Step 2: doctor 체크에서 plan-only 관련 메시지 업데이트**

`run_doctor` 함수 안의 plan profile 체크 부분:
```bash
# 변경 전
if [[ -f "$PROFILE_DIR/CLAUDE.md" ]]; then
  echo -e "  ${GREEN}✓${NC} Plan profile:   $PROFILE_DIR/CLAUDE.md"
else
  echo -e "  ${RED}✗${NC} Plan profile:   not found at $PROFILE_DIR/CLAUDE.md"
  echo -e "    ${DIM}Run install.sh to fix${NC}"
  issues=$((issues + 1))
fi

# 변경 후
if [[ -f "$PROFILE_DIR/CLAUDE.md" ]]; then
  echo -e "  ${GREEN}✓${NC} Worker profile: $PROFILE_DIR/CLAUDE.md"
else
  echo -e "  ${RED}✗${NC} Worker profile: not found at $PROFILE_DIR/CLAUDE.md"
  echo -e "    ${DIM}Run install.sh to fix${NC}"
  issues=$((issues + 1))
fi
```

- [ ] **Step 3: doctor 체크에서 `/execute-gemini` 슬래시 커맨드 체크 제거**

`run_doctor` 함수 안의 slash command 체크 블록 전체 삭제:
```bash
# 삭제할 블록
if [[ -f "$HOME/.claude/commands/execute-gemini.md" ]]; then
  echo -e "  ${GREEN}✓${NC} Slash command:  /execute-gemini"
else
  echo -e "  ${RED}✗${NC} Slash command:  /execute-gemini not found"
  echo -e "    ${DIM}Run install.sh to fix${NC}"
  issues=$((issues + 1))
fi
```

- [ ] **Step 4: 확인**

```bash
bash bin/cplan --doctor 2>/dev/null | grep -E "profile|command" || true
```

Expected: `Worker profile` 라인만 있고 `/execute-gemini` 라인 없음.

---

### Task 4: `bin/cplan` — Gemini exec 버그 수정 (`-p "..."`)

**Files:**
- Modify: `bin/cplan:482-486` (run_gemini_execute 함수)

- [ ] **Step 1: 플랜 내용을 실제로 Gemini에 전달하도록 수정**

`run_gemini_execute` 함수 내의 gemini 호출 부분:
```bash
# 변경 전
gemini \
  --model "$model" \
  --yolo \
  -p "..." \
  > "$attempt_out" 2> "$attempt_err" &

# 변경 후
local plan_prompt
plan_prompt="You are an implementation agent. Execute the following plan step by step. Complete all tasks:\n\n$(cat "$plan_file")"

gemini \
  --model "$model" \
  --yolo \
  -p "$plan_prompt" \
  > "$attempt_out" 2> "$attempt_err" &
```

- [ ] **Step 2: 확인 — 버그가 없어졌는지 grep**

```bash
grep 'p "\.\.\."' bin/cplan
```

Expected: 출력 없음 (버그 라인이 사라짐).

---

### Task 5: `bin/cplan` — `run_gemini_api_fallback` 제거

**Files:**
- Modify: `bin/cplan:361-428`

- [ ] **Step 1: `run_gemini_api_fallback` 함수 전체 삭제**

`bin/cplan` 에서 아래 블록 전체를 삭제한다 (약 361~428번 줄):
```bash
run_gemini_api_fallback() {
    ...
    # 함수 끝 닫는 중괄호까지 전부 삭제
}
```

- [ ] **Step 2: `run_gemini_execute` 안의 fallback 호출도 제거**

`run_gemini_execute` 함수 안 실패 처리 부분:
```bash
# 변경 전
  else
    {
      echo ""
      echo "[Failed] — $(date '+%Y-%m-%d %H:%M:%S')"
    } >> "$log_file"
    log_error "✗ All Gemini CLI models failed."
    run_gemini_api_fallback "$plan_file"
    final_exit_code=$?
    if [[ $final_exit_code -ne 0 ]]; then
        log_error "✗ REST API fallback also failed."
    fi
  fi

# 변경 후
  else
    {
      echo ""
      echo "[Failed] — $(date '+%Y-%m-%d %H:%M:%S')"
    } >> "$log_file"
    log_error "✗ All Gemini CLI models failed. Check log: $log_file"
  fi
```

- [ ] **Step 3: 확인**

```bash
grep "run_gemini_api_fallback\|REST API fallback" bin/cplan
```

Expected: 출력 없음.

---

### Task 6: `install.sh` 업데이트

**Files:**
- Modify: `install.sh:78,190,205-209`

- [ ] **Step 1: PROFILE_DIR 변경 (78번 줄)**

```bash
# 변경 전
PROFILE_DIR="$CLAUDE_DIR/profiles/plan-only"

# 변경 후
PROFILE_DIR="$CLAUDE_DIR/profiles/gemini-worker"
```

- [ ] **Step 2: mkdir에서 commands 제거, 프로필 설치 경로 변경 (190, 205-209번 줄)**

```bash
# 변경 전
mkdir -p "$BIN_DIR" "$PROFILE_DIR" "$HOME/.claude/commands"
...
_install_file "profiles/plan-only/CLAUDE.md"    "$PROFILE_DIR/CLAUDE.md"
log_ok "plan-only profile → $PROFILE_DIR/CLAUDE.md"

_install_file "commands/execute-gemini.md"       "$HOME/.claude/commands/execute-gemini.md"
log_ok "/execute-gemini → $HOME/.claude/commands/execute-gemini.md"

# 변경 후
mkdir -p "$BIN_DIR" "$PROFILE_DIR"
...
_install_file "profiles/gemini-worker/CLAUDE.md"  "$PROFILE_DIR/CLAUDE.md"
log_ok "gemini-worker profile → $PROFILE_DIR/CLAUDE.md"
# (execute-gemini 설치 두 줄 삭제)
```

- [ ] **Step 3: 확인**

```bash
grep -n "plan-only\|execute-gemini" install.sh
```

Expected: 출력 없음.

---

### Task 7: `uninstall.sh` 업데이트

**Files:**
- Modify: `uninstall.sh:31-32,52-58,61-66`

- [ ] **Step 1: 안내 메시지 변경 (31-32번 줄)**

```bash
# 변경 전
echo "    ~/.claude/profiles/plan-only/CLAUDE.md"
echo "    ~/.claude/commands/execute-gemini.md"

# 변경 후
echo "    ~/.claude/profiles/gemini-worker/CLAUDE.md"
```

- [ ] **Step 2: plan-only 제거 블록 → gemini-worker 로 변경 (52-58번 줄)**

```bash
# 변경 전
if [[ -f "$HOME/.claude/profiles/plan-only/CLAUDE.md" ]]; then
  rm -f "$HOME/.claude/profiles/plan-only/CLAUDE.md"
  rmdir "$HOME/.claude/profiles/plan-only" 2>/dev/null || true
  log_ok "Removed: ~/.claude/profiles/plan-only/"
else
  log_skip "~/.claude/profiles/plan-only/CLAUDE.md"
fi

# 변경 후
if [[ -f "$HOME/.claude/profiles/gemini-worker/CLAUDE.md" ]]; then
  rm -f "$HOME/.claude/profiles/gemini-worker/CLAUDE.md"
  rmdir "$HOME/.claude/profiles/gemini-worker" 2>/dev/null || true
  log_ok "Removed: ~/.claude/profiles/gemini-worker/"
else
  log_skip "~/.claude/profiles/gemini-worker/CLAUDE.md"
fi
```

- [ ] **Step 3: execute-gemini 제거 블록 삭제 (61-66번 줄)**

아래 블록 전체 삭제:
```bash
# 삭제
if [[ -f "$HOME/.claude/commands/execute-gemini.md" ]]; then
  rm -f "$HOME/.claude/commands/execute-gemini.md"
  log_ok "Removed: ~/.claude/commands/execute-gemini.md"
else
  log_skip "~/.claude/commands/execute-gemini.md"
fi
```

- [ ] **Step 4: 확인**

```bash
grep -n "plan-only\|execute-gemini" uninstall.sh
```

Expected: 출력 없음.

---

### Task 8: 구 파일 삭제

**Files:**
- Delete: `profiles/plan-only/CLAUDE.md`
- Delete: `commands/execute-gemini.md`

- [ ] **Step 1: 구 파일 삭제 및 git 스테이징**

```bash
git rm profiles/plan-only/CLAUDE.md
rmdir profiles/plan-only 2>/dev/null || true
git rm commands/execute-gemini.md
```

- [ ] **Step 2: 확인**

```bash
ls profiles/
```

Expected: `gemini-worker/` 디렉토리만 있음.

---

### Task 9: 전체 smoke test + 최종 커밋

- [ ] **Step 1: syntax 검사**

```bash
bash -n bin/cplan && echo "OK: bin/cplan syntax valid"
bash -n install.sh && echo "OK: install.sh syntax valid"
bash -n uninstall.sh && echo "OK: uninstall.sh syntax valid"
```

Expected: 세 줄 모두 `OK:` 출력.

- [ ] **Step 2: doctor 실행**

```bash
bash bin/cplan --doctor
```

Expected:
- `Worker profile: ~/.claude/profiles/gemini-worker/CLAUDE.md` — 설치된 경우 ✓, 미설치 시 ✗ 표시 (정상)
- `/execute-gemini` 관련 항목 없음

- [ ] **Step 3: `-p "..."` 버그 최종 확인**

```bash
grep -n 'p "\.\.\."' bin/cplan && echo "BUG STILL PRESENT" || echo "OK: bug fixed"
```

Expected: `OK: bug fixed`

- [ ] **Step 4: 최종 커밋**

```bash
git add bin/cplan install.sh uninstall.sh profiles/gemini-worker/CLAUDE.md
git status
git commit -m "feat: overhaul cplan — gemini-worker mode, fix gemini exec bug, remove plan-only"
```
