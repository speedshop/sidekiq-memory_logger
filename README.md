# Sidekiq Memory Logger

This tool tracks memory usage for each Sidekiq job. It helps you identify memory-heavy jobs that might be slowing down your workers.

Have you ever seen your Sidekiq workers consume excessive memory? This gem helps you pinpoint which jobs are causing the problem.

![memory](https://github.com/user-attachments/assets/6084306f-1f3e-4fdb-9c4a-fccc63a2942f)

## How it works

This gem uses [get_process_mem](https://github.com/zombocom/get_process_mem) to measure memory usage. It works across all platforms (Windows, macOS, Linux) and containers.

By default, this gem writes a simple message for every job:
```
Job MyJob on queue default used 15.2 MB
```

We recommend using these logs to investigate memory issues. You can also send this data to monitoring tools like Datadog or create custom metrics.

> [!WARNING]
> **Important limitation:** Concurrent job execution can lead to inaccurate memory attribution. Since all threads share the same process heap, memory increases from simultaneous jobs may be incorrectly attributed to all running jobs.
>
> **Workaround:** Collect sufficient sample data and focus on jobs that consistently show high memory usage patterns rather than one-off spikes. This statistical approach helps identify problematic jobs despite measurement noise.

## Installation

Add this line to your app's Gemfile:

```ruby
gem 'sidekiq-memory-logger'
```

## Usage

### Basic Setup

Add this code to set up the memory logger:

```ruby
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::MemoryLogger::Middleware
  end
end
```

That's it! You're ready to start tracking memory usage.

### Configuration

You can change how the memory logger works or send the memory data to other tools.

```ruby
Sidekiq::MemoryLogger.configure do |config|
  # Use a different logger if you want
  config.logger = MyCustomLogger.new
  
  # Only watch certain queues (leave empty to watch all)
  config.queues = ["critical", "mailers"]  # Only watch these queues
  # config.queues = []  # Watch all queues (default)
  
  # Do something custom with the memory data
  config.callback = ->(job_class, queue, memory_diff_mb, args) do
    # Get extra info from job data
    company_id = args&.first
    
    # Send to StatsD
    StatsD.histogram('sidekiq.memory_usage', memory_diff_mb, tags: {
      job_class: job_class, 
      queue: queue,
      company_id: company_id
    })
    
    # Log it too
    Rails.logger.info "Job #{job_class} for company #{company_id} on queue #{queue} used #{memory_diff_mb} MB"
    
    # Send to Datadog
    # $dogstatsd.histogram('sidekiq.memory_usage', memory_diff_mb, tags: [
    #   "job_class:#{job_class}",
    #   "queue:#{queue}",
    #   "company_id:#{company_id}"
    # ])
    
    # Send to New Relic
    # NewRelic::Agent.record_metric("Custom/Sidekiq/MemoryUsage/#{queue}/#{job_class}", memory_diff_mb)
  end
  
  # The normal way just logs like this:
  # config.callback = ->(job_class, queue, memory_diff_mb, args) do
  #   config.logger.info("Job #{job_class} on queue #{queue} used #{memory_diff_mb} MB")
  # end
  
  # If you want to send data somewhere AND keep logging:
  config.callback = ->(job_class, queue, memory_diff_mb, args) do
    # Send data to another tool
    StatsD.histogram('sidekiq.memory_usage', memory_diff_mb, tags: {
      job_class: job_class, 
      queue: queue
    })
    
    # Keep the log messages too
    Rails.logger.info "Job #{job_class} on queue #{queue} used #{memory_diff_mb} MB"
  end
end
```

## Performance Impact

This middleware introduces minimal performance overhead due to memory measurement and callback execution.

Our benchmarks show it **adds ~0.16ms of latency per job**. The memory footprint increase is negligible. Consider this overhead for high-throughput production environments. Use the `queues` setting to limit monitoring to specific queues you're debugging.
