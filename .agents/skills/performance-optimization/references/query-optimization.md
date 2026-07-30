# Query Optimization Patterns

## Select Only Needed Columns

```ruby
# BAD: Loads all columns
User.all.map(&:name)

# GOOD: Loads only name
User.pluck(:name)

# GOOD: For objects with limited columns
User.select(:id, :name, :email).map { |u| "#{u.name} <#{u.email}>" }
```

## Batch Processing

```ruby
# BAD: Loads all records into memory
Event.all.each { |e| process(e) }

# GOOD: Processes in batches
Event.find_each(batch_size: 500) { |e| process(e) }

# GOOD: For updates
Event.in_batches(of: 1000) do |batch|
  batch.update_all(status: :archived)
end
```

## Exists? vs Any? vs Present?

```ruby
# BAD: Loads all records
if Event.where(status: :active).any?
if Event.where(status: :active).present?

# GOOD: SELECT 1 LIMIT 1
if Event.where(status: :active).exists?

# GOOD: For checking count
if Event.where(status: :active).count > 0
```

## Size vs Count vs Length

```ruby
# count: Always queries database
events.count  # SELECT COUNT(*) FROM events

# size: Uses counter cache or count
events.size   # Uses cached value if available

# length: Uses loaded collection or loads all
events.length # Loads all records if not loaded

# Best practices:
events.loaded? ? events.length : events.count
# OR just use size (handles both cases)
```

## Database Indexing

### Finding Missing Indexes

```ruby
# Check for missing foreign key indexes
ActiveRecord::Base.connection.tables.each do |table|
  columns = ActiveRecord::Base.connection.columns(table)
  fk_columns = columns.select { |c| c.name.end_with?('_id') }
  indexes = ActiveRecord::Base.connection.indexes(table)

  fk_columns.each do |col|
    indexed = indexes.any? { |idx| idx.columns.include?(col.name) }
    puts "Missing index: #{table}.#{col.name}" unless indexed
  end
end
```

### Index Types

```ruby
# Single column index
add_index :events, :status

# Composite index (order matters!)
add_index :events, [:account_id, :status]

# Unique index
add_index :users, :email, unique: true

# Partial index
add_index :events, :event_date, where: "status = 0"

# Covering index (PostgreSQL)
add_index :events, [:account_id, :status], include: [:name, :event_date]
```

### When to Add Indexes

| Add Index For | Example |
|--------------|---------|
| Foreign keys | `account_id`, `user_id` |
| Columns in WHERE | `WHERE status = 'active'` |
| Columns in ORDER BY | `ORDER BY created_at DESC` |
| Columns in JOIN | `JOIN ON events.venue_id` |
| Unique constraints | `email`, `uuid` |

## Query Analysis with EXPLAIN

```ruby
# Analyze query plan
Event.where(status: :active).explain

# Analyze with format
Event.where(status: :active).explain(:analyze)
```

## Logging Slow Queries

```ruby
# config/environments/production.rb
config.active_record.warn_on_records_fetched_greater_than = 1000

# Custom slow query logging
ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  if event.duration > 100  # ms
    Rails.logger.warn("SLOW QUERY (#{event.duration.round}ms): #{event.payload[:sql]}")
  end
end
```

## Monitoring Query Count in Development

```ruby
# app/controllers/application_controller.rb
around_action :log_query_count, if: -> { Rails.env.development? }

private

def log_query_count
  count = 0
  counter = ->(*, _) { count += 1 }
  ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
    yield
  end
  Rails.logger.info "QUERIES: #{count} for #{request.path}"
end
```
