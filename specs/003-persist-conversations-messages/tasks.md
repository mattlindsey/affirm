# Tasks: Persist Conversations and Messages

**Input**: Design documents from `/specs/003-persist-conversations-messages/`  
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Organization**: Tasks grouped by user story. Each story is independently testable after its phase is complete.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

## Path Conventions

- **Models**: `app/models/`
- **Controllers**: `app/controllers/`
- **Views**: `app/views/`
- **Services**: `app/services/conversations/`
- **Policies**: `app/policies/`
- **Stimulus**: `app/javascript/controllers/`
- **Migrations**: `db/migrate/`
- **Config**: `config/routes.rb`
- **Model specs**: `spec/models/`
- **Policy specs**: `spec/policies/`
- **Service specs**: `spec/services/conversations/`
- **Request specs**: `spec/requests/`
- **System specs**: `spec/system/`
- **Factories**: `spec/factories/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Gem, routes, and Pundit wiring that must exist before any story work.

- [x] T001 Add `gem "pundit"` to `Gemfile` and run `mise exec ruby@4.0.2 -- bundle install`
- [x] T002 Add `resources :conversations, only: [:index, :show, :create] { resources :messages, only: [:create] }` to `config/routes.rb` and remove `post "chat" => "chats#create"`
- [x] T003 Add `include Pundit::Authorization` and `rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized` (rendering 404) to `app/controllers/application_controller.rb`
- [x] T004 [P] Create `ApplicationPolicy` base class with all actions defaulting to `false` in `app/policies/application_policy.rb`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database schema, core models, policy, and factories required by all user stories.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T005 Create `CreateConversations` migration with `t.references :user, null: false, foreign_key: { on_delete: :cascade }` and composite index on `[:user_id, :updated_at]` in `db/migrate/YYYYMMDDHHMMSS_create_conversations.rb`
- [x] T006 Create `CreateMessages` migration with `t.references :conversation, null: false, foreign_key: { on_delete: :cascade }`, `t.string :role, null: false`, `t.text :content, null: false`, and index on `conversation_id` in `db/migrate/YYYYMMDDHHMMSS_create_messages.rb`
- [x] T007 Run `mise exec ruby@4.0.2 -- bin/rails db:migrate` to apply both migrations
- [x] T008 Create `Conversation` model with `belongs_to :user`, `has_many :messages, dependent: :destroy`, `scope :recent`, `CONTEXT_MESSAGE_LIMIT = 50` constant, and `messages_for_llm` method returning `messages.order(created_at: :asc).last(CONTEXT_MESSAGE_LIMIT)` in `app/models/conversation.rb`
- [x] T009 [P] Create `Message` model with `belongs_to :conversation, touch: true`, `ROLES = %w[user assistant].freeze`, `validates :role, presence: true, inclusion: { in: ROLES }`, and `validates :content, presence: true, length: { maximum: 10_000 }` in `app/models/message.rb`
- [x] T010 Add `has_many :conversations, dependent: :destroy` to `app/models/user.rb`
- [x] T011 [P] Create `ConversationPolicy` with `show?`, `create?`, `index?` methods (allow only when `record.user == user`) and a `Scope` class filtering to `scope.where(user:)` in `app/policies/conversation_policy.rb`
- [x] T012 [P] Create FactoryBot factory for `Conversation` with `association :user` in `spec/factories/conversations.rb`
- [x] T013 [P] Create FactoryBot factory for `Message` with `association :conversation`, `role "user"`, and `sequence(:content)` in `spec/factories/messages.rb`
- [x] T014 [P] Write `Conversation` model spec covering: `belongs_to :user`, `has_many :messages`, `validates :user presence`, `recent` scope ordering, `messages_for_llm` returns at most 50 messages in chronological order in `spec/models/conversation_spec.rb`
- [x] T015 [P] Write `Message` model spec covering: `belongs_to :conversation`, `validates :role inclusion`, `validates :content presence`, `validates :content length max 10_000`, `touch: true` bumps `conversation.updated_at` in `spec/models/message_spec.rb`
- [x] T016 [P] Write `ConversationPolicy` spec covering: `show?` true for owner / false for other user, `create?` true for any authenticated user, `Scope#resolve` returns only current user's conversations in `spec/policies/conversation_policy_spec.rb`

**Checkpoint**: Foundation ready — migrations applied, models and policy tested. All user story phases can begin.

---

## Phase 3: User Story 1 — Conversations Survive Page Reload (Priority: P1) 🎯 MVP

**Goal**: Every message sent and received is saved to the database. When the user returns to the chat (after reload, close/reopen, or returning later), all previous messages are displayed in order and the LLM receives them as context.

**Independent Test**: Open chat, send three messages, reload the page, confirm all three messages and assistant replies are visible and the LLM context includes the prior exchange.

