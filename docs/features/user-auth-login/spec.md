# Feature Specification: User Authentication and Login

**Branch**: `add-users`
**Created**: 2026-06-01
**Status**: Draft

---

## Overview

Users need to create a personal account and log in to the Affirm wellness app so their private data — affirmations, gratitude entries, mood check-ins, and reflections — is accessible only to them. Authentication can be established with an email address and password, or by signing in with a Google account (OAuth). Once authenticated, users see only the content they have personally created; unauthenticated visitors cannot access any app content beyond the sign-in/sign-up pages.

---

## Problem Statement

The app currently stores all wellness content in a shared, unprotected database. Any person who visits the application can see (or accidentally overwrite) everyone else's data. Users cannot maintain a private, personal record of their mental wellness journey.

---

## Goals

1. Allow a new user to register an account using their email address and a chosen password.
2. Allow an existing user to sign in with their email and password.
3. Allow users to sign in with their existing Google account (no password required).
4. Restrict all wellness content (affirmations, gratitude, mood check-ins, reflections, settings) to the authenticated owner.
5. Provide a way for users to sign out.

---

## Non-Goals

- Password reset by SMS or security questions (email link reset is sufficient).
- Support for authentication providers other than Google and email/password.
- Admin or role-based access control (all authenticated users have the same permissions over their own data).
- Public or shareable profiles.
- Adding a password to an existing Google-only account (post-MVP; no route or form for this flow is in scope for this feature).

---

## User Scenarios & Testing

### Scenario 1 — New user registers with email

**Given** a visitor who does not yet have an account  
**When** they open the sign-up form, enter a valid email and password, and submit  
**Then** an account is created, they are automatically signed in, and they land on their personal home dashboard

**Edge cases**:
- Submitting with an email that is already registered → show an inline error, do not create a duplicate account
- Submitting with a mismatched password confirmation → show inline validation error before submission
- Submitting with a password below minimum length (8 characters) → show inline validation error

---

### Scenario 2 — Existing user signs in with email

**Given** a registered user with an email/password account  
**When** they enter their correct email and password on the login page  
**Then** they are signed in and land on their personal dashboard

**Edge cases**:
- Wrong password → show a generic "Invalid email or password" error (do not reveal which field is wrong)
- Unknown email → same generic error
- Submitting an empty form → show validation errors

---

### Scenario 3 — User signs in with Google

**Given** any visitor (new or returning)  
**When** they click "Continue with Google" and complete Google's authorization flow  
**Then**:
- If first time: an account is created linked to their Google identity, they are signed in
- If returning: they are signed in to their existing account

---

### Scenario 4 — User signs out

**Given** a signed-in user  
**When** they click "Sign out"  
**Then** their session is cleared and they are redirected to the login page

---

### Scenario 5 — Unauthenticated access is blocked

**Given** a visitor who is not signed in  
**When** they attempt to navigate to any protected page (dashboard, affirmations, gratitude, check-ins, reflections, settings)  
**Then** they are redirected to the login page; after signing in they are taken to the page they originally requested

---

### Scenario 6 — Data isolation

**Given** two users, Alice and Bob, who have each created their own affirmations and gratitude entries  
**When** Alice is signed in  
**Then** she sees only her own entries — Bob's data never appears in any list, index, or search result

---

### Scenario 7 — Password reset

**Given** a registered email/password user who has forgotten their password  
**When** they request a password reset using their email address  
**Then** a reset link is delivered to that email; following the link lets them set a new password and then signs them in

---

## Clarifications

### Session 2026-06-03

- Q: Should the app enforce brute force / rate limiting on failed login attempts? → A: App-level throttle — lock or block after 10 consecutive failed attempts per email address.
- Q: When a Google sign-in email matches an existing email/password account, should the Google identity be permanently linked? → A: Yes — auto-link the Google identity to the existing account so the user can sign in via either method on future visits.
- Q: What should happen when Google OAuth is unavailable? → A: Redirect to an error page informing the user that Google sign-in is temporarily unavailable and to try again later.
- Q: How long should a password reset link remain valid? → A: 2 hours.

---

## Functional Requirements

### Authentication entry points

1. The application must provide a login page accessible at a well-known URL (e.g., `/login`) with fields for email and password, a "Sign in" button, and a "Continue with Google" button.
2. The application must provide a sign-up page with fields for email, password, and password confirmation, plus a "Continue with Google" option.
3. A "Forgot password?" link on the login page must initiate an email-based password reset flow.

