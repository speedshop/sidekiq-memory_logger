# frozen_string_literal: true

require "get_process_mem"
require "sidekiq"
require_relative "memory_logger/version"

module Sidekiq
  module MemoryLogger
    class Error < StandardError; end

    class Configuration
      attr_accessor :logger, :callback

      def initialize
        @logger = default_logger
        @callback = nil
      end

      private

      def default_logger
        rails_logger = defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
        rails_logger || fallback_logger
      end

      def fallback_logger
        require "logger"
        ::Logger.new($stdout)
      end
    end

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield configuration
      end
    end

    class Middleware
      include Sidekiq::ServerMiddleware

      def initialize
        @config = MemoryLogger.configuration
      end

      def call(worker_instance, job, queue)
        start_mem = GetProcessMem.new.mb

        begin
          yield
        ensure
          end_mem = GetProcessMem.new.mb
          memory_diff = end_mem - start_mem

          if @config.callback
            begin
              @config.callback.call(job["class"], queue, memory_diff)
            rescue => e
              @config.logger.error("Sidekiq memory logger callback failed: #{e.message}")
            end
          else
            @config.logger.info("Job #{job["class"]} on queue #{queue} used #{memory_diff} MB")
          end
        end
      end
    end
  end
end
