Queue the current plan for Gemini execution.

Steps:
1. Find the most recently modified `.md` file in `docs/superpowers/plans/` using the Glob tool.
2. If no plan file is found, output an error and stop.
3. Write the exact relative plan file path (e.g. `docs/superpowers/plans/2026-03-27-example.md`) to `docs/superpowers/logs/.cplan-execute` using the Write tool. The file must contain only the path, nothing else.
4. Output exactly this (replace `<path>` with the actual path):

```
✓ Gemini 실행 예약: <path>

/exit 를 입력하면 Gemini가 자동으로 plan을 실행합니다.
```
