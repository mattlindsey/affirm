# N+1 Query Detection and Prevention Patterns

## The N+1 Problem

```ruby
# BAD: N+1 query - 1 query for events, N queries for venues
@events = Event.all
@events.each do |event|
  puts event.venue.name  # Query per event!
end

# Generated SQL:
# SELECT * FROM events
# SELECT * FROM venues WHERE id = 1
# SELECT * FROM venues WHERE id = 2
# SELECT * FROM venues WHERE id = 3
# ... (N more queries)
```

## The Solution: Eager Loading

```ruby
# GOOD: Eager loading - 2 queries total
@events = Event.includes(:venue)
@events.each do |event|
  puts event.venue.name  # No additional query
end

# Generated SQL:
# SELECT * FROM events
# SELECT * FROM venues WHERE id IN (1, 2, 3, ...)
```

## Eager Loading Methods

### includes (Preferred)

```ruby
# Single association
Event.includes(:venue)

# Multiple associations
Event.includes(:venue, :organizer)

# Nested associations
Event.includes(venue: :address)
Event.includes(vendors: { category: :parent })

# Deep nesting
Event.includes(
  :venue,
  :organizer,
  vendors: [:category, :reviews],
  comments: :user
)
```

### preload vs eager_load

```ruby
# preload: Separate queries (default for includes)
Event.preload(:venue)
# SELECT * FROM events
# SELECT * FROM venues WHERE id IN (...)

# eager_load: Single LEFT JOIN query
Event.eager_load(:venue)
# SELECT events.*, venues.* FROM events LEFT JOIN venues ON ...

# includes chooses automatically based on conditions
Event.includes(:venue).where(venues: { city: 'Paris' })
# Uses LEFT JOIN because of WHERE condition on venue
```

### When to Use Each

| Method | Use When |
|--------|----------|
| `includes` | Most cases (Rails chooses best strategy) |
| `preload` | Forcing separate queries, large datasets |
| `eager_load` | Filtering on association, need single query |
| `joins` | Only need to filter, don't need association data |

## Bullet Gem Configuration

```ruby
# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true

  # Raise errors in test
  # Bullet.raise = true
end

# config/environments/test.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.raise = true  # Fail tests on N+1
end
```

## N+1 Detection in Specs

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.before(:each) do
    Bullet.start_request
  end

  config.after(:each) do
    Bullet.perform_out_of_channel_notifications if Bullet.notification?
    Bullet.end_request
  end
end

# spec/requests/events_spec.rb
RSpec.describe "Events", type: :request do
  it "loads index without N+1" do
    create_list(:event, 5, :with_venue, :with_vendors)

    expect {
      get events_path
    }.not_to raise_error  # Bullet raises on N+1
  end
end
```

## Query Count Assertions

```ruby
# spec/support/query_counter.rb
module QueryCounter
  def count_queries(&block)
    count = 0
    counter = ->(*, _) { count += 1 }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end
end

RSpec.configure do |config|
  config.include QueryCounter
end

# Usage
it "makes minimal queries" do
  events = create_list(:event, 5, :with_venue)

  query_count = count_queries do
    Event.with_details.map { |e| e.venue.name }
  end

  expect(query_count).to eq(2)  # events + venues
end
```

## Scoped Eager Loading Pattern

```ruby
# app/models/event.rb
class Event < ApplicationRecord
  scope :with_details, -> {
    includes(:venue, :organizer, vendors: :category)
  }

  scope :with_stats, -> {
    select("events.*,
            (SELECT COUNT(*) FROM comments WHERE comments.event_id = events.id) as comments_count,
            (SELECT COUNT(*) FROM event_vendors WHERE event_vendors.event_id = events.id) as vendors_count")
  }
end

# Controller
@events = Event.with_details.where(account: current_account)
```

## Counter Caches

```ruby
# Migration
add_column :events, :comments_count, :integer, default: 0, null: false
add_column :events, :vendors_count, :integer, default: 0, null: false

# Model
class Comment < ApplicationRecord
  belongs_to :event, counter_cache: true
end

class EventVendor < ApplicationRecord
  belongs_to :event, counter_cache: :vendors_count
end

# Usage - no query needed
event.comments_count
event.vendors_count
```
