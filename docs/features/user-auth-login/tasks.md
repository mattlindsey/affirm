# Tasks: User Authentication and Login

**Branch:** `add-users`
**Total tasks:** 50
**Spec:** [spec.md](spec.md) | **Plan:** [plan.md](plan.md) | **Data model:** [data-model.md](data-model.md)

---

## Phase 1 — Setup (config, gems, routes)

_Complete before any other phase. No story label — these unlock all user stories._

- [x] T001 Add gems to Gemfile: uncomment `bcrypt ~> 3.1.7`; add `omniauth-google-oauth2`, `omniauth-rails_csrf_protection`, `rack-attack`; run `bundle install`
- [x] T002 Add auth routes to config/routes.rb: `get/post login`, `delete logout`, `get/post signup`, `get/post password_reset`, `patch password_reset`, `get /auth/google_oauth2/callback`, `get /auth/failure`
- [x] T003 Create config/initializers/rack_attack.rb: throttle `logins/email` to 10 POST /login attempts per 15 minutes per downcased email; set `throttled_responder` to return a full HTML 429 response (wrap the lockout message in a minimal `<html><body>` page — a plain-text body breaks Turbo Drive's response handling) with header `Content-Type: text/html; charset=utf-8`
- [x] T004 [P] Create config/initializers/omniauth.rb: configure `google_oauth2` provider with `ENV.fetch("GOOGLE_CLIENT_ID")` and `ENV.fetch("GOOGLE_CLIENT_SECRET")`, scope `email,profile`; add `config.middleware.use Rack::Attack` to config/application.rb

---

## Phase 2 — Foundational (migrations, User model, ApplicationController)

_Must complete entirely before Phase 3+. Migrations and model are shared prerequisites._

- [x] T005 Generate migration CreateUsers: columns `email:string:uniq`, `password_digest:string`, `google_uid:string`, `name:string`, `timestamps`; add unique partial index on `google_uid WHERE google_uid IS NOT NULL` in db/migrate/YYYYMMDDHHMMSS_create_users.rb
- [x] T006 [P] Generate migration AddUserIdToAffirmations: nullable `user_id:integer`, index in db/migrate/YYYYMMDDHHMMSS_add_user_id_to_affirmations.rb
- [x] T007 [P] Generate migration AddUserIdToGratitudes: nullable `user_id:integer`, index in db/migrate/YYYYMMDDHHMMSS_add_user_id_to_gratitudes.rb
- [x] T008 [P] Generate migration AddUserIdToMoodCheckIns: nullable `user_id:integer`, index in db/migrate/YYYYMMDDHHMMSS_add_user_id_to_mood_check_ins.rb
- [x] T009 [P] Generate migration AddUserIdToSettings: nullable `user_id:integer`, unique index in db/migrate/YYYYMMDDHHMMSS_add_user_id_to_settings.rb
- [x] T010 Generate migration AddForeignKeysForUserContent: add FK `user_id → users` with `on_delete: :cascade` to affirmations, gratitudes, mood_check_ins, settings; add FK to reflections (column already exists per schema.rb) in db/migrate/YYYYMMDDHHMMSS_add_foreign_keys_for_user_content.rb
- [x] T011 Run `bin/rails db:migrate` and verify `bin/rails db:migrate:status` shows all UP
- [x] T012 Create app/models/user.rb: `has_secure_password validations: false`; associations `has_one :setting`, `has_many :affirmations/gratitudes/mood_check_ins/reflections` all `dependent: :destroy`; `generates_token_for :password_reset, expires_in: 2.hours { password_digest }`; `before_validation :downcase_email`; validate email presence/uniqueness/format; validate password `length minimum: 8, allow_nil: true`; validate password_confirmation presence when password present; custom validate `password_or_google_uid_present`
- [x] T013 Update app/models/affirmation.rb: add `belongs_to :user, optional: true`
- [x] T014 [P] Update app/models/gratitude.rb: add `belongs_to :user, optional: true`
- [x] T015 [P] Update app/models/mood_check_in.rb: add `belongs_to :user, optional: true`
- [x] T016 [P] Update app/models/reflection.rb: add `belongs_to :user, optional: true`
- [x] T017 [P] Update app/models/setting.rb: add `belongs_to :user, optional: true`; remove the `instance` class method (it will be replaced by `current_user.setting || current_user.build_setting` in the controller)
- [x] T018 Update app/controllers/application_controller.rb: add `before_action :authenticate_user!`; add `helper_method :current_user, :user_signed_in?`; implement private `current_user` (memoized `User.find_by(id: session[:user_id])`), `user_signed_in?`, `authenticate_user!` (sets `response.headers["Cache-Control"] = "no-store"` then redirects to `login_path` — the no-store header prevents browsers from caching protected pages, satisfying SC-6), `store_location` (saves `request.fullpath` to session on GET), `redirect_back_or(default)`
- [x] T048 Create spec/support/omniauth_helpers.rb: set `OmniAuth.config.test_mode = true`; define `mock_google_auth(uid:, email:, name:)` helper that assigns `OmniAuth.config.mock_auth[:google_oauth2]` an `OmniAuth::AuthHash` with the given values; require this file in spec/rails_helper.rb so all request specs can call it
- [x] T049 [P] Configure ActionMailer for tests in config/environments/test.rb: set `config.action_mailer.delivery_method = :test` and `config.action_mailer.default_url_options = { host: "localhost", port: 3000 }`; add `before(:each) { ActionMailer::Base.deliveries.clear }` in the RSpec config block in spec/rails_helper.rb
- [x] T019 Write spec/models/user_spec.rb: test email presence/uniqueness/downcasing, password minimum length, password_confirmation required when password present, `password_or_google_uid_present` custom validation, Google-only account valid (no password), `generates_token_for(:password_reset)` returns token and expires in 2 hours

---

## Phase 3 — US1: Registration and unauthenticated redirect (Scenarios 1 & 5)

_Delivers: new users can create accounts; unauthenticated users are bounced to login._

**Independent test criteria:** A visitor can POST /signup with valid params, receive a session cookie, and be redirected to root. Any GET to a protected route without a session redirects to /login.

- [x] T020 Create app/controllers/registrations_controller.rb: `skip_before_action :authenticate_user!`; `new` (redirects to root if signed in, assigns `@user = User.new`); `create` (builds from `registration_params`, saves, sets `session[:user_id]`, redirects to root with notice OR re-renders new with 422); strong params permit `:email, :password, :password_confirmation`
- [x] T021 Create app/views/registrations/new.html.erb: Tailwind-styled form posting to `signup_path`; fields for email, password, password confirmation; inline model error display; "Continue with Google" rendered as `button_to "/auth/google_oauth2", method: :post, data: { turbo: false }` — must be a POST (not a GET link) because `omniauth-rails_csrf_protection` rejects GET-initiated OAuth; link to login page
- [x] T022 [P] Write spec/requests/registrations_spec.rb: POST /signup with valid params → 302 to root, session set; POST with duplicate email → 422, error message present; POST with password < 8 chars → 422; POST with mismatched confirmation → 422; GET /signup when already signed in → redirects to root; GET /daily_flow without session → redirects to /login (unauthenticated redirect test)
- [x] T023 [P] Write spec/factories/users.rb (FactoryBot): factory `:user` with email sequence, password `"password123"`, password_confirmation `"password123"`; trait `:google_only` with `google_uid` set and no password

---

## Phase 4 — US2: Email login, sign-out, and rate limiting (Scenarios 2 & 4)

_Delivers: existing users can sign in and out; too many failures trigger a lockout message._

**Independent test criteria:** POST /login with correct credentials sets session and redirects. DELETE /logout clears session. POST /login after 10 failures returns 429.

- [x] T024 Create app/controllers/sessions_controller.rb: `skip_before_action :authenticate_user!`; `new` (redirects to root if signed in); `create` (finds user by downcased email, calls `user.authenticate`, on success calls `sign_in` + `redirect_back_or root_path`, on failure renders new with 422 and `flash.now[:alert]`); `destroy` (deletes `session[:user_id]`, redirects to login); private `sign_in(user)` sets `session[:user_id]`
- [x] T025 Create app/views/sessions/new.html.erb: Tailwind-styled form posting to `login_path`; email and password fields; "Sign in" submit; "Continue with Google" rendered as `button_to "/auth/google_oauth2", method: :post, data: { turbo: false }` (must be POST — same CSRF requirement as T021); "Forgot password?" link to `password_reset_path`; link to signup page; inline flash alert display for error messages
- [x] T026 [P] Write spec/requests/sessions_spec.rb: POST /login correct credentials → 302 to root, session[:user_id] set; POST /login wrong password → 422, flash alert generic message; POST /login unknown email → 422, same generic message; DELETE /logout → session cleared, redirected to login; GET /login when signed in → redirects to root; POST /login after 10 consecutive failures from same email → 429 response with lockout message

---

## Phase 5 — US3: Google OAuth sign-in and auto-link (Scenario 3)

_Delivers: users can sign in via Google; new Google users get accounts; existing email/password accounts get Google linked._

**Independent test criteria:** GET /auth/google_oauth2/callback with valid OmniAuth env creates or finds a user and sets session. Existing user with matching email gets google_uid saved. GET /auth/failure redirects to /login with alert.

- [x] T047 Create app/services/auth/process_oauth_callback_service.rb: `.call(auth_hash)` class method; extracts uid/email/name from auth_hash; finds existing user by `google_uid`, then by `email`; auto-links google_uid when blank; creates new user if not found; returns the user record — no session or redirect logic (belongs in controller)
- [x] T027 Add `omniauth` and `oauth_failure` actions to app/controllers/sessions_controller.rb: `omniauth` delegates entirely to `Auth::ProcessOauthCallbackService.call(request.env["omniauth.auth"])` to get the user, then calls `sign_in(user)` + `redirect_back_or root_path`; `oauth_failure` sets `flash[:alert]` and redirects to `login_path`
- [x] T028 [P] Write spec/requests/sessions_spec.rb — OAuth section (append to existing file or add shared context): mock OmniAuth env for Google; GET /auth/google_oauth2/callback with new Google email → user created, session set; with existing google_uid → signed in, no duplicate created; with email matching existing email/password account → google_uid linked, signed in; GET /auth/failure → redirected to /login with alert flash

---

## Phase 6 — US4: Password reset (Scenario 7)

_Delivers: users who forgot their password can reset it via email link._

**Independent test criteria:** POST /password_reset with any email shows neutral confirmation. GET /password_reset/edit with valid token renders form. PATCH /password_reset with valid token + new password updates password, signs user in, redirects to root. Invalid/expired token redirects to /password_reset with alert.

- [x] T029 Create app/mailers/password_reset_mailer.rb: `reset(user)` method generates token via `user.generate_token_for(:password_reset)`, builds `edit_password_reset_url(token: @token)`, mails to user email with subject "Reset your Affirm password"
- [x] T030 Create app/views/password_reset_mailer/reset.html.erb: Tailwind-styled email body with greeting, explanation, reset link button, and 2-hour expiry notice
- [x] T031 [P] Create app/views/password_reset_mailer/reset.text.erb: plain-text version of reset email with URL on its own line
- [x] T032 Create app/controllers/password_resets_controller.rb: `skip_before_action :authenticate_user!`; `new` (renders email request form); `create` (finds user by email, calls `PasswordResetMailer.reset(user).deliver_later` if found, always redirects to login with neutral notice); `edit` (finds user via `User.find_by_token_for(:password_reset, params[:token])`, redirects with alert if nil); `update` (same token lookup, updates with `password_reset_params`, on success signs in + redirects to root, on failure re-renders edit 422)
- [x] T033 Create app/views/password_resets/new.html.erb: single email field form posting to `password_reset_path`; link back to login
- [x] T034 [P] Create app/views/password_resets/edit.html.erb: hidden `token` field (value from `params[:token]`), new password field, confirmation field; form patches to `password_reset_path`
- [x] T035 [P] Write spec/requests/password_resets_spec.rb: POST /password_reset registered email → redirects to login with neutral notice, `deliver_later` enqueued; POST /password_reset unknown email → same neutral response (no info leak); GET /password_reset/edit valid token → 200; GET with invalid/expired token → redirects to /password_reset; PATCH /password_reset valid token + valid password → password updated, session set, redirected to root; PATCH invalid token → redirected with alert

---

## Phase 7 — US5: Data isolation — scope existing controllers (Scenario 6)

_Delivers: every piece of wellness content is filtered to the signed-in user only._

**Independent test criteria:** Signed-in user sees only their own records on every index page. Creating content via a controller sets `user_id` to `current_user.id`. A user cannot reach another user's record by guessing IDs.

- [x] T036 Update app/controllers/affirmations_controller.rb: `index` → `current_user.affirmations.order(created_at: :desc)`; `random` → scoped to `current_user.affirmations`; `create` → `current_user.affirmations.new(affirmation_params)`; `destroy` → find via `current_user.affirmations.find(params[:id])` to prevent cross-user delete
- [x] T037 [P] Update app/controllers/gratitude_controller.rb: scope `index`, `random`, `prompt` reads and any writes through `current_user.gratitudes`
- [x] T038 [P] Update app/controllers/checkins_controller.rb: `index` → `current_user.mood_check_ins.order(created_at: :desc)` (or existing scope)
- [x] T039 [P] Update app/controllers/reflections_controller.rb: `index` → `current_user.reflections`
- [x] T040 Update app/controllers/settings_controller.rb: replace every `Setting.instance` call with `current_user.setting || current_user.build_setting`
- [x] T041 Update app/controllers/home_controller.rb: replace `Setting.instance.name` with `current_user.setting&.name`
- [x] T042 Update app/controllers/daily_flow_controller.rb: scope all `MoodCheckIn.new`, `Gratitude.new`, `Reflection.new` through `current_user` associations (e.g. `current_user.mood_check_ins.new(...)`)
- [x] T043 [P] Write spec/requests/data_isolation_spec.rb: two users each with affirmations; signed in as user A → GET /affirmations shows only user A's records; GET /affirmations as user B → shows only user B's; unauthenticated GET → redirects to login; destroy another user's affirmation by ID → 404
- [x] T050 [P] Write spec/system/authentication_spec.rb: full sign-up flow (fill form → land on dashboard); sign-in with email → see personal dashboard; sign-out → GET /daily_flow redirects to /login; verify that after sign-out the back-button response has `Cache-Control: no-store` header

---

## Phase 8 — Polish (nav, lint, security)

- [x] T044 Update app/views/layouts/application.html.erb: in nav, add conditional block — when `user_signed_in?` show user name/email and a sign-out form (`button_to logout_path, method: :delete`); when not signed in, show "Sign in" and "Sign up" links and hide all content nav links (Daily Workflow, Check-ins, etc.)
- [x] T045 [P] Run `bundle exec rubocop -a app/controllers/sessions_controller.rb app/controllers/registrations_controller.rb app/controllers/password_resets_controller.rb app/models/user.rb config/initializers/rack_attack.rb` and fix any remaining offenses
- [x] T046 [P] Run `bin/brakeman --no-pager` and resolve any findings in the new auth code

---

## Dependency Graph

```
Phase 1 (T001–T004)
  └── Phase 2 (T005–T019)   ← all foundational, must be 100% green before Phase 3
        ├── Phase 3 US1 (T020–T023)
        ├── Phase 4 US2 (T024–T026)   ← can start in parallel with Phase 3
        ├── Phase 5 US3 (T027–T028)   ← depends on Phase 4 (adds to SessionsController)
        ├── Phase 6 US4 (T029–T035)   ← independent of Phases 3–5
        └── Phase 7 US5 (T036–T043)   ← independent, but practical after Phase 3/4 (needs auth working)
              └── Phase 8 Polish (T044–T046)
```

---

## Parallel execution examples

**Phase 2 inner parallels:**
- T006, T007, T008, T009 (four content table migrations) — all [P], different files
- T013, T014, T015, T016, T017 (model `belongs_to` additions) — all [P], different files

**Phase 3 + Phase 6 outer parallel:**
- After Phase 2 is green, Phases 3, 4, and 6 can be started concurrently by different agents — they touch different controllers and views.

**Phase 7 inner parallels:**
- T037, T038, T039 — all [P] controller scoping, different files

---

## Implementation strategy (MVP scope)

**MVP = Phases 1–4** (T001–T026):

Delivers a fully working email/password auth system with registration, login, sign-out, and rate limiting. The app is protected and personal. Google OAuth (Phase 5), password reset (Phase 6), and full data scoping (Phase 7) can ship in a subsequent increment on the same branch.

---

## Summary

| Phase | Tasks | Parallel tasks | User story |
|-------|-------|---------------|------------|
| 1 — Setup | 4 | 1 | — |
| 2 — Foundational | 17 | 10 | — (includes T048, T049 test setup + cache-control) |
| 3 — Registration | 4 | 2 | US1 (Scenarios 1 & 5) |
| 4 — Email login | 3 | 1 | US2 (Scenarios 2 & 4) |
| 5 — Google OAuth | 3 | 1 | US3 (Scenario 3) — includes T047 service |
| 6 — Password reset | 7 | 3 | US4 (Scenario 7) |
| 7 — Data scoping | 9 | 6 | US5 (Scenario 6) — includes T050 system spec |
| 8 — Polish | 3 | 2 | — |
| **Total** | **50** | **26** | |
