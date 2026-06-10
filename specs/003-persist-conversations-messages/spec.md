# Feature Specification: Persist Conversations and Messages

**Feature Branch**: `003-persist-conversations-messages`  
**Created**: 2026-06-10  
**Status**: Draft  
**Input**: User description: "Add persistance of Conversations and Messages"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Conversations Survive Page Reload (Priority: P1)

When a user sends messages to the CBT wellness coach and then closes or refreshes the page, their conversation history is preserved. When they return to the chat, all previous messages are still visible, and they can continue the conversation without losing context.

**Why this priority**: Without persistence, all conversation history is lost on page reload. This is the core missing capability and the foundation every other story builds on.

**Independent Test**: Open a chat, send three messages, reload the page, and confirm all three messages and the assistant's replies are visible.

**Acceptance Scenarios**:

1. **Given** a user has an active chat conversation with at least one message exchange, **When** the user refreshes the page, **Then** all previous messages are displayed in the correct order with their original content.
2. **Given** a user has an active chat conversation, **When** the user closes the browser and returns later, **Then** the conversation is restored exactly as left.
3. **Given** a user sends a new message in a restored conversation, **When** the assistant replies, **Then** the full conversation history is used as context for the reply.
4. **Given** a user opens the chat for the first time with no prior conversations, **When** the page loads, **Then** a "Start your first conversation" prompt is shown and no conversation record exists until they send a message.

---

### User Story 2 - View and Resume Past Conversations (Priority: P2)

A user can see a list of all their past coaching conversations, navigate to any one of them, and pick up where they left off. Each conversation in the list is identified by the date and time it was started, so the user can locate sessions by when they occurred.

**Why this priority**: Once conversations are stored, users need a way to access and continue them. Without this, every new visit starts a fresh conversation even though history is saved.

**Independent Test**: Start two separate conversations on different days, navigate to the conversation history list, select the first conversation, and confirm its full message conversation is displayed.

**Acceptance Scenarios**:

1. **Given** a user has had multiple conversations, **When** they visit the conversation history page, **Then** they see a list of their conversations ordered from most recent to oldest.
2. **Given** a conversation list is displayed, **When** the user selects a past conversation, **Then** the full message conversation for that conversation is shown.
3. **Given** a user is viewing a past conversation, **When** they type and send a new message, **Then** the assistant responds with full prior conversation context and the new exchange is saved.
4. **Given** a user has no past conversations, **When** they visit the conversation history page, **Then** an appropriate empty-state message is shown.

---

### User Story 3 - Start a New Conversation (Priority: P3)

A user can explicitly start a fresh conversation with the wellness coach, separate from any previous one. New conversations are saved as independent conversations, keeping each coaching session distinct.

**Why this priority**: Once past conversations are accessible, users need a clear way to start a new topic without overwriting or contaminating an existing conversation conversation.

**Independent Test**: While viewing an existing conversation, click "New Conversation", send a message, and confirm it appears in the history list as a separate entry from the previous conversation.

**Acceptance Scenarios**:

1. **Given** a user is viewing any conversation, **When** they initiate a new conversation, **Then** a fresh, empty chat is started and saved as a new conversation.
2. **Given** a user starts a new conversation and sends messages, **When** they navigate to the history list, **Then** the new conversation appears as a distinct entry alongside previous ones.
3. **Given** a user starts a new conversation, **When** the assistant replies, **Then** the assistant has no memory of previous conversation conversations.

---

### Interaction Patterns

- **Chat view**: The user's most recently updated conversation is automatically loaded when they open the chat; new messages are appended live without a full-page reload.
- **Conversation list**: Displayed as a navigable list; selecting an item loads that conversation's conversation.
- **New conversation**: A button or link triggers a new conversation and redirects the user to the empty chat view.

### Edge Cases

