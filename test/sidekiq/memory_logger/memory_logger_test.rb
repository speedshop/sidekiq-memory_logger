# frozen_string_literal: true

require "test_helper"

class TestSidekiqMemoryLogger < Minitest::Test
  def setup
    Sidekiq::MemoryLogger.callback = nil
    Sidekiq::MemoryLogger.logger = nil
  end

  def test_that_it_has_a_version_number
    refute_nil ::Sidekiq::MemoryLogger::VERSION
  end

  def test_configuration
    Sidekiq::MemoryLogger.configure do |config|
      config.logger = "test_logger"
      config.callback = "test_callback"
    end

    assert_equal "test_logger", Sidekiq::MemoryLogger.logger
    assert_equal "test_callback", Sidekiq::MemoryLogger.callback
  end
end
