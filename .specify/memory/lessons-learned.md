# Lessons Learned

**Purpose**: Cross-feature learnings that accumulate over time and feed forward into future planning and implementation.
**Last Updated**: 2026-06-10

<!--
  USAGE INSTRUCTIONS (for AI agents):

  When READING this file:
  - Filter entries by phase tag if you only need lessons relevant to your current phase
  - Prioritize entries tagged [phase:all] as they apply universally
  - Check the category tag to find entries relevant to your current concern
  - Most recent entries appear at the bottom of each section

  When WRITING to this file:
  - Append new entries to the appropriate section below
  - Always include: date, feature reference, phase tag, category tag
  - Keep entries concise (2-4 lines max)
  - Focus on actionable insight, not narrative
  - Update the "Last Updated" date above

  Entry format:
  - **[YYYY-MM-DD] [feature-branch-name]** `[phase:X]` `[category:Y]` —
    Brief description of the lesson. What happened, what was learned, what to do differently.

  Phase tags: specify, plan, implement, all
  Category tags: error-recovery, pattern, tooling, architecture, testing, performance, dependency, process

  ARCHIVAL: When this file exceeds 50 entries, move all but the 20 most recent
  entries to .specify/memory/lessons-learned-archive.md, preserving section structure.
-->

## Architecture & Design

<!-- Lessons about system design, patterns chosen, structural decisions -->

## Testing & Quality

<!-- Lessons about testing strategies, coverage gaps, quality processes -->

- **[2026-06-10] [003-persist-conversations-messages]** `[phase:implement]` `[category:testing]` —
  `current_path` in Capybara system specs is immediate (no retry). After any Turbo Drive navigation use `expect(page).to have_current_path(...)` which retries like all Capybara matchers. Using `current_path` directly races against the navigation completing.

- **[2026-06-10] [003-persist-conversations-messages]** `[phase:implement]` `[category:testing]` —
  `allow(...).to receive(:call).and_return(SomeResult.new(record: create(:model)))` evaluates the `create` immediately during stub setup, not at call time. Breaks `change { count }.by(1)` assertions. Fix: stub a lower-level dependency (e.g. stub the LLM, not the orchestrating service) or use `.and_return { ... }` (block form for lazy evaluation).

- **[2026-06-10] [003-persist-conversations-messages]** `[phase:implement]` `[category:testing]` —
  RSpec `allow` stubs don't cross Puma thread boundaries in Selenium system specs. Method stubs are visible only in the thread that sets them. For external API calls in system specs: stub at the HTTP level with WebMock (not yet in project Gemfile) or pre-seed DB state and skip the live submission path entirely.

## Dependencies & Tooling

<!-- Lessons about gems, libraries, build tools, environment issues -->

## Process & Workflow

<!-- Lessons about the SDD pipeline itself, command usage, workflow improvements -->

## Error Patterns

<!-- Recurring error types, common failure modes, debugging strategies -->

- **[2026-06-10] [003-persist-conversations-messages]** `[phase:implement]` `[category:error-recovery]` —
  Never disable a form input in a Stimulus `submit` action handler. Turbo captures the event but re-registers its FormData-reading listener in the bubble phase, after Stimulus's element-level listener fires. Disabling an input removes it from `FormData`, silently dropping the field. Fix: only disable the submit button; leave the input enabled so its value is included.
