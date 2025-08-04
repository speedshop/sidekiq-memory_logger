# frozen_string_literal: true

require "get_process_mem"
require "sidekiq"
require_relative "memory_logger/version"

module Sidekiq
  module MemoryLogger
    class Error < StandardError; end

    class Configuration
      attr_accessor :logger, :callback, :queues

      def initialize
        @logger = default_logger
        @callback = default_callback
        @queues = []
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
        ->(job_class, queue, memory_diff_mb, objects_diff, args) do
          @logger.info("[MemoryLogger] job=#{job_class} queue=#{queue} memory_mb=#{memory_diff_mb} objects=#{objects_diff}")
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

      def initialize(config = nil)
        @memory_logger_config = config || MemoryLogger.configuration
      end

      def call(worker_instance, job, queue)
        return yield if should_skip_queue?(queue)

        start_mem = GetProcessMem.new.mb
        start_objects = GC.stat[:total_allocated_objects]

        begin
          yield
        ensure
          end_mem = GetProcessMem.new.mb
          end_objects = GC.stat[:total_allocated_objects]
          memory_diff = end_mem - start_mem
          objects_diff = end_objects - start_objects

          begin
            @memory_logger_config.callback.call(job["class"], queue, memory_diff, objects_diff, job["args"])
          rescue => e
            @memory_logger_config.logger.error("Sidekiq memory logger callback failed: #{e.message}")
          end
        end
      end

      private

      def should_skip_queue?(queue)
        return false if @memory_logger_config.queues.empty?
        !@memory_logger_config.queues.include?(queue)
      end
    end
  end
end
