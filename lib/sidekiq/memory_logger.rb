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
        @callback = default_callback
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

      def default_callback
        ->(job_class, queue, memory_diff_mb) do
          @logger.info("Job #{job_class} on queue #{queue} used #{memory_diff_mb} MB")
        end
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

          begin
            @config.callback.call(job["class"], queue, memory_diff)
          rescue => e
            @config.logger.error("Sidekiq memory logger callback failed: #{e.message}")
          end
        end
      end
    end
  end
end
