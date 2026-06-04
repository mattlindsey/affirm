# Data Model: User Authentication and Login

## New table: `users`

```ruby
create_table :users do |t|
  t.string  :email,           null: false
  t.string  :password_digest              # null for Google-only accounts
  t.string  :google_uid                   # null for email-only accounts
  t.string  :name
  t.timestamps
end

add_index :users, :email,      unique: true
add_index :users, :google_uid, unique: true, where: "google_uid IS NOT NULL"
```

**Constraints:**
- `email` is unique (case-insensitive — enforce via `before_validation :downcase_email`)
- `password_digest` and `google_uid` may each be null; at least one must be present (model-level validation)
- `google_uid` uniqueness index uses a partial index so the NULL-for-email-only rows don't conflict

---

## Modified tables

### `affirmations`

```ruby
add_column :affirmations, :user_id, :integer
add_index  :affirmations, :user_id
add_foreign_key :affirmations, :users, on_delete: :cascade
```

### `gratitudes`

```ruby
add_column :gratitudes, :user_id, :integer
add_index  :gratitudes, :user_id
add_foreign_key :gratitudes, :users, on_delete: :cascade
```

### `mood_check_ins`

```ruby
add_column :mood_check_ins, :user_id, :integer
add_index  :mood_check_ins, :user_id
add_foreign_key :mood_check_ins, :users, on_delete: :cascade
```

### `reflections`

```ruby
# user_id column already exists in schema; add FK and index if missing
add_index   :reflections, :user_id  # if not already present
add_foreign_key :reflections, :users, on_delete: :cascade
```

### `settings`

```ruby
add_column :settings, :user_id, :integer
add_index  :settings, :user_id, unique: true  # one setting record per user
add_foreign_key :settings, :users, on_delete: :cascade
```

---

## Migration safety plan

1. All `add_column` calls are nullable with no default — safe on live data, no table lock.
2. Each foreign key migration is separate from the `add_column` migration to allow easy rollback.
3. Existing records will have `user_id: NULL` and remain invisible once scoping is enforced.
4. No mixed DDL + data manipulation in any single migration.
5. The `reflections` table already has a `user_id` column per `schema.rb`; only the FK constraint needs adding.
6. Migration order: `create_users` → `add_user_id_to_*` (each table separately) → `add_fk_to_*`.

---

## Model associations

```ruby
# User
has_one  :setting,      dependent: :destroy
has_many :affirmations, dependent: :destroy
has_many :gratitudes,   dependent: :destroy
has_many :mood_check_ins, dependent: :destroy
has_many :reflections,  dependent: :destroy

# Setting, Affirmation, Gratitude, MoodCheckIn, Reflection
belongs_to :user, optional: true  # optional: true preserves orphan records
```

---

## State transitions: account linking

```
Email-only account                Google-only account
  password_digest: [hash]          google_uid: [uid]
  google_uid: nil                  password_digest: nil
         |                                |
         +------ Google sign-in ---------> Auto-link
                 (matching email)         google_uid: [uid]
                                          password_digest: [hash]  (both present)
```

---

## Token: password reset

Handled by `User.generates_token_for :password_reset, expires_in: 2.hours`.  
No additional column or table needed. Token fingerprint includes `password_digest`, so it is automatically invalidated after use.
