# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/sdd:plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

**Language/Version**: Ruby 4.0, Rails 8.1
**Primary Dependencies**: Hotwire (Turbo + Stimulus), ImportMap, Propshaft, SQLite3
**Storage**: SQLite3 (primary, cache via Solid Cache, queue via Solid Queue, cable via Solid Cable)
**Testing**: RSpec, FactoryBot, Shoulda Matchers, Capybara (system specs)
**Target Platform**: Web application, single server (Kamal/Docker deployment)
**Project Type**: Web application
**Performance Goals**: [feature-specific, e.g., page loads <1s, form submission <X seconds or NEEDS CLARIFICATION]
**Constraints**: [feature-specific, e.g., concurrent-request safety, booking horizon or NEEDS CLARIFICATION]
**Scale/Scope**: [feature-specific, e.g., single tenant, expected traffic level or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

[Gates determined based on constitution file]

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/sdd:plan command output)
├── research.md          # Phase 0 output (/sdd:plan command)
├── data-model.md        # Phase 1 output (/sdd:plan command)
├── quickstart.md        # Phase 1 output (/sdd:plan command)
├── contracts/           # Phase 1 output (/sdd:plan command)
└── tasks.md             # Phase 2 output (/sdd:tasks command - NOT created by /sdd:plan)
```

### Source Code (repository root)

```text
app/
├── models/          # ActiveRecord models, validations, scopes
├── controllers/     # Request handling, orchestration only
├── views/           # ERB templates, Turbo Frame/Stream responses
├── services/        # Business logic (side effects, multi-model operations)
├── mailers/         # Email delivery
├── jobs/            # Solid Queue background jobs
├── channels/        # Action Cable / Solid Cable channels
├── helpers/         # View helpers
└── javascript/
    └── controllers/ # Stimulus controllers (via ImportMap)

config/
├── initializers/    # App-wide constants and configuration
├── routes.rb        # RESTful routing (resources, namespaces)
└── locales/         # I18n translation files

db/
└── migrate/         # ActiveRecord migrations (reversible, no mixed DDL+data)

test/
├── models/          # Model unit tests
├── controllers/     # Controller integration tests
├── services/        # Service unit tests
├── system/          # Capybara browser tests
├── integration/     # Multi-controller flow tests
└── fixtures/        # Test data fixtures
```

**Structure Decision**: Standard Rails MVC layout. [Document namespace strategy
(e.g., Admin:: for staff routes) and any non-standard directories added.]

## Hotwire Decision Matrix

| User Interaction | Technique | Rationale |
|-----------------|-----------|-----------|
| [e.g., Page navigation] | Turbo Drive | [Full page replacement, no custom JS needed] |
| [e.g., Inline edit form] | Turbo Frame | [Lazy-loaded partial update within a frame] |
| [e.g., Real-time list update] | Turbo Stream | [Server-pushed append/replace/remove] |
| [e.g., Date picker validation] | Stimulus | [Client-side behavior on a specific element] |

<!--
  Fill one row per distinct UI interaction in the feature.
  Default to Turbo Drive unless a specific interaction needs frames, streams, or JS.
  Rationale column prevents over-engineering with Stimulus where Turbo suffices.
-->

## Migration Safety

- [ ] All migrations are reversible (use `change` method or paired `up`/`down`)
- [ ] No mixed DDL and data manipulation in the same migration
- [ ] Large-table indexes use `disable_ddl_transaction!` + `algorithm: :concurrently` (PostgreSQL) or are verified safe for SQLite3
- [ ] Foreign key constraints include appropriate `on_delete` behavior
- [ ] Migration order matches model dependency graph

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
