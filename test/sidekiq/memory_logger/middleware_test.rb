# frozen_string_literal: true

require "test_helper"

class TestSidekiqMemoryLoggerMiddleware < Minitest::Test
  def setup
    @job = {"class" => "TestJob", "args" => [123, "test_arg"]}
    @queue = "test_queue"
  end

  def test_middleware_calls_callback_when_configured
    callback_calls = []
    config = Sidekiq::MemoryLogger::Configuration.new
    config.callback = ->(job_class, queue, memory_diff, objects_diff, args) do
      callback_calls << [job_class, queue, memory_diff, objects_diff, args]
    end

    middleware = Sidekiq::MemoryLogger::Middleware.new(config)
    middleware.call(nil, @job, @queue) { sleep 0.01 }

    assert_equal 1, callback_calls.length
    job_class, queue, memory_diff, _objects_diff, args = callback_calls.first
    assert_equal "TestJob", job_class
    assert_equal "test_queue", queue
    assert_kind_of Float, memory_diff
    assert_equal [123, "test_arg"], args
  end

  def test_middleware_logs_with_default_callback
    log_output = StringIO.new
    test_logger = Logger.new(log_output)
    config = Sidekiq::MemoryLogger::Configuration.new
    config.logger = test_logger
    # Reset to default callback (which logs)
    config.callback = config.send(:default_callback)

    middleware = Sidekiq::MemoryLogger::Middleware.new(config)
    middleware.call(nil, @job, @queue) { sleep 0.01 }

    log_content = log_output.string
    assert_includes log_content, "[MemoryLogger] job=TestJob queue=test_queue memory_mb="
    assert_includes log_content, "objects="
  end

  def test_middleware_handles_exceptions
    callback_calls = []
    config = Sidekiq::MemoryLogger::Configuration.new
    config.callback = ->(job_class, queue, memory_diff, objects_diff, args) do
      callback_calls << [job_class, queue, memory_diff, objects_diff, args]
    end

    middleware = Sidekiq::MemoryLogger::Middleware.new(config)

    assert_raises(RuntimeError) do
      middleware.call(nil, @job, @queue) { raise "test error" }
    end

    assert_equal 1, callback_calls.length
  end

  def test_middleware_handles_callback_exceptions
    log_output = StringIO.new
    test_logger = Logger.new(log_output)
    config = Sidekiq::MemoryLogger::Configuration.new
    config.logger = test_logger
    config.callback = ->(job_class, queue, memory_diff, objects_diff, args) do
      raise StandardError, "callback error"
    end

    middleware = Sidekiq::MemoryLogger::Middleware.new(config)

    # Middleware should not raise, but should log the error
    middleware.call(nil, @job, @queue) { sleep 0.01 }

    log_content = log_output.string
    assert_includes log_content, "Sidekiq memory logger callback failed: callback error"
  end

  def test_middleware_passes_job_arguments_to_callback
    callback_args = nil
    job_with_company_id = {
      "class" => "ProcessCompanyDataJob",
      "args" => [42, "Acme Corp", {"priority" => "high"}]
    }

    config = Sidekiq::MemoryLogger::Configuration.new
    config.callback = ->(job_class, queue, memory_diff, objects_diff, args) do
      callback_args = args
    end

    # Create middleware with custom configuration
    middleware = Sidekiq::MemoryLogger::Middleware.new(config)
    middleware.call(nil, job_with_company_id, @queue) { sleep 0.01 }

    assert_equal [42, "Acme Corp", {"priority" => "high"}], callback_args
  end

  def test_middleware_works_with_empty_job_args
    callback_args = nil
    job_without_args = {
      "class" => "CleanupJob",
      "args" => []
    }

    config = Sidekiq::MemoryLogger::Configuration.new
    config.callback = ->(job_class, queue, memory_diff, objects_diff, args) do
      callback_args = args
    end

    # Create middleware with custom configuration
    middleware = Sidekiq::MemoryLogger::Middleware.new(config)
    middleware.call(nil, job_without_args, @queue) { sleep 0.01 }

    assert_equal [], callback_args
  end

  def test_middleware_works_with_nil_job_args
    callback_args = :not_set
    job_with_nil_args = {
      "class" => "SpecialJob"
      # Note: no "args" key at all
    }

    config = Sidekiq::MemoryLogger::Configuration.new
    config.callback = ->(job_class, queue, memory_diff, objects_diff, args) do
      callback_args = args
    end

    # Create middleware with custom configuration
    middleware = Sidekiq::MemoryLogger::Middleware.new(config)
    middleware.call(nil, job_with_nil_args, @queue) { sleep 0.01 }

    assert_nil callback_args
  end

  def test_middleware_skips_queues_not_in_config
    callback_calls = []
    config = Sidekiq::MemoryLogger::Configuration.new
    config.queues = ["important", "critical"]
    config.callback = ->(job_class, queue, memory_diff, objects_diff, args) do
      callback_calls << [job_class, queue, memory_diff, objects_diff, args]
    end

    middleware = Sidekiq::MemoryLogger::Middleware.new(config)
    middleware.call(nil, @job, "unimportant_queue") { sleep 0.01 }

    assert_equal 0, callback_calls.length
  end

  def test_middleware_processes_queues_in_config
    callback_calls = []
    config = Sidekiq::MemoryLogger::Configuration.new
    config.queues = ["test_queue", "critical"]
    config.callback = ->(job_class, queue, memory_diff, objects_diff, args) do
      callback_calls << [job_class, queue, memory_diff, objects_diff, args]
    end

    middleware = Sidekiq::MemoryLogger::Middleware.new(config)
    middleware.call(nil, @job, "test_queue") { sleep 0.01 }

    assert_equal 1, callback_calls.length
    job_class, queue, _memory_diff, _objects_diff, _args = callback_calls.first
    assert_equal "TestJob", job_class
    assert_equal "test_queue", queue
  end

  def test_middleware_processes_all_queues_when_empty_config
    callback_calls = []
    config = Sidekiq::MemoryLogger::Configuration.new
    config.queues = []
    config.callback = ->(job_class, queue, memory_diff, objects_diff, args) do
      callback_calls << [job_class, queue, memory_diff, objects_diff, args]
    end

    middleware = Sidekiq::MemoryLogger::Middleware.new(config)
    middleware.call(nil, @job, "any_queue") { sleep 0.01 }

    assert_equal 1, callback_calls.length
    job_class, queue, _memory_diff, _objects_diff, _args = callback_calls.first
    assert_equal "TestJob", job_class
    assert_equal "any_queue", queue
  end
end
