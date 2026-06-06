# Lessons Learned

A running log of implementation insights captured during SDD feature development.
Entries tagged by `[phase]` and `[category]` for future reference.

---

## 2026-06-06 — OpenAI API Key Settings

**Feature**: `openai-api-key-settings`

### [phase:implement] [category:tooling] Ruby version — always use mise

**Lesson**: All Rails/Bundler commands must be prefixed with `mise exec ruby@4.0.2 --`. The macOS system Ruby 2.6 intercepts bare `bin/rails` calls and fails with a Bundler version mismatch before the app even boots.

**Pattern**: `mise exec ruby@4.0.2 -- bin/rails ...` / `mise exec ruby@4.0.2 -- bundle exec rspec ...`

---

### [phase:implement] [category:ruby_llm] Per-request API key override

**Lesson**: RubyLLM 1.x supports per-request configuration via `RubyLLM.context`. This does **not** mutate the global config and is thread-safe.

**Pattern**:
```ruby
context = RubyLLM.context { |config| config.openai_api_key = user_key }
chat = context.chat(model: "gpt-4o-mini")
```

When no override is needed, `RubyLLM.context` (no block) still returns a valid `Context` that uses the global config.

---

### [phase:implement] [category:testing] Updating RubyLLM mocks after context refactor

**Lesson**: Existing specs that stub `allow(RubyLLM).to receive(:chat)` break when the service switches from `RubyLLM.chat(...)` to routing through `RubyLLM.context.chat(...)`. The fix is a two-level mock:

```ruby
let(:context_double) { instance_double(RubyLLM::Context) }

before do
  allow(RubyLLM).to receive(:context).and_return(context_double)
  allow(context_double).to receive(:chat).with(model: "gpt-4o-mini").and_return(chat_double)
end
```

Do **not** use `and_yield` on the context mock — the no-api_key path calls `RubyLLM.context` without a block and `and_yield` will raise.
