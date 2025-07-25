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
        if defined?(Rails) && Rails.respond_to?(:logger)
          Rails.logger
        else
          require "logger"
          ::Logger.new($stdout)
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

      def callback
        configuration.callback
      end

      def logger
        configuration.logger
      end

      def callback=(value)
        configuration.callback = value
      end

      def logger=(value)
        configuration.logger = value
      end
    end

    class Middleware
      include Sidekiq::ServerMiddleware

      def call(worker_instance, job, queue)
        start_mem = GetProcessMem.new.mb

        begin
          yield
        ensure
          end_mem = GetProcessMem.new.mb
          memory_diff = end_mem - start_mem

          if MemoryLogger.callback
            MemoryLogger.callback.call(job["class"], queue, memory_diff)
          else
            MemoryLogger.logger.info("Job #{job["class"]} on queue #{queue} used #{memory_diff} MB")
          end
        end
      end
    end
  end
end