### Implementation for User Story 1

- [x] T017 [US1] Create `Conversations::SendMessageService` with `.call(user:, message:, conversation: nil)` class method, `ActiveRecord::Base.transaction` wrapping conversation creation + user message save (FR-012), then LLM call via `Chat::ReplyService`, then assistant reply save on success, returning a `Result` struct with `success?`, `conversation`, `reply`, `error` in `app/services/conversations/send_message_service.rb`
- [x] T018 [US1] Write `Conversations::SendMessageService` specs covering: success path with new conversation (creates both records atomically), success path with existing conversation (adds message), LLM failure path (user message persisted, returns failure result), and `messages_for_llm` cap respected in `spec/services/conversations/send_message_service_spec.rb`
- [x] T019 [US1] Create `ConversationsController` with `index` (redirects to `current_user.conversations.recent.first` or renders index), `show` (loads `@conversation`, `@messages = @conversation.messages.chronological`, `@conversations = policy_scope(Conversation).recent`), and `create` (calls `SendMessageService` with `conversation: nil`, redirects to `show` on success) in `app/controllers/conversations_controller.rb`
- [x] T020 [US1] Create `MessagesController` with `create` action (loads `@conversation = current_user.conversations.find(params[:conversation_id])`, calls `SendMessageService` with existing conversation, responds with `turbo_stream` on success or renders error stream on failure) in `app/controllers/messages_controller.rb`
- [x] T021 [P] [US1] Create `conversations/show.html.erb` with: `<div id="messages">` Turbo target containing a `render @messages` collection, a message input form pointing to `conversation_messages_path(@conversation)` with `data-controller="conversation"`, and a send button with `data-conversation-target="sendBtn"` in `app/views/conversations/show.html.erb`
- [x] T022 [P] [US1] Create `conversations/index.html.erb` rendering a "Start your first conversation" prompt with a message input form pointing to `conversations_path` in `app/views/conversations/index.html.erb`
- [x] T023 [P] [US1] Create `conversations/_message.html.erb` partial rendering a single message bubble with role-based CSS class (`user` vs `assistant`) and `dom_id(message)` for Turbo targeting in `app/views/conversations/_message.html.erb`
- [x] T024 [P] [US1] Create `messages/create.turbo_stream.erb` with two stream actions: `turbo_stream.append "messages", partial: "conversations/message", locals: { message: @user_message }` and `turbo_stream.append "messages", partial: "conversations/message", locals: { message: @assistant_message }` in `app/views/messages/create.turbo_stream.erb`
- [x] T025 [P] [US1] Create `conversation_controller.js` Stimulus controller with `sendBtnTarget` and `inputTarget` that disables both and shows a "…" typing indicator on form submit, re-enables on Turbo Stream response (via `turbo:submit-end` event) in `app/javascript/controllers/conversation_controller.js`
- [x] T026 [US1] Write `ConversationsController` request specs covering: unauthenticated redirect, `show` loads correct conversation and messages, `show` returns 404 for other user's conversation, `index` redirects to most recent conversation in `spec/requests/conversations_spec.rb`
- [x] T027 [US1] Write `MessagesController` request specs covering: unauthenticated redirect, successful message creates both message records and returns Turbo Stream, LLM failure returns error Turbo Stream, unauthorized conversation_id returns 404 in `spec/requests/messages_spec.rb`
- [x] T028 [US1] Update `app/views/home/index.html.erb` to replace the chat popup button (`data-action="click->chat-popup#open"`) with `<%= link_to "Chat with wellness coach", conversations_path %>`
- [x] T029 [US1] Remove `app/controllers/chats_controller.rb` and `app/javascript/controllers/chat_popup_controller.js`; delete corresponding spec `spec/requests/chats_spec.rb`
- [x] T030 [US1] Write system spec for US1: sign in, open chat, send three messages, reload page, verify all six messages (3 user + 3 assistant) are visible in `spec/system/chat_spec.rb`

**Checkpoint**: US1 complete — messages persist across reload, LLM uses DB history, home page links to chat. Fully testable independently.

---

## Phase 4: User Story 2 — View and Resume Past Conversations (Priority: P2)

**Goal**: Users can view a sidebar listing all past conversations (ordered most recent first, labeled by date/time) and navigate to any one to read and continue it.

**Independent Test**: Create two conversations on different days, navigate to the sidebar, click the first conversation, verify its messages load fully.

### Implementation for User Story 2

- [x] T031 [US2] Update `conversations/show.html.erb` to add a conversation history sidebar: a `<nav>` listing `@conversations` as links with `link_to conversation.created_at.strftime(...)` and `conversation_path(conversation)`, with the current conversation highlighted in `app/views/conversations/show.html.erb`
- [x] T032 [US2] Extend `ConversationsController` request specs: `show` response includes all of the current user's conversations in the `@conversations` assign (for sidebar), `index` with no conversations renders blank state in `spec/requests/conversations_spec.rb`
- [x] T033 [US2] Write system spec for US2: create two conversations, visit sidebar, click first conversation, verify its messages are shown; verify empty state message when no conversations exist in `spec/system/chat_spec.rb`