### Account creation (email/password)

4. A user may register using any valid, unique email address and a password of at least 8 characters.
5. On successful registration the user is automatically signed in and redirected to their dashboard.
6. If the email is already in use the form must display a clear, inline error message.
7. Password and password confirmation must match; a mismatch must display an inline error before the record is saved.

### Sign in (email/password)

8. Correct credentials must sign the user in and redirect them to the originally requested page, or the dashboard if no page was requested.
9. Incorrect credentials must display a generic "Invalid email or password" message that does not identify which field is wrong.
10. After 10 consecutive failed sign-in attempts for a given email address, further attempts must be blocked for a cooling-off period of 15 minutes. The user must be shown a clear message that the account is temporarily locked and directed to wait or use password reset.

### Sign in (Google OAuth)

11. Tapping "Continue with Google" must initiate an OAuth flow using the user's Google account.
12. If the Google email matches an existing account, the Google identity is permanently linked to that account and the user is signed in. On future visits the user may sign in via either email/password or Google.
13. If the Google email is new, an account is created and the user is signed in automatically.
14. Accounts created via Google do not require a password.
15. If Google's OAuth service is unreachable or returns an error, the user must be redirected to a dedicated error page explaining that Google sign-in is temporarily unavailable and instructing them to try again later.

### Session management

16. A signed-in session must persist across browser page loads (session cookie).
17. A "Sign out" action must destroy the session and redirect to the login page.

### Access control

18. Every page except the login, sign-up, and password-reset pages must require authentication. Unauthenticated requests must be redirected to login.
19. All wellness content (affirmations, gratitude entries, mood check-ins, reflections, settings) must be scoped to the authenticated user; a user must never be able to read or modify another user's records.

### Password reset

20. Submitting a valid email on the "forgot password" page must send a reset link to that address. The link must expire after 2 hours.
21. Submitting an email that is not registered must show a neutral confirmation message (do not confirm or deny whether the email exists).
22. Following a valid, unexpired reset link must allow the user to set a new password and then sign them in.

---

## Key Entities

### User

| Attribute | Type | Notes |
|-----------|------|-------|
| id | integer | Primary key |
| email | string | Unique, required, downcased |
| password_digest | string | BCrypt hash; null if Google-only |
| google_uid | string | Google OAuth identifier; null if email-only |
| created_at | datetime | |
| updated_at | datetime | |

All existing content entities (Affirmation, Gratitude, MoodCheckIn, Reflection, Setting) gain a `user_id` foreign key linking them to their owner.

---

## Success Criteria

1. A new visitor can create an account and access their personal dashboard in under 60 seconds.
2. A returning user can sign in (email or Google) in under 10 seconds on a standard connection.
3. No wellness content from one user is ever visible to another user.
4. All protected routes redirect unauthenticated users to the login page.
5. A password reset email is delivered within 60 seconds of request.
6. After sign-out, the browser back button does not grant access to protected content.

---

## Dependencies & Constraints

- The app uses Rails 8.1 with `has_secure_password` available natively; no external auth library is required for email/password.
- Google OAuth requires a registered OAuth application in Google Cloud Console with valid client credentials stored as environment variables (not in source code).
- Existing records in the database do not belong to any user; a migration strategy for this orphan data is required (see Assumptions).

---

## Assumptions

1. **Orphan data migration**: Existing records (affirmations, gratitude, check-ins, reflections) created before this feature will be assigned to the first user who signs up, or simply left un-owned and hidden from all users. The simpler approach — hide un-owned records — is assumed; orphan data can be cleaned up manually if needed.
2. **Session duration**: Sessions expire when the browser closes (session cookie), which is the Rails default. Persistent "remember me" login is out of scope.
3. **Password policy**: Minimum 8 characters. No complexity rules (uppercase, symbols) to keep registration friction low.
4. **Email uniqueness**: Case-insensitive uniqueness is enforced at the database level.
5. **Google OAuth scope**: Only the user's email address and basic profile (name) will be requested. No access to Google Drive, Calendar, or other services.
6. **Single Google account per app account**: A Google UID can only be linked to one app account; attempting to link the same Google account to a second email account will result in an error.
