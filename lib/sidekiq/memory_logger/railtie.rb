# frozen_string_literal: true

module Sidekiq
  module MemoryLogger
    class Railtie < Rails::Railtie
      # Configuration is now handled automatically by the Configuration class
      # No initializer needed since Configuration sets the default logger during initialization
    end
  end
end
