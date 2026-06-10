# Data Model: Persist Conversations and Messages

**Branch**: `003-persist-conversations-messages`  
**Date**: 2026-06-10

---

## Entity: Conversation

Represents a single coaching session. Belongs to one user. Has zero or more messages. Identified by its creation timestamp.

### Database Table: `conversations`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | integer | PK, auto-increment | SQLite default |
| `user_id` | integer | NOT NULL, FK → users | |
| `created_at` | datetime | NOT NULL | Auto-managed by Rails |
| `updated_at` | datetime | NOT NULL | Bumped by `touch: true` on message saves |

### Indexes

| Name | Columns | Reason |
|------|---------|--------|
| `index_conversations_on_user_id` | `user_id` | Scope all conversation queries to user |
| `index_conversations_on_user_id_and_updated_at` | `user_id`, `updated_at` | Fast lookup of "most recent conversation for user" |

### Foreign Keys

| References | `on_delete` | Rationale |
|------------|-------------|-----------|
| `users.id` | `:cascade` | Matches all other user-owned models in this app |

### Model Design

```ruby
class Conversation < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy

  validates :user, presence: true

  scope :recent, -> { order(updated_at: :desc) }

  CONTEXT_MESSAGE_LIMIT = 50

  def messages_for_llm
    messages.order(created_at: :asc).last(CONTEXT_MESSAGE_LIMIT)
  end
end
```

### Migration

```ruby
create_table :conversations do |t|
  t.references :user, null: false, foreign_key: { on_delete: :cascade }
  t.timestamps
end

add_index :conversations, [:user_id, :updated_at]
```

---

## Entity: Message

A single turn within a conversation. Records who sent it (user or assistant) and the text content.

### Database Table: `messages`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | integer | PK, auto-increment | SQLite default |
| `conversation_id` | integer | NOT NULL, FK → conversations | |
| `role` | string | NOT NULL | Values: `'user'` or `'assistant'` |
| `content` | text | NOT NULL | Max 10,000 characters |
| `created_at` | datetime | NOT NULL | Defines display order |
| `updated_at` | datetime | NOT NULL | Auto-managed by Rails |

### Indexes

| Name | Columns | Reason |
|------|---------|--------|
| `index_messages_on_conversation_id` | `conversation_id` | Load all messages for a conversation |

### Foreign Keys

| References | `on_delete` | Rationale |
|------------|-------------|-----------|
| `conversations.id` | `:cascade` | Deleting a conversation removes all its messages |

### Model Design

```ruby
class Message < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :conversation, touch: true

  validates :role,    presence: true, inclusion: { in: ROLES }
  validates :content, presence: true, length: { maximum: 10_000 }

  scope :chronological, -> { order(created_at: :asc) }
end
```

### Migration

```ruby
create_table :messages do |t|
  t.references :conversation, null: false, foreign_key: { on_delete: :cascade }
  t.string :role,    null: false
  t.text   :content, null: false
  t.timestamps
end
```

---

## Entity Relationships

```
User (existing)
 └── has_many :conversations (new)
      └── has_many :messages (new)
```

No changes to existing models. `User` gains a `has_many :conversations, dependent: :destroy` association.

---

## Authorization Policy: ConversationPolicy (Pundit)

```ruby
class ConversationPolicy < ApplicationPolicy
  def index?  = true           # scope enforces user isolation
  def show?   = record.user == user
  def create? = true
end

class ConversationPolicy::Scope < ApplicationPolicy::Scope
  def resolve = scope.where(user:)
end
```

`MessagePolicy` delegates to the parent conversation's policy — messages are accessible if the conversation is accessible.

---

## Migration Safety Checklist

- [x] Migrations are reversible (`create_table` is always reversible via `drop_table`)
- [x] No DDL + data manipulation mixed in one migration
- [x] Foreign key constraints include `on_delete: :cascade`
- [x] Migration order: `conversations` before `messages` (dependency graph respected)
- [x] Indexes added in same migration (SQLite doesn't require concurrent index creation)
- [x] No data migration required (new tables only)

---

## Constants

| Constant | Value | Location | Purpose |
|----------|-------|----------|---------|
| `Conversation::CONTEXT_MESSAGE_LIMIT` | `50` | `app/models/conversation.rb` | Max messages sent to LLM as context |
| `Message::ROLES` | `%w[user assistant]` | `app/models/message.rb` | Valid role values |
