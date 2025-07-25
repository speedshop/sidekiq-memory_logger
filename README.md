# Sidekiq Memory Logger

A Sidekiq server middleware that tracks RSS memory usage for each job and provides configurable logging and reporting options.

## How it works

This middleware measures the process RSS (Resident Set Size) memory before and after each Sidekiq job runs, then logs or reports the difference. This helps you identify memory-hungry jobs and track memory usage patterns across your Sidekiq workers.

Memory measurement is handled by the [get_process_mem](https://github.com/zombocom/get_process_mem) gem, which works reliably across all platforms (Windows, macOS, Linux) and functions both inside and outside of containers.

Example log output:
```
Job MyJob on queue default used 15.2 MB
```

The memory difference can be positive (job increased memory usage) or negative (job decreased memory usage, possibly due to garbage collection).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-memory-logger'
```

## Usage

### Basic Setup

Add the middleware to your Sidekiq server configuration:

```ruby
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::MemoryLogger::Middleware
  end
end
```

By default, this will log memory usage for each job to Rails.logger (if Rails is detected) or stdout:

```
Job MyJob on queue default used 15.2 MB
```

### Configuration

Configure custom logging behavior:

```ruby
Sidekiq::MemoryLogger.configure do |config|
  # Use a custom logger (overrides default Rails.logger detection)
  config.logger = MyCustomLogger.new
  
  # OR use a custom callback (this disables logging entirely)
  config.callback = ->(job_class, queue, memory_diff_mb) do
    # StatsD example
    StatsD.histogram('sidekiq.memory_usage', memory_diff_mb, tags: {
      job_class: job_class, 
      queue: queue
    })
    
    # Dogstatsd example
    # $dogstatsd.histogram('sidekiq.memory_usage', memory_diff_mb, tags: [
    #   "job_class:#{job_class}",
    #   "queue:#{queue}"
    # ])
    
    # New Relic example
    # NewRelic::Agent.record_metric('Custom/Sidekiq/MemoryUsage', memory_diff_mb)
    # NewRelic::Agent.add_custom_attributes({
    #   'sidekiq.job_class' => job_class,
    #   'sidekiq.queue' => queue
    # })
  end
end
```

### Rails Integration

For Rails applications, the middleware automatically uses `Rails.logger` by default. No additional configuration needed.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/speedshop/sidekiq-memory_logger.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
