# frozen_string_literal: true

require "test_helper"

class TestSidekiqMemoryLoggerRails < Minitest::Test
  def setup
    # Reset configuration before each test
    Sidekiq::MemoryLogger.logger = nil
    Sidekiq::MemoryLogger.callback = nil
  end

  def test_initializer_logic_sets_rails_logger_when_defined
    # Mock Rails and Rails.logger
    rails_logger = "mock_rails_logger"
    rails_class = Class.new do
      define_singleton_method(:logger) { rails_logger }
    end

    # Temporarily define Rails constant
    Object.const_set(:Rails, rails_class)

    # Simulate the railtie initializer logic
    Sidekiq::MemoryLogger.logger = Rails.logger if defined?(Rails.logger)

    # Verify the logger was set
    assert_equal rails_logger, Sidekiq::MemoryLogger.logger
  ensure
    # Clean up the Rails constant
    Object.send(:remove_const, :Rails) if defined?(Rails)
  end

  def test_initializer_logic_does_not_set_logger_when_rails_logger_undefined
    # Mock Rails without logger method
    rails_class = Class.new
    Object.const_set(:Rails, rails_class)

    # Simulate the railtie initializer logic
    Sidekiq::MemoryLogger.logger = Rails.logger if defined?(Rails.logger)

    # Verify the logger was not set
    assert_nil Sidekiq::MemoryLogger.logger
  ensure
    # Clean up the Rails constant
    Object.send(:remove_const, :Rails) if defined?(Rails)
  end

  def test_initializer_logic_does_not_set_logger_when_rails_undefined
    # Ensure Rails is not defined
    rails_backup = nil
    if defined?(Rails)
      rails_backup = Rails
      Object.send(:remove_const, :Rails)
    end

    # Simulate the railtie initializer logic
    Sidekiq::MemoryLogger.logger = Rails.logger if defined?(Rails.logger)

    # Verify the logger was not set (should be nil since Rails.logger is not defined)
    assert_nil Sidekiq::MemoryLogger.logger
  ensure
    # Restore Rails if it was defined
    Object.const_set(:Rails, rails_backup) if rails_backup
  end

  def test_configuration_uses_rails_logger_when_available
    # Test that the configuration automatically detects and uses Rails.logger
    rails_logger = "mock_rails_logger"
    rails_class = Class.new do
      define_singleton_method(:logger) { rails_logger }
      define_singleton_method(:respond_to?) { |method| method == :logger }
    end

    # Temporarily define Rails constant
    Object.const_set(:Rails, rails_class)

    # Create new configuration (should detect Rails.logger)
    config = Sidekiq::MemoryLogger::Configuration.new

    # Verify Rails.logger was set as default
    assert_equal rails_logger, config.logger
  ensure
    # Clean up the Rails constant
    Object.send(:remove_const, :Rails) if defined?(Rails)
  end
end
