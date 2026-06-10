# Research: Persist Conversations and Messages

**Branch**: `003-persist-conversations-messages`  
**Date**: 2026-06-10  
**Phase**: 0 — Pre-design research

---

## Decision 1: Authorization Strategy (FR-011 / Constitution §V)

**Decision**: Add the `pundit` gem. Include `Pundit` in `ApplicationController`. Create `ApplicationPolicy` (default deny all). Create `ConversationPolicy` granting all actions only when `record.user == user` (ownership check). All conversation and message controller actions call `authorize`.

**Rationale**: Constitution §V mandates Pundit for all resource authorization. Direct scoping via `current_user.conversations.find` would satisfy security but violates the constitution's explicit requirement for named policy files with default-deny posture.

**Alternatives considered**:
- Inline scope (`current_user.conversations.find(params[:id])`) — rejected: constitution violation; also silently swallows authorization semantics with a 404 rather than an explicit policy decision.
- Skip authorization for now — rejected: constitution §V is non-negotiable.

---

## Decision 2: Chat UI Architecture — Popup vs. Dedicated Page

**Decision**: Evolve the chat from the home-page popup into dedicated `/conversations` pages (`index` + `show`). The existing `chat_popup_controller.js` is replaced by a new `conversation_controller.js` Stimulus controller. The home page popup becomes a link to `/conversations`.

**Rationale**: User Stories 2 and 3 require a navigable conversation history list and a "new conversation" action visible while viewing an existing conversation. These interactions don't fit naturally in a popup modal. A dedicated page is the clean Turbo-native solution.

**Alternatives considered**:
- Keep popup, add persistence — rejected: US-2 (history page) requires list navigation outside a 420px modal; US-3 requires side-by-side access to the conversation list.
- Popup with embedded conversation list — rejected: overly complex Stimulus controller managing both popup state and history navigation; violates KISS.

---

## Decision 3: LLM Context Message Limit (FR-004)

**Decision**: `Chat::CONTEXT_MESSAGE_LIMIT = 50`. The service passes `conversation.messages.order(created_at: :asc).last(50)` to the LLM on every request. All messages are stored; only the 50 most recent are included in the LLM context window.

**Rationale**: gpt-4o-mini supports 128k tokens. 50 messages × ~400 tokens average = ~20,000 tokens, leaving ample headroom. 50 messages represents ~25 user/assistant exchanges — sufficient context for any realistic CBT session. The constant is named so it can be tuned without a code search.

**Alternatives considered**:
- No limit (send full history) — rejected: review finding R-004; unbounded cost growth and eventual token-limit failures.
- Dynamic token counting — rejected: premature complexity; a fixed message count is simpler and sufficient.
- 20 messages — rejected: too short for a meaningful CBT session; context quality would degrade quickly.

---

## Decision 4: Message Sending — Turbo Stream vs. JSON Fetch

**Decision**: Replace the JSON fetch pattern in `ChatPopupController` with Turbo Stream responses. The message form submits via Turbo. `MessagesController#create` (and `ConversationsController#create`) respond with a `turbo_stream` template that appends the user message and assistant reply to the message list. A `conversation_controller.js` Stimulus controller handles the loading/disabled state during the in-flight request.

**Rationale**: Consistent with the project's Hotwire-native architecture (Constitution §VI). Eliminates custom JavaScript DOM manipulation and in-memory history tracking. The LLM call is synchronous — the Turbo response naturally delivers both messages when the request completes.

**Alternatives considered**:
- Keep JSON fetch + Stimulus DOM manipulation — rejected: maintains the non-Turbo pattern that caused the history-loss problem in the first place; duplicates what Turbo Streams already do natively.
- Async with Action Cable (Turbo Streams over WebSocket) — rejected: YAGNI; synchronous response is sufficient and much simpler for a single-user, low-frequency chat.

---

## Decision 5: Service Layer Design (FR-001, FR-012)

**Decision**: Single `Conversations::SendMessageService` handles both the "first message creates conversation" and "subsequent message adds to existing conversation" cases.

Internal flow:
1. `ActiveRecord::Base.transaction` wraps: create conversation if `conversation` is nil + create user message → satisfies FR-012 (atomic).
2. Transaction commits. User message is now persisted.
3. Fetch `CONTEXT_MESSAGE_LIMIT` most recent messages from conversation for LLM history.
4. Call `Chat::ReplyService` with message + history.
5. If LLM succeeds → save assistant reply outside the transaction.
6. If LLM fails → user message remains; return failure result.

The existing `Chat::ReplyService` is kept intact for LLM interaction.

**Rationale**: One service, two paths, single responsibility. The transaction boundary precisely matches FR-012 (atomicity for conversation + first message) without wrapping the LLM call (which would violate FR-001's "save user message immediately" requirement).

**Alternatives considered**:
- Two separate services (`CreateConversationService`, `AddMessageService`) — rejected: over-engineered for what is fundamentally one user action.
- Wrapping LLM call in transaction — rejected: violates FR-001; if LLM fails, user message would be rolled back contrary to the spec.

---

## Decision 6: Message Content Validation

**Decision**: `validates :content, length: { maximum: 10_000 }` on the `Message` model. No minimum length (empty messages blocked by `validates :content, presence: true`).

**Rationale**: 10,000 characters is generous for any real coaching message. It prevents abuse and unbounded storage while never constraining legitimate use. Maps cleanly to a user-visible error.

**Alternatives considered**:
- No max — rejected: review finding R-007; required by spec for completeness.
- 4,000 characters — rejected: too restrictive for users who paste journal entries.

---

## Decision 7: `conversation.updated_at` as "Most Recently Used" Signal (FR-003)

**Decision**: `Message` uses `belongs_to :conversation, touch: true`. Every time a message is saved, `conversation.updated_at` is bumped automatically. `ConversationsController#index` redirects to `current_user.conversations.order(updated_at: :desc).first`.

**Rationale**: `touch: true` is the standard Rails idiom for propagating child updates to parent timestamps. No extra logic needed. The `updated_at` field precisely answers "which conversation was last used?"

**Alternatives considered**:
- Separate `last_message_at` column — rejected: YAGNI; `updated_at` already carries this semantics via `touch: true`.
