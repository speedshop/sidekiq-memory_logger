# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sidekiq/memory_logger"

require "minitest/autorun"
