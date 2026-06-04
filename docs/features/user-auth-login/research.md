# Research: User Authentication and Login

## Technology Decisions

### Email/password authentication

**Decision:** Rails 8 `has_secure_password` + manual session controller  
**Rationale:** The project already has bcrypt commented out in the Gemfile. `has_secure_password` gives BCrypt hashing, `authenticate` method, and `password_confirmation` validation out of the box — no Devise needed. Keeps the stack lean and the auth code readable.  
**Alternatives considered:** Devise — too much magic, hard to customise for Google linking; Rodauth — excellent but unfamiliar DSL.

---

### Google OAuth

**Decision:** `omniauth-google-oauth2` gem + `omniauth-rails_csrf_protection`  
**Rationale:** The de-facto standard Rails OmniAuth strategy. The CSRF protection gem wraps OmniAuth callbacks in Rails' authenticity token check (required since OmniAuth 2.x).  
**Alternatives considered:** Devise + OmniAuth — rejected (no Devise). Building raw OAuth from scratch — too much surface area.

---

### Rate limiting / brute force protection

**Decision:** `rack-attack` gem — throttle 10 failed logins per email per 15 minutes  
**Rationale:** Rack::Attack is the Rails-ecosystem standard. It hooks into Rack before the app sees the request, has zero model coupling, and stores throttle counters in Solid Cache (the project's existing cache store) via `Rails.cache`. No new infrastructure needed.  
**Alternatives considered:** Custom `before_action` counter in DB — more coupling, harder to test; Fail2ban at infra level — not sufficient on its own for app-level guarantee.

---

### Password reset tokens

**Decision:** Rails 8 `generates_token_for :password_reset, expires_in: 2.hours`  
**Rationale:** Introduced in Rails 7.1. Generates a signed, tamper-proof token tied to the record's state (password_digest is part of the token fingerprint, so a used token is automatically invalidated after the password changes). No separate `password_resets` table needed.  
**Alternatives considered:** SecureRandom token stored in DB column — requires migration and cleanup job; Devise-style — rejected.

---

### Session storage

**Decision:** Rails default cookie-based session (`ActionDispatch::Session::CookieStore`)  
**Rationale:** Sufficient for a single-server app. Session contains only `user_id`. Expires on browser close (no "remember me" in scope).  
**Alternatives considered:** Database-backed sessions — adds complexity, no benefit here.

---

### Settings scoping

**Decision:** Add `user_id` to `settings` table; replace `Setting.instance` with `current_user.setting` (has_one :setting, dependent: :destroy)  
**Rationale:** The existing singleton pattern becomes per-user. `has_one` with `dependent: :destroy` keeps teardown clean. Build the setting record lazily on first access.  
**Alternatives considered:** Merge name field into users table — simpler but loses extensibility of the settings pattern.

---

### Orphan data

**Decision:** Existing records retain `user_id: NULL`; all queries scope with `where(user_id: current_user)` so orphan records are invisible to all users. No automated reassignment.  
**Rationale:** Matches the spec assumption. Zero-risk data migration — no data is touched or deleted.
