---

description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: The examples below include test tasks. Tests are OPTIONAL - only include them if explicitly requested in the feature specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Models**: `app/models/`
- **Controllers**: `app/controllers/` (namespaced: `app/controllers/admin/`)
- **Views**: `app/views/` (namespaced: `app/views/admin/`)
- **Services**: `app/services/`
- **Jobs**: `app/jobs/`
- **Mailers**: `app/mailers/`
- **Stimulus**: `app/javascript/controllers/`
- **Migrations**: `db/migrate/`
- **Config**: `config/initializers/`, `config/routes.rb`
- **Model specs**: `spec/models/`
- **Controller specs**: `spec/controllers/` (namespaced: `spec/controllers/admin/`)
- **Service specs**: `spec/services/`
- **System specs**: `spec/system/`
- **Request specs**: `spec/requests/`
- **Factories**: `spec/factories/`

<!-- 
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.
  
  The /sdd:tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Feature requirements from plan.md
  - Entities from data-model.md
  - Endpoints from contracts/
  
  Tasks MUST be organized by user story so each story can be:
  - Implemented independently
  - Tested independently
  - Delivered as an MVP increment
  
  DO NOT keep these sample tasks in the generated tasks.md file.
  ============================================================================
-->

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Configuration, routes, and initializers that must exist before any story work.

- [ ] T001 Create application config initializer with feature-specific constants in `config/initializers/[feature]_config.rb`
- [ ] T002 Add RESTful routes (resources/namespace) for the feature in `config/routes.rb`
- [ ] T003 [P] Add any required gems to `Gemfile` and run `bundle install`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database schema and core models required by all user stories.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T004 Generate migration with columns and indexes in `db/migrate/YYYYMMDDHHMMSS_create_[table].rb`
- [ ] T005 Run `bin/rails db:migrate` to apply the schema
- [ ] T006 Create [Entity] model with validations, enums, scopes, and normalization callbacks in `app/models/[entity].rb`
- [ ] T007 Write [Entity] model specs covering validations, scopes, and enums in `spec/models/[entity]_spec.rb`
- [ ] T008 [P] Create FactoryBot factory for [Entity] in `spec/factories/[entities].rb`

**Checkpoint**: Foundation ready — migration applied, model tested. User story phases can begin.

---

## Phase 3: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Implementation for User Story 1

- [ ] T009 [US1] Create [Service] with `call` method in `app/services/[service].rb`
- [ ] T010 [US1] Create [Controller] with actions in `app/controllers/[controller].rb`
- [ ] T011 [P] [US1] Create view templates in `app/views/[resource]/[action].html.erb`
- [ ] T012 [US1] Write [Service] specs in `spec/services/[service]_spec.rb`
- [ ] T013 [US1] Write [Controller] request specs in `spec/requests/[controller]_spec.rb`
- [ ] T014 [US1] Write system spec for happy-path user journey in `spec/system/[feature]_spec.rb`

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Implementation for User Story 2

- [ ] T015 [US2] Create [Service] in `app/services/[service].rb`
- [ ] T016 [US2] Create [Controller] with actions in `app/controllers/[controller].rb`
- [ ] T017 [P] [US2] Create view templates in `app/views/[resource]/[action].html.erb`
- [ ] T018 [US2] Write [Controller] request specs in `spec/requests/[controller]_spec.rb`

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Implementation for User Story 3

- [ ] T019 [US3] Update [Service] with additional logic in `app/services/[service].rb`
- [ ] T020 [US3] Update [Controller] to handle new scenarios in `app/controllers/[controller].rb`
- [ ] T021 [US3] Extend service specs in `spec/services/[service]_spec.rb`
- [ ] T022 [US3] Extend system specs in `spec/system/[feature]_spec.rb`

**Checkpoint**: All user stories independently functional.

---

[Add more user story phases as needed, following the same pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Quality gates and CI validation across all stories.

- [ ] TXXX [P] Run `bin/rubocop` and fix all linting violations across new files
- [ ] TXXX [P] Run `bin/brakeman --no-pager` security scan and address any findings
- [ ] TXXX Run full CI pipeline `bin/ci` and resolve any remaining failures
- [ ] TXXX Validate quickstart.md scenarios manually end-to-end
- [ ] TXXX [P] Documentation updates (if applicable)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable

### Within Each User Story

- Migration (if story adds schema) before model
- Model before service
- Service before controller
- Controller before views
- Implementation before tests (or TDD if spec requests it)
- System tests after controller + views are complete
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Run these in parallel (different files):
Task: "Create [Service] in app/services/[service].rb"
Task: "Create view template in app/views/[resource]/new.html.erb"
Task: "Create view template in app/views/[resource]/show.html.erb"

# Then sequentially (depends on service):
Task: "Create [Controller] in app/controllers/[controller].rb"

# Then specs (depends on controller + service):
Task: "Service specs in spec/services/[service]_spec.rb"
Task: "Request specs in spec/requests/[controller]_spec.rb"
Task: "System spec in spec/system/[feature]_spec.rb"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
