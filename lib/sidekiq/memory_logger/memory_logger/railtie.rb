# frozen_string_literal: true

module Sidekiq
  module MemoryLogger
    class Railtie < Rails::Railtie
      initializer "sidekiq_memory_logger.configure_rails_logger" do
        Sidekiq::MemoryLogger.logger = Rails.logger if defined?(Rails.logger)
      end
    end
  end
end
