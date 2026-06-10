<!--
  SYNC IMPACT REPORT
  ==================
  Version change: (none) → 1.0.0 (initial creation)

  New sections:
  - Core Principles (I–VI): all new
  - Development Stack: new
  - Development Workflow: new
  - Governance: new

  Removed sections: N/A (initial creation)

  Modified principles: N/A (initial creation)

  Templates updated:
  ✅ .specify/templates/plan-template.md — Updated Technical Context block:
       Ruby 3.3.6 → Ruby 4.0; Minitest → RSpec, FactoryBot, Capybara
  ✅ .specify/templates/tasks-template.md — Updated Path Conventions:
       test/ paths (Minitest) → spec/ paths (RSpec)

  Follow-up TODOs:
  - None. No placeholders intentionally deferred.
-->

# Affirm Constitution

## Core Principles

### I. Rails Conventions First

Standard Rails idioms are the default. Conventional RESTful routing (`resources`, namespaces) and
standard CRUD controllers are preferred over custom abstractions. If a junior developer cannot
understand a piece of code in 30 seconds, it MUST be simplified.

- Controllers MUST be thin orchestrators: receive request, delegate to service, render response.
- Models MUST handle persistence only: validations, associations, scopes, and simple predicates.
- Views MUST contain ERB markup only — no logic beyond iteration and conditional rendering.
- Services MUST contain all business logic, side effects, API calls, and job enqueuing.

### II. Test-First Development (NON-NEGOTIABLE)

TDD is mandatory for all feature work. The Red-Green-Refactor cycle MUST be followed:

1. **RED**: Write a failing RSpec spec that describes the desired behavior.
2. **GREEN**: Write the minimal code to make the spec pass.
3. **REFACTOR**: Improve code structure while keeping all specs green.

No implementation code is merged without a corresponding spec. System specs with Capybara MUST
cover the primary user journey of every new feature.

### III. Explicit Over Implicit

Code MUST be explicit and readable. Hidden magic is a defect.

- Callbacks are permitted ONLY for data normalization (`before_validation`, `before_save`).
  Side effects — emails, background jobs, API calls, creating related records — MUST live in
  services, never in model callbacks.
- Services MUST expose a `.call` class method entry point and return a Result object.
- Services MUST be namespaced by domain: `Domain::ActionService`
  (e.g., `Affirmations::CreateService`).
- Named methods are preferred over metaprogramming. `define_method` requires explicit justification.

### IV. No Premature Abstraction (YAGNI)

Implement only what is currently required. Abstractions are a liability until proven necessary.

- Base classes, helpers, or utilities MUST NOT be created for a single use case.
  Extract only when 3+ concrete implementations share identical structure.
- Three similar lines of code are better than the wrong abstraction.
- Configuration options and feature flags for hypothetical future needs MUST NOT be added.
- Start simple; extract later when complexity demands it.

### V. Authorization by Default

Pundit policies govern all resource access. The default posture is deny.

- Every controller action accessing a resource MUST call `authorize`.
- Policy files MUST default all actions to `false`; permissions are explicitly granted.
- Scope restrictions MUST be applied via policy scopes in index actions.
- Brakeman security scan MUST pass before any PR is merged.

### VI. Hotwire-Native UI

The UI is built with Hotwire (Turbo + Stimulus) and Tailwind CSS 4. Node.js is not in the stack.

- Turbo Drive handles full-page navigation by default.
- Turbo Frames are used for partial page updates (inline edits, lazy-loaded sections).
- Turbo Streams are used for server-pushed real-time updates.
- Stimulus controllers handle client-side behavior scoped to a specific element.
- JavaScript written outside Stimulus MUST be justified in code review.
- React, Vue, webpack, or any external JS build tool is prohibited.
- ViewComponents are used for reusable UI elements; each component MUST have its own spec.

## Development Stack

**Language/Version**: Ruby 4.0, Rails 8.1
**Database**: SQLite3 (primary), Solid Cache (caching), Solid Queue (jobs), Solid Cable (WebSockets)
**Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS 4, ViewComponent
**Testing**: RSpec, FactoryBot, Shoulda Matchers, Capybara (system specs)
**Auth**: `has_secure_password` (authentication), Pundit (authorization)
**Assets**: Propshaft + Import Maps (no Node.js, no Webpack)
**Deployment**: Kamal 2 + Thruster

### Naming Conventions

| Layer | Pattern | Example |
|-------|---------|---------|
| Model | Singular PascalCase | `Affirmation`, `Mood` |
| Controller | Plural PascalCase | `AffirmationsController` |
| Service | Namespaced + `Service` | `Affirmations::CreateService` |
| Query | Namespaced + `Query` | `Affirmations::SearchQuery` |
| Policy | Singular + `Policy` | `AffirmationPolicy` |
| Job | Descriptive + `Job` | `SendDailyAffirmationJob` |
| Presenter | Singular + `Presenter` | `AffirmationPresenter` |
| Form | Descriptive + `Form` | `MoodCheckInForm` |

### Path Conventions (RSpec)

| Artifact | Path |
|----------|------|
| Model specs | `spec/models/` |
| Controller specs | `spec/controllers/` |
| Service specs | `spec/services/` |
| System specs | `spec/system/` |
| Factories | `spec/factories/` |
| Request specs | `spec/requests/` |

## Development Workflow

1. Feature work starts with a spec in `specs/[###-feature-name]/spec.md`.
2. Plan is designed using `/sdd:plan`, producing `plan.md`, `research.md`, `data-model.md`.
3. Tasks are generated with `/sdd:tasks`, producing `tasks.md`.
4. Implementation follows TDD: failing spec → minimal implementation → refactor.
5. All migrations MUST be reversible. Mixed DDL + data manipulation in one migration is prohibited.
6. Pull requests MUST pass: RSpec suite, RuboCop (`-a`), Brakeman, bundler-audit.
7. All Rails and Bundler commands MUST be prefixed with `mise exec ruby@4.0.2 --` locally.

## Governance

This constitution supersedes all other project practices. When a principle conflicts with convenience
or speed, the principle wins.

**Amendments MUST**:
1. Be documented with a rationale explaining why the existing principle was insufficient.
2. Receive project maintainer approval before merging.
3. Include a migration plan for any existing code that now violates the amended principle.
4. Increment the version according to semantic versioning:
   - MAJOR: Backward-incompatible removal or redefinition of a principle.
   - MINOR: New principle or section added, or materially expanded guidance.
   - PATCH: Clarifications, wording fixes, non-semantic refinements.

**Compliance review**: All PRs and code reviews MUST verify adherence to the principles above.
Constitution violations MUST be flagged and resolved before merge.

**Runtime guidance**: See `.claude/CLAUDE.md` for agent-specific development guidance and
`.specify/.specify/templates/` for SDD workflow templates.

**Version**: 1.0.0 | **Ratified**: 2026-06-10 | **Last Amended**: 2026-06-10
