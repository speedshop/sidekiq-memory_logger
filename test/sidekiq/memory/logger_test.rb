# frozen_string_literal: true

require "test_helper"

class TestSidekiqMemoryLogger < Minitest::Test
  def setup
    Sidekiq::Memory::Logger.reset!
  end

  def test_that_it_has_a_version_number
    refute_nil ::Sidekiq::Memory::Logger::VERSION
  end

  def test_configuration
    Sidekiq::Memory::Logger.configure do |config|
      config.logger = "test_logger"
      config.callback = "test_callback"
    end

    assert_equal "test_logger", Sidekiq::Memory::Logger.logger
    assert_equal "test_callback", Sidekiq::Memory::Logger.callback
  end

  def test_reset
    Sidekiq::Memory::Logger.logger = "test"
    Sidekiq::Memory::Logger.callback = "test"
    
    Sidekiq::Memory::Logger.reset!
    
    assert_nil Sidekiq::Memory::Logger.logger
    assert_nil Sidekiq::Memory::Logger.callback
  end
end