**Checkpoint**: US1 + US2 both complete — history sidebar functional, past conversations navigable.

---

## Phase 5: User Story 3 — Start a New Conversation (Priority: P3)

**Goal**: Users can start a fresh, empty coaching session at any time. The new conversation is saved as a distinct entry in the history list.

**Independent Test**: While viewing an existing conversation, click "New Conversation", send a message, navigate to history list, confirm it appears as a separate entry.

### Implementation for User Story 3

- [x] T034 [US3] Add a "New Conversation" link (`link_to "New Conversation", conversations_path`) to the sidebar in `app/views/conversations/show.html.erb`; clicking it navigates to `conversations#index` which shows the blank-state input form for a new first message
- [x] T035 [US3] Extend `ConversationsController` request specs for `create`: creates conversation and first message atomically, redirects to new `conversation_path`, second `create` request produces a separate conversation record in `spec/requests/conversations_spec.rb`
- [x] T036 [US3] Write system spec for US3: while viewing conversation A, click "New Conversation", send a message, navigate to history list, verify both conversations appear as distinct entries in `spec/system/chat_spec.rb`

**Checkpoint**: All three user stories complete and independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Quality gates across all stories.

- [x] T037 [P] Run `mise exec ruby@4.0.2 -- bundle exec rubocop -a` on all new and modified files and fix any remaining violations
- [x] T038 [P] Run `mise exec ruby@4.0.2 -- bin/brakeman --no-pager` and address any security findings (especially mass-assignment or missing authorization)
- [x] T039 Run full RSpec suite `mise exec ruby@4.0.2 -- bundle exec rspec` and resolve any failures
- [x] T040 Manual end-to-end validation: start server (`bin/dev`), open chat, send messages, reload page, navigate history, start new conversation — verify all three user stories work

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (routes must exist, Pundit must be included) — **BLOCKS all user stories**
- **US1 (Phase 3)**: Depends on Phase 2 — no dependency on US2 or US3
- **US2 (Phase 4)**: Depends on Phase 2 — no dependency on US1 (can be developed in parallel with US1 if staffed)
- **US3 (Phase 5)**: Depends on Phase 2 — but in practice requires the chat view from US1 and sidebar from US2
- **Polish (Phase 6)**: Depends on all desired stories complete

### User Story Dependencies

| Story | Can Start After | Blocks |
| ----- | --------------- | ------ |
| US1 (P1) | Foundational complete | Nothing — delivers standalone value |
| US2 (P2) | Foundational complete | Nothing — delivers standalone value |
| US3 (P3) | Foundational + US1 view exists | Nothing |

### Within Each User Story

1. Service → service specs
2. Controller (depends on service)
3. Views (parallel with controller)
4. Request specs (depends on controller)
5. System spec (depends on views + controller)

---

## Parallel Example: User Story 1

```bash
# Run in parallel (different files, no dependencies between them):
T017: Create Conversations::SendMessageService
T021: Create conversations/show.html.erb
T022: Create conversations/index.html.erb
T023: Create conversations/_message.html.erb
T025: Create conversation_controller.js

# Then (depends on service existing):
T019: Create ConversationsController
T020: Create MessagesController

# Then in parallel (depends on controller + views):
T024: Create messages/create.turbo_stream.erb
T026: Write ConversationsController request specs
T027: Write MessagesController request specs

# Then (depends on controller + views complete):
T030: Write system spec for US1
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T004)
2. Complete Phase 2: Foundational (T005–T016) ← **critical gate**
3. Complete Phase 3: User Story 1 (T017–T030)
4. **STOP and VALIDATE**: Send message, reload page, verify persistence
5. Deploy/demo as MVP

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. US1 → chat persists → **deploy MVP**
3. US2 → history sidebar → deploy
4. US3 → new conversation button → deploy
5. Polish → CI clean

---

## Notes

- All `bin/rails` and `bundle exec` commands must be prefixed with `mise exec ruby@4.0.2 --`
- [P] tasks touch different files — safe to run in parallel
- Each story phase should pass `bundle exec rspec` for its own spec files before proceeding
- `ChatsController` and `chat_popup_controller.js` are deleted in Phase 3 (T029) — their specs go too
- The `CONTEXT_MESSAGE_LIMIT = 50` constant lives in `Conversation` model, used by `messages_for_llm`
- `ConversationsController#create` and `MessagesController#create` both call `SendMessageService` — the difference is `conversation: nil` (new) vs `conversation: @conversation` (existing)
