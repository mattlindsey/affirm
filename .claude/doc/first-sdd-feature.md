# Your First SDD Feature

A practical walkthrough for developers new to Spec Driven Development.

---

## What is SDD?

Spec Driven Development is a structured approach where you **specify what you're building before you build it**. An AI assistant (Claude Code) helps you at every step -- from writing the spec to generating tasks to validating the final implementation.

The core idea: think first, build second, verify at the end.

---

## The Two Paths

Not every change needs the full ceremony. SDD offers two paths depending on scope:

| Path | When to Use | Steps | Time |
|------|-------------|-------|------|
| **Lightweight** (`sdd-change`) | Bug fixes, small features, < 3 files | specify, tasks, implement | ~15 min setup |
| **Full SDD** (`sdd`) | New features, cross-cutting changes, multi-model work | specify, clarify, plan, tasks, implement, validate | ~45-90 min setup |

**Rule of thumb:** If you can describe the change in one sentence and know exactly which files to touch, use `sdd-change`. Otherwise, use the full path.

This walkthrough covers the **full SDD path**. The lightweight path is a subset -- just skip the steps marked **(full only)**.

---

## Prerequisites

Before you start, make sure you have:

- Claude Code CLI installed and configured
- The project repository cloned with the `.specify/` and `.claude/commands/sdd/` directories present
- A clean working tree on `main` (or your team's base branch)

Verify the SDD toolkit is available:

```bash
ls .specify/
# Expected: memory/ init-options.json scripts/ templates/

ls .claude/commands/sdd/
# Expected: specify.md clarify.md plan.md tasks.md implement.md validate.md ...
```

---

## Step-by-Step Walkthrough

We'll build a real feature: **"Users can bookmark articles for later reading."**

### Step 1: Specify -- Describe What You're Building

```
/sdd:specify Users can bookmark articles and view their bookmarked articles list
```

**What happens:**
1. Claude generates a short branch name (e.g., `bookmark-articles`)
2. A numbered feature branch is created (e.g., `004-bookmark-articles`)
3. A `spec.md` file is written to `specs/004-bookmark-articles/`
4. A quality checklist is generated and validated

**What you get:**

```
specs/004-bookmark-articles/
  spec.md                         # Feature specification
  checklists/requirements.md      # Quality validation checklist
```

**Your role:** Review the spec. The AI makes reasonable defaults for things like error handling, performance targets, and authentication. Check that:
- The user stories match your understanding of the feature
- The functional requirements are complete
- The acceptance scenarios (Given/When/Then) cover the important flows
- Nothing critical is missing from edge cases

If something looks wrong, tell Claude directly: *"The spec should also cover removing a bookmark"* or *"Bookmarks should be private, not public."*

**Output example -- spec.md sections:**

```markdown
## User Scenarios & Testing

### US-1 [P1]: Bookmark an Article
As a logged-in user, I want to bookmark an article so I can find it later.

#### Acceptance Scenarios
- Given I am viewing an article, When I click "Bookmark", Then the article is saved to my bookmarks
- Given I have already bookmarked an article, When I click "Remove Bookmark", Then it is removed
...

## Requirements
- FR-001: Authenticated users can bookmark any published article
- FR-002: Users can view a list of their bookmarked articles
- FR-003: Users can remove a bookmark
...
```

---

### Step 2: Clarify -- Fill the Gaps (full only)

```
/sdd:clarify
```

**What happens:**
1. Claude scans the spec across 9 categories (functional scope, data model, UX flow, security, edge cases, etc.)
2. Up to 5 targeted questions are asked, **one at a time**
3. Each question comes with a recommended answer and options
4. Your answers are integrated directly into the spec

**Example interaction:**

```
Q1: Should bookmarks be ordered by date added or allow custom sorting?

Recommended: Option A - Ordered by most recently bookmarked (simplest,
matches user expectation for "saved for later" patterns)

| Option | Description                        |
|--------|------------------------------------|
| A      | Most recently bookmarked first     |
| B      | Alphabetical by article title      |
| C      | Custom drag-and-drop ordering      |
| Short  | Provide a different short answer   |

Your choice: _
```

You can reply with just `A`, `yes` (to accept the recommendation), or type a custom answer.

**Tips:**
- Accepting the recommendation is fine for most questions -- they're based on best practices
- You can say `done` at any time to stop early if the remaining questions aren't critical
- If you skip this step entirely, downstream rework risk increases

---

### Step 3: Plan -- Design the Technical Approach (full only)

```
/sdd:plan I am building with Ruby 3.3, Rails 8.1, PostgreSQL, Hotwire
```

**What happens:**
1. Claude reads your spec and the project constitution
2. A `plan.md` is generated with technical context, architecture decisions, and a Hotwire decision matrix
3. Supporting artifacts are created:
   - `data-model.md` -- entities, fields, relationships, migration plan
   - `contracts/routes.md` -- RESTful route definitions
   - `research.md` -- resolved technical unknowns (if any)

**What you get:**

```
specs/004-bookmark-articles/
  spec.md
  plan.md                         # Technical implementation plan
  data-model.md                   # Entity definitions and relationships
  contracts/
    routes.md                     # Route contracts
  research.md                     # Technical decisions (if needed)
  checklists/
    requirements.md
```

**Key section -- Hotwire Decision Matrix:**

```markdown
| Interaction              | Mechanism    | Rationale                          |
|--------------------------|--------------|------------------------------------|
| Bookmark/unbookmark      | Turbo Stream | Toggle button without full reload  |
| Bookmarks list page      | Turbo Drive  | Standard navigation                |
| Remove from list         | Turbo Stream | Remove row without page reload     |
```

**Your role:** Review the data model and routes. These drive everything downstream. Flag issues now -- it's much cheaper to fix a plan than to fix code.

---

### Step 4: Generate Tasks -- Break It Down

```
/sdd:tasks
```

**What happens:**
1. Claude reads plan.md and spec.md
2. A dependency-ordered `tasks.md` is generated with phases
3. Tasks are organized by user story priority (P1 first, then P2, P3)

**Task format:**

```markdown
## Phase 1: Setup
- [ ] [T001] [P1] Create bookmarks migration with user_id, article_id, timestamps `db/migrate/`
- [ ] [T002] [P1] Create Bookmark model with validations and associations `app/models/bookmark.rb`

## Phase 2: Foundational
- [ ] [T003] [P1] Add bookmark associations to User and Article models `app/models/`
- [ ] [T004] [P1] Create BookmarkPolicy with Pundit authorization `app/policies/bookmark_policy.rb`

## Phase 3: User Story P1 - Bookmark an Article
- [ ] [T005] [P1] [US-1] Create BookmarksController with create/destroy actions `app/controllers/`
- [ ] [T006] [P1] [US-1] Add bookmark toggle button component `app/components/`
- [ ] [T007] [P1] [US-1] Write request specs for bookmark create/destroy `spec/requests/`
...

## Final Phase: Polish
- [ ] [T015] Run rubocop -a and fix violations
- [ ] [T016] Run brakeman security scan
- [ ] [T017] Run full rspec suite and verify green
```

**Your role:** Scan the task list for anything missing or out of order. The tasks follow TDD (Red-Green-Refactor), so test tasks often come alongside implementation tasks.

---

### Step 5 (Optional): Analyze -- Check Consistency (full only)

```
/sdd:analyze
```

**What happens:**
- A read-only consistency check across spec.md, plan.md, and tasks.md
- Detects duplications, ambiguities, coverage gaps, and constitution violations
- Produces a findings report -- you decide what to fix

This step is optional but recommended for complex features or when different people wrote the spec vs. the plan.

---

### Step 6: Implement -- Build It

```
/sdd:implement
```

**What happens:**
1. Claude reads tasks.md and processes each task in order
2. For each task, a fresh subagent receives minimal context (constitution, plan summary, relevant spec section, task description)
3. After each task: `rubocop` and relevant `rspec` tests are run
4. After each phase: the full test suite runs
5. Failures are retried with context, and lessons are logged to `lessons-learned.md`

**What you see:**
- Progress updates as each task completes
- Test results after each phase
- Any errors or decisions that need your input

**Your role during implementation:**
- Watch for test failures -- Claude will attempt fixes, but persistent failures may need your judgment
- If Claude asks a question, answer it -- don't let it guess on ambiguous implementation details
- The Setup and Polish phases are handled directly; middle phases use subagents

**After implementation completes**, your feature branch has working code with passing tests.

---

### Step 7: Validate -- Verify Spec Alignment (full only)

```
/sdd:validate
```

**What happens:**
1. **Structural scan** -- checks that expected files exist based on Rails conventions
2. **Test coverage mapping** -- matches RSpec descriptions to spec requirements
3. **AI semantic analysis** -- searches code for requirement implementations
4. **Acceptance test generation** -- proposes additional tests if gaps found (requires your approval)

**Output -- Validation Report:**

```markdown
## Coverage Summary
- Total Requirements: 8
- Covered: 7 (87.5%)
- Not Covered: 1 (12.5%)

## Requirement Status
| ID     | Requirement                        | Status  | Evidence           |
|--------|------------------------------------|---------|--------------------|
| FR-001 | Users can bookmark articles        | Covered | BookmarksController#create |
| FR-002 | Users can view bookmark list       | Covered | BookmarksController#index  |
| FR-003 | Users can remove bookmarks         | Covered | BookmarksController#destroy |
| FR-004 | Bookmarks are user-scoped          | Covered | BookmarkPolicy::Scope      |
...

## Overall Assessment: PARTIAL (87.5% coverage)
```

**Your role:** Address any uncovered or broken requirements before merging. The report tells you exactly what's missing and where to look.

---

## The Lightweight Path: sdd-change

For bug fixes and small features, skip the full ceremony:

```bash
# 1. Specify the change
/sdd-change:specify Fix: clicking bookmark on draft articles returns 500 error

# 2. Generate tasks (3-8 flat tasks, no phases)
/sdd-change:tasks

# 3. Implement
/sdd-change:implement
```

The change spec is simpler -- just Problem, Proposed Change, Acceptance Criteria, and Files Affected. Tasks are a flat list executed top-to-bottom. No clarify, plan, analyze, or validate steps.

---

## Quick Reference Card

### Full SDD Pipeline

```
/sdd:specify <description>     Write the feature spec
        |
/sdd:clarify                   Fill gaps with Q&A (optional but recommended)
        |
/sdd:spec-review               Adversarial review (optional)
        |
/sdd:plan <tech stack>         Generate technical plan + artifacts
        |
/sdd:tasks                     Break plan into ordered tasks
        |
/sdd:analyze                   Cross-artifact consistency check (optional)
        |
/sdd:implement                 Execute all tasks with TDD
        |
/sdd:validate                  Verify implementation matches spec
```

### Lightweight Pipeline

```
/sdd-change:specify <description>     Write a change spec
        |
/sdd-change:tasks                     Generate 3-8 flat tasks
        |
/sdd-change:implement                 Execute tasks sequentially
```

### Other Useful Commands

| Command | Purpose |
|---------|---------|
| `/sdd:checklist` | Generate custom quality checklists for specific domains (security, UX, etc.) |
| `/sdd:constitution` | Create or update the project's architectural principles |
| `/sdd:spec-review` | Adversarial review from security, performance, and edge-case perspectives |

---

## Common Questions

### "Do I have to use every step?"

No. The minimum viable path is **specify, tasks, implement**. The other steps (clarify, plan, analyze, validate) add rigor for complex features but can be skipped for straightforward work.

### "Can I edit the generated files manually?"

Yes. The spec, plan, and tasks files are plain Markdown. Edit them freely. The AI will read whatever is in the file when you run the next command.

### "What if I disagree with the AI's spec?"

Tell it directly. Say *"Update the spec: bookmarks should support tags"* or edit the file yourself and move to the next step.

### "What if implementation fails or tests don't pass?"

Claude retries with context and logs the issue to `lessons-learned.md`. If it can't resolve the failure, it will ask for your input. You can also fix the code manually and re-run `/sdd:implement` to continue from where it left off.

### "Where do all the artifacts live?"

Everything lives under `specs/<branch-name>/`:

```
specs/004-bookmark-articles/
  spec.md                    # Feature specification
  plan.md                    # Technical plan
  data-model.md              # Entity definitions
  research.md                # Technical decisions
  tasks.md                   # Implementation task list
  contracts/
    routes.md                # Route definitions
  checklists/
    requirements.md          # Spec quality checklist
  validation-report.md       # Post-implementation verification
```

### "What's the constitution?"

A shared document (`.specify/memory/constitution.md`) that defines architectural principles for the project. The plan phase checks your design against it. Think of it as guardrails that prevent architectural drift across the team. Create or update it with `/sdd:constitution`.

### "What happens to lessons learned?"

They accumulate in `.specify/memory/lessons-learned.md` with date, feature, phase, and category tags. Future features automatically reference relevant past lessons during planning -- so the team gets smarter over time.

---

## Tips for Success

1. **Invest time in the spec.** A good spec saves hours of rework. A bad spec generates bad code faster.
2. **Don't skip clarify for complex features.** Five questions now prevent five rounds of code review later.
3. **Review the data model before tasks.** Schema changes are the hardest to fix downstream.
4. **Use sdd-change for small stuff.** The full pipeline for a one-line bug fix is overkill.
5. **Edit the artifacts.** They're your documents, not the AI's. If something is wrong, fix it.
6. **Read the validation report.** It tells you exactly what's missing before your teammates do in code review.