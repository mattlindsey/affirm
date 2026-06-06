# Tasks: OpenAI API Key Settings

**Feature**: OpenAI API Key Settings
**Spec**: [spec.md](spec.md)
**Generated**: 2026-06-06
**Total tasks**: 16

---

## Dependency Order

```text
Phase 1 (Setup) → Phase 2 (Foundational) → Phase 3 (US-1/2/3) → Phase 4 (US-4) → Phase 5 (FR-005) → Polish
```

Phase 3, 4, and 5 can begin once Phase 2 migration is applied. Phase 3 and 4 are independent of each other and of Phase 5.

---

## Phase 1: Setup

- [x] T001 Add `delete "settings/api_key"` route and remove the stale `get "settings/index"` and `get "settings/update"` entries in `config/routes.rb`

---

## Phase 2: Foundational — Schema & Model

- [x] T002 Create migration `AddOpenaiApiKeyToSettings` adding a nullable `openai_api_key` string column to the `settings` table in `db/migrate/`
- [x] T003 Run `bin/rails db:migrate` to apply the migration
- [x] T004 [P] Add `openai_api_key_present?` predicate to `app/models/setting.rb` (returns true when `openai_api_key` is non-blank)
- [x] T005 [P] Create settings factory at `spec/factories/settings.rb` with `openai_api_key nil` default and an `:with_openai_key` trait

---

## Phase 3: US-1/US-2/US-3 — Store and Display API Key

_Goal: Users can enter, save, and see a masked confirmation of their API key on the Settings page. Blank submission preserves an existing key._

**Independent test criteria**: POST /settings with a key value persists it; POST with blank value does not overwrite; Settings page shows masked indicator when key exists and never renders the raw key value.

- [x] T006 [US1] Update `SettingsController#update` to permit `openai_api_key` and skip updating it when the submitted value is blank in `app/controllers/settings_controller.rb`
- [x] T007 [US1] Add password input for `openai_api_key` and a masked indicator (shown only when `@setting.openai_api_key_present?`) to `app/views/settings/index.html.erb`
- [x] T008 [US1] Extend `spec/requests/settings_spec.rb` with tests for: saving a key, blank no-op, masked display present/absent based on key existence

---

## Phase 4: US-4 — Remove API Key

_Goal: Users can explicitly remove their saved key via a confirmed delete action. The action is hidden when no key exists._

**Independent test criteria**: DELETE /settings/api_key clears the key; the "Remove API Key" button is absent when no key is saved; the action is a no-op if called with no key present.

- [x] T009 [US4] Add `destroy_api_key` action to `SettingsController` that clears `openai_api_key` and redirects with a flash notice in `app/controllers/settings_controller.rb`
- [x] T010 [US4] Add "Remove API Key" delete button — visible only when `@setting.openai_api_key_present?`, with `data-turbo-confirm` for browser confirmation — to `app/views/settings/index.html.erb`
- [x] T011 [US4] Add removal tests to `spec/requests/settings_spec.rb`: DELETE clears the key, button absent without a key, redirects with notice

---

## Phase 5: FR-005 — Runtime Key Resolution

_Goal: When an authenticated user has a saved API key, AI features use it instead of the server environment variable._

**Independent test criteria**: `Chat::ReplyService` uses a provided key when given one; `ChatsController` passes the current user's stored key (if present) to the service.

- [x] T012 [P] Update `Chat::ReplyService` to accept an optional `api_key:` keyword argument and pass it to `RubyLLM.chat(...)` (falling back to the global config when nil) in `app/services/chat/reply_service.rb`
- [x] T013 [P] Update `ChatsController#create` to resolve the current user's `openai_api_key` from their Setting and pass it to `Chat::ReplyService.call` in `app/controllers/chats_controller.rb`

---

## Polish

- [x] T014 Run `bundle exec rubocop -a` and fix any remaining violations across changed files
- [x] T015 Run `bin/brakeman --no-pager` and resolve any new findings
- [x] T016 Run full `bundle exec rspec` suite and confirm green

---

## Summary

| Phase       | Tasks     | User Stories      |
| ----------- | --------- | ----------------- |
| Setup       | T001      | —                 |
| Foundational| T002–T005 | —                 |
| Phase 3     | T006–T008 | US-1, US-2, US-3  |
| Phase 4     | T009–T011 | US-4              |
| Phase 5     | T012–T013 | FR-005            |
| Polish      | T014–T016 | —                 |

**MVP scope**: Phase 1 + Phase 2 + Phase 3 (T001–T008) — users can enter and see their key. Phase 4 and 5 add removal and runtime override.

**Parallelizable tasks**: T004 & T005 (after T003); T012 & T013 (independent of Phases 3/4).
