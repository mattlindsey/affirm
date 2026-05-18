---
name: monitor
description: Check for new Sentry production errors and propose fixes
---

# Monitor: Single Monitoring Cycle

Execute one monitoring cycle: check for new errors, analyze them, and propose fixes.

## Input

`$ARGUMENTS` — optional environment filter (e.g., `/sentry:monitor production`).

## Workflow

1. **Check for new errors**: Call the `check_new_errors` MCP tool.
   - If `$ARGUMENTS` is not empty, pass it as the `environment` parameter.
   - If the response contains a `warning` about state file corruption, inform the developer.

2. **If no new errors**: Report "No new errors detected since last check" and stop.

3. **For each new error** (process up to 5 per cycle):

   a. Call `get_issue_detail` with `include_pii=False` to get the error details.
   
   b. Call `map_stacktrace` to find which local files correspond to the stack trace.
   
   c. For each mapped local file with confidence "exact" or "partial", read the file around the relevant line number to understand the code context.
   
   d. **Analyze the error**: Based on the exception type, error message, stack trace, and local code context, identify the likely root cause and propose a fix.
   
   e. If the error context seems insufficient due to PII redaction (e.g., the error message references user input that was stripped), note: "Additional context may be available by re-querying with `get_issue_detail` using `include_pii=True`."

4. **Present fix proposals**: For each analyzed error, output a structured proposal:

   ```
   ### Error: [title] (Sentry [short_id])
   
   **Root cause**: [explanation]
   **Affected files**: [list of local files]
   **Suggested fix**: [description of what to change]
   
   **Code change**:
   [show the specific code diff or change needed]
   
   > Launch a background agent to implement this fix? Use: `/sentry:fix-error [issue_id] [brief fix description]`
   ```

5. **Summary**: Report total errors checked, proposals generated, and remind the developer they can use `/sentry:fix-error` to launch isolated fix experiments.

## Notes

- Never use `print()` in any MCP tool calls — use the Context logging methods.
- Limit analysis to 5 errors per cycle to avoid overwhelming the developer.
- Always check stack trace mapping confidence before reading local files — skip "unmapped" frames.
