# frozen_string_literal: true

require "test_helper"

class TestSidekiqMemoryLoggerMiddleware < Minitest::Test
  def setup
    @middleware = Sidekiq::Memory::Logger::Middleware.new
    @job = {"class" => "TestJob"}
    @queue = "test_queue"
    Sidekiq::Memory::Logger.reset!
  end

  def test_middleware_calls_callback_when_configured
    callback_calls = []

    Sidekiq::Memory::Logger.configure do |config|
      config.callback = ->(job_class, queue, memory_diff) do
        callback_calls << [job_class, queue, memory_diff]
      end
    end

    @middleware.call(nil, @job, @queue) { sleep 0.01 }

    assert_equal 1, callback_calls.length
    job_class, queue, memory_diff = callback_calls.first
    assert_equal "TestJob", job_class
    assert_equal "test_queue", queue
    assert_kind_of Float, memory_diff
  end

  def test_middleware_logs_when_no_callback
    log_output = StringIO.new
    test_logger = Logger.new(log_output)

    Sidekiq::Memory::Logger.configure do |config|
      config.logger = test_logger
    end

    @middleware.call(nil, @job, @queue) { sleep 0.01 }

    log_content = log_output.string
    assert_includes log_content, "Job TestJob on queue test_queue used"
    assert_includes log_content, "MB"
  end

  def test_middleware_handles_exceptions
    callback_calls = []

    Sidekiq::Memory::Logger.configure do |config|
      config.callback = ->(job_class, queue, memory_diff) do
        callback_calls << [job_class, queue, memory_diff]
      end
    end

    assert_raises(RuntimeError) do
      @middleware.call(nil, @job, @queue) { raise "test error" }
    end

    assert_equal 1, callback_calls.length
  end

  def test_default_logger_without_rails
    log_output = StringIO.new

    @middleware.stub :default_logger, Logger.new(log_output) do
      @middleware.call(nil, @job, @queue) { sleep 0.01 }
    end

    log_content = log_output.string
    assert_includes log_content, "Job TestJob on queue test_queue used"
  end
end
