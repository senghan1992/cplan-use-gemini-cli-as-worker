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
