# frozen_string_literal: true

require "test_helper"
require "logger"
require "rails"

class TestSidekiqMemoryLoggerRails < Minitest::Test
  def setup
    @original_logger = Rails.logger
  end

  def teardown
    Rails.logger = @original_logger
  end

  def test_configuration_uses_rails_logger_when_rails_logger_available
    test_logger = Logger.new(StringIO.new)
    Rails.logger = test_logger

    config = Sidekiq::MemoryLogger::Configuration.new

    assert_equal test_logger, config.logger
  end

  def test_configuration_falls_back_when_rails_logger_nil
    Rails.logger = nil

    config = Sidekiq::MemoryLogger::Configuration.new

    assert_instance_of Logger, config.logger
    assert_equal $stdout, config.logger.instance_variable_get(:@logdev).dev
  end
end
