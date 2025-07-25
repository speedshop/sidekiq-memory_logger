# frozen_string_literal: true

require "test_helper"

class TestSidekiqMemoryLoggerConfiguration < Minitest::Test
  def setup
    @config = Sidekiq::MemoryLogger::Configuration.new
  end

  def test_default_values
    refute_nil @config.logger
    assert_kind_of Logger, @config.logger
    assert_nil @config.callback
  end

  def test_setting_logger
    logger = "test_logger"
    @config.logger = logger
    assert_equal logger, @config.logger
  end

  def test_setting_callback
    callback = ->(job, queue, memory) { "test" }
    @config.callback = callback
    assert_equal callback, @config.callback
  end
end
