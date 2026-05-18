---
name: fix-error
description: Launch a background agent in an isolated worktree to fix a Sentry error
---

# Fix Error: Launch Isolated Fix Agent

Launch a background agent in a git worktree to implement and test a fix for a specific Sentry error.

## Input

`$ARGUMENTS` — Sentry issue ID followed by a brief fix description.

Example: `/sentry:fix-error 12345 Add nil check before accessing user.email in payment_service.rb`

## Workflow

1. **Parse arguments**: Extract the issue ID (first argument, numeric) and the fix description (remaining text).
   - If no issue ID is provided, ask the developer for one.
   - If no fix description is provided, fetch the issue detail and suggest a fix direction.

2. **Fetch error context**:
   - Call `get_issue_detail` with the issue ID to get the full error details.
   - Call `map_stacktrace` to identify which local files are affected.

3. **Check worktree limit**: Run `git worktree list` and count branches matching `fix/SENTRY-*`.
   - If there are **3 or more** active fix worktrees, **stop** and notify the developer:
     ```
     Maximum concurrent fix worktrees reached (3). 
     Run `/sentry:fix-status` to review and close completed worktrees before launching a new fix.
     ```
   - Otherwise, proceed to step 4.

4. **Generate branch name**: `fix/SENTRY-{short_id}-{slug}` where `{slug}` is derived from the fix description (lowercase, hyphens, max 30 chars).

5. **Launch background agent**: Use the Agent tool with these parameters:
   - `isolation: "worktree"` — creates an isolated git worktree
   - `run_in_background: true` — runs asynchronously
   - `description: "Fix Sentry {short_id}"`

   **Agent prompt** (include all of this in the prompt):
   ```
   You are fixing a production error detected by Sentry.

   ## Error Details
   - Issue: {short_id} — {title}
   - Exception: {exception_type}: {exception_value}
   - Affected files: {list of mapped local files with line numbers}

   ## Fix Description
   {fix description from user}

   ## Instructions
   1. Read the affected source files to understand the context.
   2. Implement the fix as described.
   3. Detect and run the project's test suite:
      - If `Rakefile` exists: `bin/rails test`
      - If `pyproject.toml` exists: `uv run pytest`
      - If `package.json` exists: `npm test`
   4. If tests pass: commit with message `fix: {title} (Sentry {short_id})`
   5. If tests fail: report the failures but do NOT commit.
   6. Report a summary: branch name, files changed, test results.
   ```

6. **Confirm to developer**:
   ```
   Background agent launched on branch `fix/SENTRY-{short_id}-{slug}`.
   You'll be notified when it completes. Use `/sentry:fix-status` to check progress.
   ```

## Notes

- The branch name must include the Sentry issue ID for traceability.
- Never launch more than 3 concurrent fix worktrees.
- The background agent works independently and reports results when done.
