---
name: report
description: Generate a markdown summary of Sentry error status for standups, PRs, or sprint reviews
---

# Report: Sentry Error Summary

Generate a markdown report summarizing production error status for a given time period.

## Input

`$ARGUMENTS` — optional period and environment filter.

Examples:
- `/sentry:report` — default 14-day report, all environments
- `/sentry:report 24h` — last 24 hours
- `/sentry:report 14d production` — last 14 days, production only

Supported periods: `24h`, `14d`.

## Workflow

1. **Parse arguments**: Extract the period (first argument, defaults to `7d`) and optional environment (second argument).

2. **Gather data** by calling the `list_issues` MCP tool three times:

   a. **New/recent errors**: `list_issues(query="is:unresolved", sort_by="new", date_range=period, environment=env, page_size=10)`

   b. **Top recurring errors**: `list_issues(query="is:unresolved", sort_by="freq", date_range=period, environment=env, page_size=5)`

   c. **Recently resolved**: `list_issues(query="is:resolved", sort_by="date", date_range=period, environment=env, page_size=10)`

3. **Format the report** as markdown:

   ```markdown
   ## Sentry Error Report — {period}
   **Environment:** {environment or "all"} | **Generated:** {date}

   ### Overview
   - **Unresolved errors:** {count from new errors query}
   - **Resolved in period:** {count from resolved query}

   ### New Errors (most recent first)
   | Error | Level | Count | First Seen | Last Seen |
   |-------|-------|-------|------------|-----------|
   | [{short_id}]({permalink}) {title} | {level} | {count} | {first_seen} | {last_seen} |
   | ... | ... | ... | ... | ... |

   ### Top Recurring (by frequency)
   | Error | Count | Users Affected |
   |-------|-------|----------------|
   | [{short_id}]({permalink}) {title} | {count} | {user_count} |
   | ... | ... | ... |

   ### Recently Resolved
   | Error | Count | Resolved |
   |-------|-------|----------|
   | [{short_id}]({permalink}) {title} | {count} | {last_seen} |
   | ... | ... | ... |
   ```

4. **Output the report** directly to the developer. Format dates as relative where helpful (e.g., "2 hours ago", "3 days ago").

5. **If any section is empty**, show "None in this period" instead of an empty table.

## Notes

- This command is read-only — it only calls `list_issues` with different query parameters.
- The report is designed to be copy-pasted into Slack, PRs, or meeting notes.
- `short_id` and `permalink` come from the issue summary fields returned by `list_issues`.
- For multi-project reports, run the command once per project: `/sentry:report 7d production` then ask to repeat for a different project slug.
