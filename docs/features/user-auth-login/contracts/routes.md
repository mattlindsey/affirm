# Route Contracts: User Authentication and Login

## New routes

```ruby
# Session (login / logout)
get  "login"  => "sessions#new",     as: :login
post "login"  => "sessions#create"
delete "logout" => "sessions#destroy", as: :logout

# Registration (sign-up)
get  "signup" => "registrations#new",    as: :signup
post "signup" => "registrations#create"

# Password reset
get  "password_reset"       => "password_resets#new",    as: :password_reset
post "password_reset"       => "password_resets#create"
get  "password_reset/edit"  => "password_resets#edit",   as: :edit_password_reset
patch "password_reset"      => "password_resets#update"

# Google OAuth callbacks
get  "/auth/google_oauth2/callback" => "sessions#omniauth"
get  "/auth/failure"                => "sessions#oauth_failure"
```

## Controller → action mapping

| Method | Path | Controller#Action | Auth required | Description |
|--------|------|-------------------|---------------|-------------|
| GET | /login | sessions#new | No | Login form |
| POST | /login | sessions#create | No | Authenticate credentials |
| DELETE | /logout | sessions#destroy | Yes | Sign out |
| GET | /signup | registrations#new | No | Sign-up form |
| POST | /signup | registrations#create | No | Create account |
| GET | /password_reset | password_resets#new | No | Request reset form |
| POST | /password_reset | password_resets#create | No | Send reset email |
| GET | /password_reset/edit | password_resets#edit | No | Set new password form (token in query string) |
| PATCH | /password_reset | password_resets#update | No | Save new password |
| GET | /auth/google_oauth2/callback | sessions#omniauth | No | OAuth callback |
| GET | /auth/failure | sessions#oauth_failure | No | OAuth error page |

## Route helpers

| Helper | Path |
|--------|------|
| `login_path` | /login |
| `logout_path` | /logout |
| `signup_path` | /signup |
| `password_reset_path` | /password_reset |
| `edit_password_reset_path` | /password_reset/edit |

## Access control

All existing routes gain implicit authentication via `before_action :authenticate_user!` in `ApplicationController`. The sessions, registrations, and password_resets controllers skip this filter with `skip_before_action :authenticate_user!`.

## Existing routes — no changes needed

All existing resource routes (`/affirmations`, `/gratitude`, `/reflections`, `/checkins`, `/settings`, `/daily_flow`) remain as-is. Authentication enforcement happens at the ApplicationController level.
