---
name: fix-status
description: List all active Sentry fix branches and their status
---

# Fix Status: Review Active Fix Branches

List all active fix branches created by `/sentry:fix-error`, show their status, and manage them (merge or discard).

## Workflow

1. **List worktrees**: Run `git worktree list` and parse the output.

2. **Filter fix branches**: Keep only worktrees whose branch name matches `fix/SENTRY-*`.

3. **For each fix worktree**, gather:
   - **Branch name**: from the worktree list output
   - **Worktree path**: the filesystem path
   - **Latest commit**: Run `git -C {worktree_path} log -1 --oneline` to get the last commit message
   - **Files changed**: Run `git -C {worktree_path} diff --stat HEAD~1 HEAD 2>/dev/null` (if a commit exists)
   - **Status**: Determine based on:
     - If a commit with `fix:` prefix exists → "Complete"
     - If no new commits beyond the branch point → "In progress" (agent may still be working)

4. **Present results** as a markdown table:

   ```
   ## Active Fix Branches

   | Branch | Status | Last Commit | Files Changed | Actions |
   |--------|--------|-------------|---------------|---------|
   | fix/SENTRY-PROJECT-123-nil-check | Complete | fix: TypeError (Sentry PROJECT-123) | 2 files | merge / discard |
   | fix/SENTRY-PROJECT-124-timeout | In progress | — | — | wait |
   ```

5. **Handle developer actions**: If the developer asks to merge or discard:

   **Merge**:
   1. Run `git merge {branch_name}` from the main working tree
   2. If merge succeeds: run `git worktree remove {worktree_path}`
   3. If merge conflicts: report the conflicts and let the developer resolve manually

   4. Suggest resolving the Sentry issue:
      ```
      Fix merged. Resolve this issue in Sentry?
      Use: /sentry:resolve {issue_id}
      ```
      Extract the issue ID from the branch name (`fix/SENTRY-{short_id}-*`).

   **Discard**:
   1. Run `git worktree remove {worktree_path} --force`
   2. Run `git branch -D {branch_name}`
   3. Confirm: "Worktree and branch `{branch_name}` have been removed."

6. **If no fix worktrees exist**: Report "No active fix branches found. Use `/sentry:fix-error` to launch a fix."

## Notes

- This skill only manages worktrees created by `/sentry:fix-error` (matching the `fix/SENTRY-*` pattern).
- Always confirm with the developer before merging or discarding.
- After cleanup, the worktree slot becomes available for new `/sentry:fix-error` launches.
