# Quickstart: Persist Conversations and Messages

**Branch**: `003-persist-conversations-messages`  
**Date**: 2026-06-10  
**For**: Developers starting implementation

---

## What This Feature Does

Replaces the in-memory, popup-only chat with persistent `Conversation` and `Message` records tied to each user. The chat becomes a dedicated `/conversations` page where users can view history, resume past sessions, and start new ones. History is loaded from the database on every request — the browser never sends history.

---

## New Files to Create

```
app/
├── models/
│   ├── conversation.rb              # belongs_to :user, has_many :messages
│   └── message.rb                   # belongs_to :conversation, touch: true
├── controllers/
│   ├── conversations_controller.rb  # index (redirect), show, create
│   └── messages_controller.rb       # create (Turbo Stream)
├── views/
│   └── conversations/
│       ├── index.html.erb           # Blank state / redirect target
│       ├── show.html.erb            # Chat UI with history + input form
│       └── _message.html.erb        # Partial for a single message bubble
│   └── messages/
│       └── create.turbo_stream.erb  # Appends user msg + assistant reply
├── services/
│   └── conversations/
│       └── send_message_service.rb  # Orchestrates save + LLM call
├── policies/
│   ├── application_policy.rb        # Default deny (Pundit base)
│   └── conversation_policy.rb       # Allow if record.user == user
└── javascript/
    └── controllers/
        └── conversation_controller.js  # Loading state during message send
db/
└── migrate/
    ├── YYYYMMDDHHMMSS_create_conversations.rb
    └── YYYYMMDDHHMMSS_create_messages.rb
spec/
├── factories/
│   ├── conversations.rb
│   └── messages.rb
├── models/
│   ├── conversation_spec.rb
│   └── message_spec.rb
├── policies/
│   └── conversation_policy_spec.rb
├── requests/
│   ├── conversations_spec.rb
│   └── messages_spec.rb
├── services/
│   └── conversations/
│       └── send_message_service_spec.rb
└── system/
    └── chat_spec.rb
```

---

## Files to Modify

| File | Change |
|------|--------|
| `Gemfile` | Add `gem "pundit"` |
| `app/controllers/application_controller.rb` | Add `include Pundit`, `rescue_from Pundit::NotAuthorizedError` |
| `app/models/user.rb` | Add `has_many :conversations, dependent: :destroy` |
| `config/routes.rb` | Add conversation/message resources; remove `post "chat"` |
| `app/views/home/index.html.erb` | Replace chat button → link to `conversations_path` |

---

## Files to Remove

| File | Reason |
|------|--------|
| `app/controllers/chats_controller.rb` | Replaced by ConversationsController + MessagesController |
| `app/javascript/controllers/chat_popup_controller.js` | Replaced by conversation_controller.js |

---

## Key Service: `Conversations::SendMessageService`

```ruby
result = Conversations::SendMessageService.call(
  user:         current_user,
  message:      "I've been feeling anxious lately",
  conversation: nil          # nil = create new; existing Conversation = add to it
)

result.success?       # => true / false
result.conversation   # => Conversation record
result.reply          # => "That sounds difficult. Can you tell me more..."
result.error          # => nil (or error message string)
```

Internal flow:
1. `ActiveRecord::Base.transaction { create_conversation_if_new; save_user_message }` — atomic (FR-012)
2. Fetch `conversation.messages_for_llm` (last 50 messages)
3. Call `Chat::ReplyService.call(message:, history:, api_key:)`
4. If success → save assistant reply → return success result
5. If failure → user message already saved → return failure result with error

---

## Running Tests for This Feature

```bash
# All feature tests
mise exec ruby@4.0.2 -- bundle exec rspec spec/models/conversation_spec.rb spec/models/message_spec.rb spec/policies/conversation_policy_spec.rb spec/requests/conversations_spec.rb spec/requests/messages_spec.rb spec/services/conversations/send_message_service_spec.rb spec/system/chat_spec.rb

# Just models
mise exec ruby@4.0.2 -- bundle exec rspec spec/models/conversation_spec.rb spec/models/message_spec.rb

# Just system (Capybara)
mise exec ruby@4.0.2 -- bundle exec rspec spec/system/chat_spec.rb
```

---

## Database Migration Commands

```bash
mise exec ruby@4.0.2 -- bin/rails db:migrate
mise exec ruby@4.0.2 -- bin/rails db:migrate:status
mise exec ruby@4.0.2 -- bin/rails db:rollback STEP=2   # undo both migrations if needed
```

---

## Constants

| Constant | Value | Where |
|----------|-------|-------|
| `Conversation::CONTEXT_MESSAGE_LIMIT` | `50` | `app/models/conversation.rb` |
| `Message::ROLES` | `%w[user assistant]` | `app/models/message.rb` |
