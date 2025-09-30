# Changelog

## [0.2.0]

- Fixed compatibility with ActiveJob, we now correctly report the wrapped class
- Removed Rails logger test mocks in favor of real integration testing

## [0.1.1]

- Renamed gem from `sidekiq-memory-logger` to `sidekiq-memory_logger` for consistency with Ruby naming conventions

## [0.1.0]

- Object allocation tracking using `GC.stat[:total_allocated_objects]`
- Queue filtering configuration to selectively monitor specific queues
- Performance benchmarking using sidekiqload tool
- Support for custom callbacks (StatsD, New Relic, Datadog examples)
at: `[MemoryLogger] job=MyJob queue=default memory_mb=15.2 objects=12345`

