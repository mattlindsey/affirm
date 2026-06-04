# Implementation Plan: User Authentication and Login

**Branch:** `add-users`  
**Stack:** Ruby 4 / Rails 8.1 / SQLite3 / Hotwire (Turbo + Stimulus) / Tailwind CSS 4  
**Spec:** [spec.md](spec.md) | **Data model:** [data-model.md](data-model.md) | **Routes:** [contracts/routes.md](contracts/routes.md) | **Research:** [research.md](research.md)

---

## Hotwire Decision Matrix

| Interaction | Mechanism | Rationale |
|---|---|---|
| Login form submit (success) | Turbo Drive redirect | Full page nav to dashboard; no partial update needed |
| Login form submit (error) | Turbo Drive re-render | Server re-renders login with inline errors; no JS needed |
| Account locked message | Turbo Drive re-render | Same page, flash alert injected in layout |
| Sign-up form submit | Turbo Drive redirect | Same pattern as login |
| Sign-up form validation errors | Turbo Drive re-render | Inline model errors |
| Sign out | Turbo Drive (form DELETE) | Session destroy + redirect to login |
| Password reset request | Turbo Drive redirect | Confirmation page after form POST |
| Password reset form | Turbo Drive redirect | Redirect to login after success |
| Google OAuth initiation | Native browser redirect | OAuth handshake requires full browser redirect; Turbo must be bypassed (`data-turbo: false` on the button) |
| Google OAuth callback | Native browser redirect | OmniAuth callback returns from Google as a full browser GET |
| OAuth error page | Turbo Drive | Static error page, no interaction |
| Nav bar (auth state) | Turbo Drive | Auth state changes on full page navigations; no stream needed |
| Flash messages | Turbo Drive | Already wired in layout; works transparently |

---

## Implementation Steps

### Step 1 — Gems

**Gemfile changes:**
```ruby
gem "bcrypt", "~> 3.1.7"           # uncomment existing line
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"
gem "rack-attack"
```

Run: `bundle install`

---

### Step 2 — User model and migrations

**Migration order (one file each):**

1. `CreateUsers` — new table (see data-model.md for schema)
2. `AddUserIdToAffirmations`
3. `AddUserIdToGratitudes`
4. `AddUserIdToMoodCheckIns`
5. `AddUserIdToSettings` + unique index
6. `AddForeignKeysForUserContent` — add FKs with `on_delete: :cascade` to all four content tables + settings
   - `reflections` already has `user_id` column; only add FK here

**User model (`app/models/user.rb`):**
```ruby
class User < ApplicationRecord
  has_secure_password validations: false  # custom validation below

  has_one  :setting,        dependent: :destroy
  has_many :affirmations,   dependent: :destroy
  has_many :gratitudes,     dependent: :destroy
  has_many :mood_check_ins, dependent: :destroy
  has_many :reflections,    dependent: :destroy

  generates_token_for :password_reset, expires_in: 2.hours do
    password_digest
  end

  before_validation :downcase_email

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :password_or_google_uid_present

  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :password_confirmation, presence: true, if: -> { password.present? }

  private

  def downcase_email
    self.email = email&.downcase
  end

  def password_or_google_uid_present
    return if password_digest.present? || google_uid.present?
    errors.add(:base, "must have either a password or a Google account linked")
  end
end
```

**Update existing models** — add `belongs_to :user, optional: true` to:
- `Affirmation`, `Gratitude`, `MoodCheckIn`, `Reflection`, `Setting`

**Update `Setting` model** — remove `instance` class method; replace with user-scoped lookup via association.

---

### Step 3 — Authentication infrastructure (ApplicationController)

```ruby
class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :authenticate_user!

  helper_method :current_user, :user_signed_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    return if user_signed_in?
    store_location
    redirect_to login_path, alert: "Please sign in to continue."
  end

  def store_location
    session[:return_to] = request.fullpath if request.get?
  end

  def redirect_back_or(default)
    redirect_to(session.delete(:return_to) || default)
  end
end
```

---

### Step 4 — SessionsController (login, logout, OAuth)

```ruby
class SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    redirect_to root_path if user_signed_in?
  end

  def create
    user = User.find_by(email: params[:email]&.downcase)
    if user&.authenticate(params[:password])
      sign_in(user)
      redirect_back_or root_path
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: "You have been signed out."
  end

  def omniauth
    auth = request.env["omniauth.auth"]
    user = User.find_by(google_uid: auth.uid) ||
           User.find_by(email: auth.info.email)

    if user
      user.update(google_uid: auth.uid) if user.google_uid.blank?
    else
      user = User.create!(
        email:      auth.info.email,
        name:       auth.info.name,
        google_uid: auth.uid
      )
    end

    sign_in(user)
    redirect_back_or root_path
  end

  def oauth_failure
    flash[:alert] = "Google sign-in is temporarily unavailable. Please try again later."
    redirect_to login_path
  end

  private

  def sign_in(user)
    session[:user_id] = user.id
  end
end
```

**Rate limiting** — Rack::Attack config (`config/initializers/rack_attack.rb`):
```ruby
class Rack::Attack
  throttle("logins/email", limit: 10, period: 15.minutes) do |req|
    req.params["email"]&.downcase if req.path == "/login" && req.post?
  end

  self.throttled_responder = lambda do |req|
    [ 429, { "Content-Type" => "text/html" },
      ["Too many sign-in attempts. Please wait 15 minutes before trying again."] ]
  end
end
```

