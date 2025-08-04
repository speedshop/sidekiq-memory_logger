# frozen_string_literal: true

require "test_helper"

begin
  require "rails"
rescue LoadError
  puts "Skipping Rails tests - Rails not available"
  return
end

class TestSidekiqMemoryLoggerRails < Minitest::Test
  def test_rails_is_available_and_responds_to_logger
    # Verify Rails constant exists and has logger method
    assert defined?(Rails), "Rails should be defined"
    assert Rails.respond_to?(:logger), "Rails should respond to logger"
  end

  def test_configuration_uses_rails_logger_when_rails_logger_available
    # Create a mock Rails with a logger
    original_logger_method = Rails.method(:logger) if Rails.respond_to?(:logger)
    test_logger = Logger.new(StringIO.new)
    
    Rails.define_singleton_method(:logger) { test_logger }

    # Create new configuration
    config = Sidekiq::MemoryLogger::Configuration.new

    # Should use our test Rails.logger
    assert_equal test_logger, config.logger
  ensure
    # Restore original logger method
    if original_logger_method
      Rails.define_singleton_method(:logger, &original_logger_method)
    end
  end

  def test_configuration_falls_back_when_rails_logger_nil
    # Ensure Rails.logger returns nil (default state)
    Rails.define_singleton_method(:logger) { nil }

    # Create new configuration
    config = Sidekiq::MemoryLogger::Configuration.new

    # Should fall back to stdout logger since Rails.logger is nil
    assert_instance_of Logger, config.logger
    assert_equal $stdout, config.logger.instance_variable_get(:@logdev).dev
  end

  def test_configuration_falls_back_when_rails_not_available
    # Temporarily hide Rails constant
    rails_backup = Object.send(:remove_const, :Rails) if defined?(Rails)

    # Create new configuration instance
    config = Sidekiq::MemoryLogger::Configuration.new

    # Should fall back to stdout logger
    assert_instance_of Logger, config.logger
    assert_equal $stdout, config.logger.instance_variable_get(:@logdev).dev
  ensure
    # Restore Rails constant
    Object.const_set(:Rails, rails_backup) if rails_backup
  end

  def test_configuration_falls_back_when_rails_logger_unavailable
    # Create mock Rails without logger method
    rails_backup = Object.send(:remove_const, :Rails) if defined?(Rails)
    rails_mock = Class.new
    Object.const_set(:Rails, rails_mock)

    # Create new configuration instance
    config = Sidekiq::MemoryLogger::Configuration.new

    # Should fall back to stdout logger since Rails doesn't respond to logger
    assert_instance_of Logger, config.logger
    assert_equal $stdout, config.logger.instance_variable_get(:@logdev).dev
  ensure
    # Restore Rails constant
    Object.send(:remove_const, :Rails)
    Object.const_set(:Rails, rails_backup) if rails_backup
  end
end
