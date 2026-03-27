Execute the latest plan with Gemini CLI in the background, keeping this Claude session alive for further instructions.

Steps:
1. Use Glob to find the most recently modified `.md` file in `docs/superpowers/plans/`. If none found, output an error message and stop.
2. Show the plan filename and first 15 lines as a preview.
3. Run the following Bash command (replace `<PLAN_FILE>` with the actual relative path):
   ```
   nohup cplan -g <PLAN_FILE> > /tmp/cplan-exec.log 2>&1 &
   echo "PID=$!"
   ```
   - `nohup ... &` runs Gemini in the background so this Claude session is NOT terminated.
   - The log is written to `/tmp/cplan-exec.log`. The user can watch it with `tail -f /tmp/cplan-exec.log`.
4. Output the following message immediately after launching:
   ```
   ⏳ Gemini 실행 시작: <PLAN_FILE>

   진행 상황 확인: tail -f /tmp/cplan-exec.log

   다음 작업을 설명해 주세요.
   새 plan을 작성한 뒤 /execute-gemini 로 계속 실행하거나, /exit 로 종료할 수 있습니다.
   ```
5. Stay in the Claude session and wait for the user's next instruction. Do NOT exit or terminate.