- What happens if the same user has the chat open in two browser tabs simultaneously? Both tabs write to the same conversation; messages are saved and displayed in arrival order. No conflict resolution is required.
- What happens if a message fails to save (network error during submission)? The user should see an error and be able to retry. **Known limitation**: if the server saved the message but the client never received confirmation, a retry will create a duplicate message. This is accepted as a low-risk edge case for a personal wellness app with low message frequency; no idempotency key mechanism is required.
- What happens if a user attempts to access another user's conversation via a direct URL? The system must deny access and show a not-found or unauthorized response.
- What happens if the conversation history grows very long? All messages remain stored and visible in the chat view. However, only the most recent messages up to the defined limit are sent to the LLM as context; older messages are retained in the record but silently excluded from the LLM window. This is a known, accepted tradeoff — no error is shown to the user.
- What happens if the LLM returns an error? The user's message is already saved; the failed assistant reply is not recorded. The user sees a friendly error and can retry sending — on retry the assistant sees the saved user message as part of the history.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST save the user's message to the current conversation immediately upon submission, before requesting an assistant reply. The assistant reply is saved only if the LLM responds successfully.
- **FR-002**: System MUST associate every conversation with the authenticated user who started it; no conversation is accessible to any other user.
- **FR-003**: System MUST automatically load the user's most recently updated conversation (and its full message history) when they open the chat.
- **FR-004**: System MUST use saved conversation history — not browser-submitted history — as context when generating assistant replies. Only the most recent messages up to a defined limit are sent to the LLM; full history beyond that limit is retained in storage but not included in the LLM context window.
- **FR-005**: Users MUST be able to view a list of all their past conversations.
- **FR-006**: Users MUST be able to navigate to any past conversation and read its full message conversation.
- **FR-007**: Users MUST be able to send new messages within a past conversation, with the assistant replying in full context.
- **FR-008**: Users MUST be able to start a new conversation. A conversation record is only created when the user sends the first message — no empty conversation records are persisted.
- **FR-009**: System MUST preserve message order (chronological, oldest first) within any conversation.
- **FR-010**: System MUST record which participant (user or assistant) authored each message.
- **FR-011**: System MUST enforce access control on all conversation and message data via a dedicated authorization policy; all actions that read, create, or modify conversations or messages MUST verify the requesting user owns the resource. Unauthenticated or unauthorized requests MUST be denied.
- **FR-012**: Conversation creation and first message creation MUST be atomic — either both records are persisted together or neither is. A failed first message save MUST NOT leave an empty conversation record in the system.

### Key Entities

- **Conversation**: Represents a single coaching session. Belongs to one user. Has a creation timestamp and zero or more messages. Displayed to the user by its start date and time (no user-defined title).
- **Message**: A single turn within a conversation. Belongs to one conversation. Records the author role (user or assistant), the text content, and the time it was sent.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of messages sent and received during a conversation are retrievable after a page reload.
- **SC-002**: A user with 10 past conversations can navigate to any specific conversation in under 5 seconds.
- **SC-003**: Starting a new conversation or resuming a past one requires no more than 2 user interactions from the chat screen.
- **SC-004**: Zero cross-user data leaks: no user can view or continue another user's conversation.
- **SC-005**: The assistant replies coherently using the most recent exchanges as context. For conversations within the defined message limit, reply quality is indistinguishable from a session that never left the page. Conversations exceeding the limit are expected to lose the oldest context — this is a known, accepted tradeoff.

## Assumptions

- Users are authenticated before accessing the chat feature; unauthenticated users cannot create or view conversations.
- When a user opens the chat, the system automatically loads their most recently updated conversation. If the user has no conversations yet, the system displays a "Start your first conversation" prompt; no conversation record is created until the first message is sent.
- Conversation deletion is out of scope for this iteration. **Known compliance risk**: storing CBT session content (thoughts, distress, cognitive distortions) may constitute sensitive health data under GDPR Article 9 and similar regulations. The right-to-erasure obligation is a deferred risk that requires a dedicated follow-up feature before this app is used in any jurisdiction where such obligations apply.
- The feature covers the text-based CBT coaching chat only; it does not apply to mood check-ins, gratitude logs, or other wellness features.
- Message content is stored as plain text; no rich formatting or attachments are in scope.
- The LLM provider and model selection remain unchanged by this feature; persistence only affects how history is stored and retrieved, not how it is used.

## Clarifications

### Session 2026-06-10

- Q: What determines the "active" conversation when a user opens the chat? → A: The most recently created or updated conversation is automatically loaded (Option A).
- Q: How are conversations identified/labeled in the history list? → A: Date and time the conversation was started (Option B); no user-defined title or message preview.
- Q: When is the user's message saved relative to the LLM call? → A: User message saved immediately on submission; assistant reply saved only on LLM success (Option A).
- Q: What happens if the same user has the chat open in two browser tabs simultaneously? → A: Both tabs write to the same conversation; messages are saved in arrival order, no conflict resolution needed (Option A).
- Q: What should the system show a first-time user with no conversations? → A: Display a "Start your first conversation" prompt; conversation record only created on first message send, no empty records (Option B).
- Q: Should the app acknowledge GDPR/health-data compliance risk for CBT session storage? → A: Keep deletion out of scope but document right-to-erasure as a known deferred compliance risk requiring a follow-up feature (Option B). Added to Assumptions; FR-011 (authorization policy) and FR-012 (atomicity) added as direct spec additions from review findings R-001 and R-006.
- Q: How much conversation history is sent to the LLM? → A: Only the most recent messages up to a defined limit; full history is stored but older messages beyond the limit are not included in the LLM context (Option B). Updated FR-004, SC-005, and long-conversation edge case.
- Q: Should message retry be idempotent (idempotency key per message)? → A: Accept the low risk of duplicate-on-retry as a known limitation; no idempotency key required for this personal wellness app (Option B). Edge case updated with known-limitation note.
