# frozen_string_literal: true

require "test_helper"

class TestSidekiqMemoryLogger < Minitest::Test
  def setup
    Sidekiq::MemoryLogger.configuration.callback = nil
    Sidekiq::MemoryLogger.configuration.logger = nil
  end

  def test_that_it_has_a_version_number
    refute_nil ::Sidekiq::MemoryLogger::VERSION
  end

  def test_configuration
    Sidekiq::MemoryLogger.configure do |config|
      config.logger = "test_logger"
      config.callback = "test_callback"
    end

    assert_equal "test_logger", Sidekiq::MemoryLogger.configuration.logger
    assert_equal "test_callback", Sidekiq::MemoryLogger.configuration.callback
  end

  def test_configuration_object
    config = Sidekiq::MemoryLogger.configuration
    assert_instance_of Sidekiq::MemoryLogger::Configuration, config
  end

  def test_configuration_is_singleton
    config1 = Sidekiq::MemoryLogger.configuration
    config2 = Sidekiq::MemoryLogger.configuration
    assert_same config1, config2
  end

  def test_direct_configuration_access
    Sidekiq::MemoryLogger.configuration.logger = "direct_logger"
    assert_equal "direct_logger", Sidekiq::MemoryLogger.configuration.logger

    callback = ->(job, queue, memory) { "test" }
    Sidekiq::MemoryLogger.configuration.callback = callback
    assert_equal callback, Sidekiq::MemoryLogger.configuration.callback
  end
end
