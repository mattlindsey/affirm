# Memory Management, Profiling Tools, and Benchmarking Patterns

## Quick Start: Profiling Gems

```ruby
# Gemfile
group :development, :test do
  gem 'bullet'           # N+1 detection
  gem 'rack-mini-profiler' # Request profiling
  gem 'memory_profiler'  # Memory analysis
end
```

## Memory Profiling

### Finding Memory Issues

```ruby
# In console or specs
require 'memory_profiler'

report = MemoryProfiler.report do
  # Code to profile
  Event.includes(:venue, :vendors).to_a
end

report.pretty_print
```

### Memory-Efficient Patterns

```ruby
# BAD: Loads all records
Event.all.map(&:name).join(', ')

# GOOD: Streams results
Event.pluck(:name).join(', ')

# BAD: Builds large array
results = []
Event.find_each { |e| results << e.name }

# GOOD: Uses Enumerator
Event.find_each.map(&:name)
```

### Avoiding Memory Bloat

```ruby
# BAD: Instantiates all AR objects
Event.all.each do |event|
  event.update!(processed: true)
end

# GOOD: Direct SQL update
Event.update_all(processed: true)

# GOOD: Batched updates
Event.in_batches.update_all(processed: true)
```

## Rack Mini Profiler

### Setup

```ruby
# Gemfile
gem 'rack-mini-profiler'
gem 'stackprof'  # For flamegraphs

# config/initializers/rack_profiler.rb
if Rails.env.development?
  Rack::MiniProfiler.config.position = 'bottom-right'
  Rack::MiniProfiler.config.start_hidden = false
end
```

### Usage

- Visit any page -- profiler badge shows in corner
- Click badge to see detailed breakdown
- Add `?pp=flamegraph` for flamegraph
- Add `?pp=help` for all options

## Performance Checklist

### Before Deployment

- [ ] Bullet enabled in development/test
- [ ] No N+1 queries in critical paths
- [ ] Foreign keys have indexes
- [ ] Counter caches for frequent counts
- [ ] Eager loading in controllers
- [ ] Batch processing for large datasets
- [ ] Query analysis for slow endpoints
