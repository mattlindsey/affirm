---
name: resolve
description: Resolve, ignore, or reopen a Sentry issue after a fix is deployed
---

# Resolve: Update Sentry Issue Status

Update the status of a Sentry issue directly from Claude Code after verifying a fix.

## Input

`$ARGUMENTS` — Sentry issue ID, optionally followed by a status.

Examples:
- `/sentry:resolve 12345` — resolve the issue
- `/sentry:resolve 12345 ignored` — ignore the issue
- `/sentry:resolve 12345 unresolved` — reopen the issue

## Workflow

1. **Parse arguments**: Extract the issue ID (first argument, numeric) and optional status (second argument, defaults to "resolved").
   - If no issue ID is provided, ask the developer for one.
   - Validate the status is one of: `resolved`, `ignored`, `unresolved`.

2. **Fetch current state**: Call `get_issue_detail` with the issue ID to confirm it exists and show its current status.
   - Display: issue title, current status, error count, last seen date.

3. **Confirm action**: Before making the change, ask the developer to confirm:
   ```
   Issue: {short_id} — {title}
   Current status: {status}
   Action: Change to "{new_status}"

   Proceed? (yes/no)
   ```

4. **Update status**: Call the `resolve_issue` MCP tool with the issue ID and status.

5. **Report result**:
   ```
   Updated {short_id} — {title}
   Status: {old_status} → {new_status}
   Sentry link: {permalink}
   ```

## Notes

- This command always asks for confirmation before making changes.
- The `resolve_issue` tool requires `project:write` scope on the Sentry auth token.
- For advanced options (resolve in next release, ignore for N minutes), call the `resolve_issue` tool directly with the appropriate parameters.
- After merging a fix branch from `/sentry:fix-error`, use this command to close the loop in Sentry.
