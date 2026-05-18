---
name: catchup
description: Summarize what happened on the current branch since the developer's last contribution (commits, authors, stats, key changes).
argument-hint: "[developer email or name — optional, defaults to local git user]"
---

# Catchup: Branch Activity Since Last Contribution

Produce a focused "welcome back" report for a developer returning to a feature branch, so they can catch up on what others (or they themselves) changed while they were away.

## Input

`$ARGUMENTS` — optional identity of the returning developer:
- empty → use the local `git config user.email` (and `user.name`)
- an email → match commits by `author.email`
- a name (or fragment) → match commits by `author.name` (case-insensitive)

Examples:
- `/catchup` — catch up the current git user
- `/catchup alice@acme.com` — catch up Alice by email
- `/catchup "Alice Martin"` — catch up Alice by name

## Workflow

1. **Resolve context** — run, in parallel where possible:
   - `git rev-parse --abbrev-ref HEAD` → current branch (abort with a clear message if `HEAD` is detached or the branch is `main`/`master`).
   - `git config user.email` and `git config user.name` → default identity.
   - `git remote show origin | sed -n 's/.*HEAD branch: //p'` (fallback to `main`) → base branch.
   - `git fetch --quiet` if a remote exists, so comparisons use up-to-date refs. Skip silently on failure (offline).

2. **Resolve the developer**:
   - Use `$ARGUMENTS` if provided; otherwise the local git identity.
   - Detect whether the argument looks like an email (contains `@`) to choose `--author=<email>` vs `--author=<name>`.
   - Record the resolved display string for the report header.

3. **Find the developer's last commit on this branch** (merge-base scoped):
   ```
   git log <base>..HEAD --author="<dev>" -n 1 --format="%H %ci %s"
   ```
   - If a commit is found → use it as the **since** anchor (`<sha>..HEAD`).
   - If none → the dev has never committed on this branch. Use the branch divergence point as the anchor: `git merge-base <base> HEAD`. Flag this in the report as "first time on this branch".

4. **Gather activity between the anchor and `HEAD`** (read-only commands only):
   - Commits with authors and dates:
     `git log <anchor>..HEAD --format="%h|%an|%ae|%cr|%s" --no-merges`
   - Author breakdown:
     `git shortlog -sne <anchor>..HEAD --no-merges`
   - Diff stats (files + lines):
     `git diff --stat <anchor>..HEAD`
   - Machine-readable per-file churn (for top-changed files):
     `git diff --numstat <anchor>..HEAD`
   - High-signal diffs for the top 3–5 most-changed files:
     `git diff <anchor>..HEAD -- <path>` (truncate each to the first ~200 lines of diff in the report; link the rest by filename).
   - Merge commits summary (if any), only listed — not expanded:
     `git log <anchor>..HEAD --merges --format="%h %s"`

5. **Synthesize** — read the collected diffs and commit messages and group changes by **theme**, not just by file. Cluster into categories such as:
   - *Features added* — new behavior the dev should know about.
   - *Refactors* — structural changes to code they may have authored.
   - *Bug fixes* — short "what broke, what was fixed".
   - *Tests / tooling / CI* — note briefly.
   - *Risky / requires attention* — migrations, schema changes, config, dependency bumps, security-sensitive files (`config/`, `db/migrate/`, `Gemfile*`, `.env*.example`, `app/policies/`).

   Be specific: reference files and commit SHAs (`abc1234`) so the dev can jump in.

6. **Format the report** as markdown and output it directly:

   ```markdown
   ## Catchup — `<branch>` for <Dev Name>
   **Base:** `<base>` | **Since:** <anchor description> | **Generated:** <date>

   ### At a glance
   - **Commits:** N (from M authors)
   - **Files changed:** F  (+A / -D lines)
   - **Merge commits:** K
   - **Your last commit:** `<sha>` — "<subject>" (<relative time>)  *(or: "You haven't committed on this branch yet.")*

   ### Who changed what
   | Author | Commits | Lines (+/-) |
   |--------|---------|-------------|
   | ...    | ...     | ...         |

   ### Themes
   **Features**
   - <concise bullet> — `sha1234`, `sha5678` (`path/to/file.rb`)

   **Refactors**
   - ...

   **Bug fixes**
   - ...

   **Tests / tooling**
   - ...

   ### Requires your attention
   - <migration / config / dep bump / policy change> — `sha`, `path`

   ### Most-changed files
   | File | Commits | +/- |
   |------|---------|-----|
   | ...  | ...     | ... |

   ### Commit log
   - `sha` — *Author* — <relative time> — subject
   - ...
   ```

7. **Empty-state handling**:
   - No commits in range → output "You're up to date — nothing new on `<branch>` since `<anchor>`." and stop.
   - First time on branch → replace the "Your last commit" line accordingly and title the section "What's on this branch so far".

## Notes

- **Read-only**: never run `git fetch --all --prune`, `git pull`, `git checkout`, or anything that mutates local state. `git fetch --quiet` of the current remote is the only network call allowed.
- Prefer `git log --no-merges` for counts so merges don't inflate stats, but keep a separate merges list.
- Keep the full report under ~300 lines. Truncate long diffs and link file paths — the developer will open them in their editor.
- Identity matching is a best-effort: if the user has committed under multiple emails, suggest re-running with an explicit argument when the "last commit" lookup returns nothing but the author clearly has activity elsewhere.
- The report is designed to be pasted into Slack or a PR comment, so avoid ANSI colors and keep tables narrow.
