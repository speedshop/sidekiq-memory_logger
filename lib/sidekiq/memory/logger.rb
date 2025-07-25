# frozen_string_literal: true

require "get_process_mem"
require "sidekiq"
require_relative "logger/version"

if defined?(Rails)
  require_relative "logger/railtie"
end

module Sidekiq
  module Memory
    module Logger
      class Error < StandardError; end

      class << self
        attr_accessor :callback, :logger

        def configure
          yield self
        end

        def reset!
          @callback = nil
          @logger = nil
        end
      end

      class Middleware
        def call(worker_instance, job, queue)
          start_mem = GetProcessMem.new.mb

          begin
            yield
          ensure
            end_mem = GetProcessMem.new.mb
            memory_diff = end_mem - start_mem

            if Logger.callback
              Logger.callback.call(job["class"], queue, memory_diff)
            else
              logger = Logger.logger || default_logger
              logger.info("Job #{job["class"]} on queue #{queue} used #{memory_diff} MB")
            end
          end
        end

        private

        def default_logger
          if defined?(Rails)
            Rails.logger
          else
            require "logger"
            ::Logger.new($stdout)
          end
        end
      end
    end
  end
end
