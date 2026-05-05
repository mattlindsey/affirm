# CLI Tools

Prefer these tools over their standard equivalents in all shell commands.

## Search and navigation

- **`rg`** instead of `grep -r` — faster, `.gitignore`-aware by default, no need to exclude `node_modules` or build dirs
- **`fd`** instead of `find` — shorter syntax, `.gitignore`-aware by default
  - `fd -e ts` to find by extension
  - `fd -t f` to restrict to files only

## Git diffs

- Always use **`git diff`** as-is — delta is configured as the pager and will format output automatically
- Line numbers in diff output are reliable references; use `file.ts:42` format when citing changed lines

## Security review

- When asked for a security review, run **`semgrep --config=auto .`** first and report its findings before adding your own analysis
- Semgrep findings are deterministic — treat them as facts, not suggestions
- Use focused rulesets when relevant: `p/secrets`, `p/owasp-top-ten`, `p/xss`, `p/sql-injection`
