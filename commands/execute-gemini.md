Execute the latest plan with Gemini CLI directly in this session. The Claude session stays open after Gemini finishes so the user can assign the next task.

Steps:
1. Use Glob to find the most recently modified `.md` file in `docs/superpowers/plans/`. If none found, output an error and stop.
2. Show the plan filename and first 15 lines as a preview.
3. Run the following Bash command (replace `<PLAN_FILE>` with the actual relative path):
   ```
   gemini --model auto-gemini-2.5 --yolo -p "You are an implementation agent. Read the plan file and execute it step by step. Check off each task as you complete it. If a step fails, log the error and continue to the next step.\n\nPlan file to read and execute: <PLAN_FILE>"
   ```
4. If the command fails AND the output contains `MODEL_CAPACITY_EXHAUSTED`, `RESOURCE_EXHAUSTED`, or `429`, retry with the next model in this order: `gemini-2.5-flash` → `gemini-2.5-flash-lite`, using the same prompt each time.
5. After Gemini finishes (success or failure), output:
   ```
   ✓ Gemini 실행 완료: <PLAN_FILE>

   다음 작업을 설명해 주세요.
   새 plan을 작성한 뒤 /execute-gemini 로 계속 실행하거나, /exit 로 종료할 수 있습니다.
   ```