Add to `config/application.rb`: `config.middleware.use Rack::Attack`

---

### Step 5 — RegistrationsController (sign-up)

```ruby
class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    redirect_to root_path if user_signed_in?
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Welcome to Affirm!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
```

---

### Step 6 — PasswordResetsController + mailer

**Controller:**
```ruby
class PasswordResetsController < ApplicationController
  skip_before_action :authenticate_user!

  def new; end

  def create
    user = User.find_by(email: params[:email]&.downcase)
    PasswordResetMailer.reset(user).deliver_later if user
    # Always show neutral confirmation (do not reveal if email exists)
    redirect_to login_path,
      notice: "If that address is registered, a reset link is on its way."
  end

  def edit
    @user = User.find_by_token_for(:password_reset, params[:token])
    redirect_to password_reset_path, alert: "Reset link is invalid or expired." unless @user
  end

  def update
    @user = User.find_by_token_for(:password_reset, params[:token])
    unless @user
      redirect_to password_reset_path, alert: "Reset link is invalid or expired." and return
    end

    if @user.update(password_reset_params)
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Password updated. You are now signed in."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_reset_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
```

**Mailer (`app/mailers/password_reset_mailer.rb`):**
```ruby
class PasswordResetMailer < ApplicationMailer
  def reset(user)
    @user  = user
    @token = user.generate_token_for(:password_reset)
    @url   = edit_password_reset_url(token: @token)
    mail(to: @user.email, subject: "Reset your Affirm password")
  end
end
```

---

### Step 7 — OmniAuth configuration

**`config/initializers/omniauth.rb`:**
```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV.fetch("GOOGLE_CLIENT_ID"),
           ENV.fetch("GOOGLE_CLIENT_SECRET"),
           scope: "email,profile"
end
```

**`.env` / credentials** (never committed):
```
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
```

Google Cloud Console setup required: add `http://localhost:3000/auth/google_oauth2/callback` as an authorized redirect URI in development.

---

### Step 8 — Scope existing content to current_user

Update every controller that reads content to scope by `current_user`:

**Pattern (apply to each):**
```ruby
# AffirmationsController
def index
  @affirmations = current_user.affirmations.order(created_at: :desc)
end

def create
  @affirmation = current_user.affirmations.new(affirmation_params)
  ...
end
```

**Controllers to update:**
- `AffirmationsController` — index, create, destroy (scope destroy via association)
- `GratitudeController` — index, random, prompt, save (any write)
- `CheckinsController` — index
- `ReflectionsController` — index
- `SettingsController` — replace `Setting.instance` with `current_user.setting || current_user.build_setting`
- `DailyFlowController` — scope check-in creation, gratitude creation, reflection creation

---

### Step 9 — Views

**Login page (`app/views/sessions/new.html.erb`):**
- Email field, password field, submit button
- "Continue with Google" button — `data-turbo="false"` to bypass Turbo for the OAuth redirect
- Link to sign-up page and forgot-password page

**Sign-up page (`app/views/registrations/new.html.erb`):**
- Email, password, password confirmation fields
- "Continue with Google" button — same `data-turbo="false"`
- Link back to login

**Password reset request (`app/views/password_resets/new.html.erb`):**
- Email field only

**Password reset form (`app/views/password_resets/edit.html.erb`):**
- New password + confirmation fields
- Hidden token field

**Email templates:**
- `app/views/password_reset_mailer/reset.html.erb`
- `app/views/password_reset_mailer/reset.text.erb`

**Application layout nav update:**
- When signed in: show user email/name + "Sign out" link (form with DELETE method)
- When signed out: show "Sign in" + "Sign up" links
- Hide all nav links (Daily Workflow, Check-ins, etc.) when not signed in — unauthenticated users only see auth pages

---

### Step 10 — Tests

**Model specs:**
- `User` — validations, `has_secure_password`, `generates_token_for`, `downcase_email`, Google/email-only accounts

**Request specs (one file per controller):**
- `SessionsController` — login success, wrong password, locked account (11th attempt), sign-out, OAuth callback (new user, existing user, email match / auto-link), OAuth failure
- `RegistrationsController` — success, duplicate email, weak password
- `PasswordResetsController` — request (existing/non-existing email shows same flash), valid token → password updated, expired/tampered token → redirect

**System specs:**
- Full sign-up → see personal dashboard
- Sign in with email → see own data only
- Data isolation: two users, no cross-visibility
- Sign out → back button blocked

---

## Dependency Graph

```
Step 1 (gems)
  └── Step 2 (migrations + User model)
        └── Step 3 (ApplicationController auth)
              ├── Step 4 (SessionsController)
              ├── Step 5 (RegistrationsController)
              ├── Step 6 (PasswordResetsController)
              └── Step 8 (scope existing controllers)
        └── Step 7 (OmniAuth config) ← feeds Step 4#omniauth
Step 9 (views) ← depends on Steps 4, 5, 6
Step 10 (tests) ← depends on all steps
```

---

## Open questions / risks

| Item | Risk | Mitigation |
|------|------|------------|
| `Setting.instance` singleton | High — currently used in HomeController and SettingsController | Replace fully in Step 8; update all call sites |
| Orphan records | Low — nullable `user_id`, scoped queries hide them | No action needed; document in seed notes |
| Google credentials in CI | Medium | Use Rails credentials or env vars; add to `.gitignore` / CI secrets |
| `reflections.user_id` already exists | Low — may have stale FK from prior work | Check schema; only add FK if absent |
