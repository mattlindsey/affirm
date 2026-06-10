# Route Contracts: Persist Conversations and Messages

**Branch**: `003-persist-conversations-messages`  
**Date**: 2026-06-10

---

## Routes DSL

```ruby
# config/routes.rb — additions / replacements

resources :conversations, only: [:index, :show, :create] do
  resources :messages, only: [:create]
end

# REMOVE: post "chat" => "chats#create"
```

---

## Route Reference

| HTTP | Path | Controller#Action | Route Helper | Auth | Description |
|------|------|-------------------|--------------|------|-------------|
| GET | `/conversations` | `conversations#index` | `conversations_path` | Required | Redirect to most recent conversation, or render blank chat state for first-time users |
| GET | `/conversations/:id` | `conversations#show` | `conversation_path(:id)` | Required | Full chat view: message history + conversation list sidebar + input form |
| POST | `/conversations` | `conversations#create` | `conversations_path` | Required | Atomically create new conversation + first message; redirect to `show` |
| POST | `/conversations/:conversation_id/messages` | `messages#create` | `conversation_messages_path(:conversation_id)` | Required | Add a message to an existing conversation; respond with Turbo Stream |

---

## Controller Contracts

### ConversationsController

**`#index`**
- Authorization: `authorize Conversation`; policy scope to `current_user`
- Logic: Redirect to most recent conversation (`current_user.conversations.recent.first`); if none, render blank state with "Start your first conversation" prompt
- Render: Redirect to `show` OR `index.html.erb` with empty state
- No params

**`#show`**
- Authorization: `authorize @conversation`
- Logic: Load `@conversation = current_user.conversations.find(params[:id])`; load `@messages = @conversation.messages.chronological`; load `@conversations = policy_scope(Conversation).recent` for sidebar
- Render: `show.html.erb` (Turbo Drive)
- Param: `id` — conversation ID

**`#create`**
- Authorization: `authorize Conversation`
- Logic: Call `Conversations::SendMessageService.call(user: current_user, message: params[:message], conversation: nil)` — creates conversation + first message atomically
- Success: Redirect to `conversation_path(result.conversation)`
- Failure: Render blank chat state with inline error
- Strong params: `params.require(:message)` (string, max 10,000 chars enforced by model)

### MessagesController

**`#create`**
- Authorization: `authorize @conversation, :show?` (user owns the conversation)
- Logic: Load `@conversation = current_user.conversations.find(params[:conversation_id])`; call `Conversations::SendMessageService.call(user: current_user, message: params[:message], conversation: @conversation)`
- Success: Respond with `turbo_stream` appending user message + assistant reply to `dom_id(@conversation, :messages)`
- Failure: Respond with `turbo_stream` replacing a `flash` target with the error
- Strong params: `params.require(:message)` (string)

---

## Removed Routes

| HTTP | Path | Old Action | Reason |
|------|------|-----------|--------|
| POST | `/chat` | `chats#create` | Replaced by `conversations#create` and `messages#create` |

`ChatsController` and `app/javascript/controllers/chat_popup_controller.js` are removed. The home page chat button becomes a link to `conversations_path`.

---

## Response Formats

| Action | Format | Response Type |
|--------|--------|---------------|
| `conversations#index` | HTML | Redirect (Turbo Drive) |
| `conversations#show` | HTML | Full page (Turbo Drive) |
| `conversations#create` | HTML | Redirect on success; render on failure |
| `messages#create` | `turbo_stream` | Turbo Stream (append messages) |
| `messages#create` (error) | `turbo_stream` | Turbo Stream (replace flash) |

---

## Authorization Summary

All routes require authentication (`before_action :authenticate_user!` in `ApplicationController`). All resource actions call `authorize` via Pundit. `ConversationPolicy` grants access only when `record.user == current_user`. Message access delegates to the parent conversation's authorization.
