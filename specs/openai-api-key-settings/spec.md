# Feature Specification: OpenAI API Key Settings

**Branch**: `openai-api-key-settings`
**Created**: 2026-06-06
**Status**: Draft

---

## Overview

Users can store their OpenAI API key through the Settings page. The key is entered via a password-style input field (characters hidden as typed), persisted to the user's settings record, and displayed as masked asterisks (`****`) on the Settings page when a key has been saved. The stored key takes precedence over any server-side environment variable of the same name.

---

## Problem Statement

The application uses an OpenAI API key to power AI features. Currently the key can only be set via a server environment variable, which is not user-configurable. Users need a way to supply their own key through the UI so they can use their personal API quota, and their key must override the default server-side key.

---

## User Scenarios & Testing

### US-1 [P1]: Enter an API Key for the First Time

As a logged-in user who has never saved an OpenAI API key,  
I want to enter my key on the Settings page  
so that the application uses my personal OpenAI account.

#### Acceptance Scenarios

- **Given** I am on the Settings page and no API key is saved, **When** I look at the API key field, **Then** it is empty and renders as a password input (characters hidden)
- **Given** I enter a valid API key and click Save, **When** the form submits, **Then** the key is saved and the page shows a masked value (e.g., `sk-••••••••••••••••`) confirming the key exists
- **Given** I enter an API key and click Save, **When** the key is saved, **Then** subsequent AI feature calls use my stored key, not the environment variable

---

### US-2 [P1]: View the Settings Page When a Key Is Already Saved

As a logged-in user who has previously saved an OpenAI API key,  
I want to see a masked representation of my key on the Settings page  
so that I know a key is on file without exposing the full value.

#### Acceptance Scenarios

- **Given** I have a saved API key and I visit the Settings page, **When** the page loads, **Then** the key field displays asterisks (`sk-••••••••••••••••` or similar masking) rather than the actual key value
- **Given** I have a saved API key, **When** I view the Settings page, **Then** the input field does not pre-populate with the real key value (preventing accidental clipboard exposure)

---

### US-3 [P1]: Update an Existing API Key

As a logged-in user with a saved OpenAI API key,  
I want to replace it with a new key  
so that I can rotate or change the key I use.

#### Acceptance Scenarios

- **Given** I have a saved API key, **When** I enter a new key in the password field and click Save, **Then** the old key is replaced and the Settings page shows the masked new key
- **Given** I submit the form with an empty key field, **When** the key field is blank, **Then** the existing key is preserved and not overwritten (leaving the field blank is treated as "no change")

---

### US-4 [P1]: Remove a Saved API Key

As a logged-in user who wants to stop using my personal API key,  
I want to remove my saved key  
so that the application falls back to the server default.

#### Acceptance Scenarios

- **Given** I have a saved API key and I am on the Settings page, **When** I click "Remove API Key", **Then** I am asked to confirm the removal before it is deleted
- **Given** I confirm removal, **When** the key is deleted, **Then** the Settings page shows the API key field as empty with no masked indicator
- **Given** I cancel the removal confirmation, **When** I return to the Settings page, **Then** the key is unchanged and the masked indicator is still shown
- **Given** I have no saved key, **When** I view the Settings page, **Then** the "Remove API Key" action is not present or is disabled
- **Given** my key has been removed, **When** the application needs an OpenAI key, **Then** it falls back to the environment variable if one is set

---

## Functional Requirements

**FR-001**: The Settings page must include an API key field that renders as a password input (characters masked as typed).

**FR-002**: When a user saves the form, the provided API key value must be persisted to the user's Settings record in the database.

**FR-003**: If the API key field is submitted empty, the existing saved key must not be overwritten (no-change semantics for blank submissions).

**FR-004**: When the Settings page is displayed and a key is already saved, the key field must not populate with the real key value; instead a masked indicator (e.g., `sk-••••••••••••••••`) must appear adjacent to or inside the field.

**FR-005**: When the application resolves the OpenAI API key at runtime, the user's stored key (if present) must take precedence over the `OPENAI_API_KEY` environment variable.

**FR-006**: Each user's API key is stored independently; one user's key must never be readable by another user.

**FR-007**: The API key must be stored in a dedicated column on the Settings table, separate from the existing `name` column.

**FR-008**: Users must be authenticated to view or update the API key field (no unauthenticated access).

**FR-009**: The Settings page must provide an explicit "Remove API Key" action that deletes the stored key. This action must require a confirmation step before the key is permanently deleted.

**FR-010**: The "Remove API Key" action must only be visible and accessible when the user has a key saved; it must be hidden or disabled when no key exists.

**FR-011**: After successful removal, the application must fall back to the server environment variable when resolving the OpenAI API key.

---

## Success Criteria

- A logged-in user can enter, save, and see a masked confirmation of their OpenAI API key in under 30 seconds via the Settings page.
- When a user has a saved key, the raw key value is never rendered in any page source, response body, or form field value attribute.
- AI-powered features use the user's stored key when one exists, verifiably bypassing the server environment variable.
- Submitting the settings form with an empty key field does not erase an existing saved key.
- No user can read another user's API key through any UI path.
- A user can remove their saved key in under 15 seconds, with the Settings page confirming the key has been cleared.

---

## Key Entities

### Setting (existing, extended)

| Field           | Type   | Notes                                      |
|-----------------|--------|--------------------------------------------|
| `id`            | int    | Primary key                                |
| `user_id`       | int    | Foreign key — belongs to User (unique)     |
| `name`          | string | Existing field — user display name         |
| `openai_api_key`| string | New field — stored API key (plain text or encrypted) |
| `created_at`    | datetime |                                          |
| `updated_at`    | datetime |                                          |

---

## Scope & Boundaries

**In scope:**
- Adding an `openai_api_key` column to the Settings table
- Password-style input on the Settings page
- Masked display when a key exists
- Blank-field no-op semantics (don't clear on blank submit)
- Explicit "Remove API Key" action with confirmation step
- Runtime key resolution that prefers the stored key over the environment variable

**Out of scope:**
- Validating the key format or testing it against the OpenAI API
- Encrypting the key at rest (can be addressed in a follow-up)
- Per-model or per-feature key overrides
- Key expiry or rotation reminders

---

## Assumptions

- The `Setting` model is a single record per user (one-to-one with `User`), as established by the existing unique index on `user_id`.
- Masking on the display page is a UI affordance only — the value is stored as plain text in the initial implementation.
- "Override environment variable" means the application's key-resolution logic reads the stored key first and uses it if non-blank, falling through to `ENV['OPENAI_API_KEY']` only when the stored key is absent.
- Removal requires a confirmation step to prevent accidental deletion; a browser-native confirmation dialog is an acceptable default.
- Authentication is already enforced by existing `before_action :authenticate_user!` in the application controller hierarchy.

---

## Dependencies

- Existing `Settings` table with `user_id` column (already migrated)
- Existing `SettingsController#update` action (will be extended)
- Wherever the application currently reads `ENV['OPENAI_API_KEY']` — those call sites must be updated to use the new resolution helper
