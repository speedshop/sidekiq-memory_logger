# frozen_string_literal: true

module Sidekiq
  module Memory
    module Logger
      class Railtie < Rails::Railtie
        initializer "sidekiq_memory_logger.configure_rails_logger" do
          Sidekiq::Memory::Logger.logger = Rails.logger if defined?(Rails.logger)
        end
      end
    end
  end
end
