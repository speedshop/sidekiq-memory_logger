# frozen_string_literal: true

module RuboCop
  module Cop
    module SidekiqMemoryLogger
      class NoConfigureInTests < Base
        MSG = "Do not use Sidekiq::MemoryLogger.configure in test files. Use Configuration objects instead."

        def on_send(node)
          return unless in_test_file?

          if sidekiq_memory_logger_configure?(node)
            add_offense(node)
          end
        end

        private

        def in_test_file?
          processed_source.path.match?(%r{test/.*\.rb\z})
        end

        def sidekiq_memory_logger_configure?(node)
          node.send_type? &&
            node.receiver&.const_type? &&
            node.receiver.const_name == "Sidekiq::MemoryLogger" &&
            node.method_name == :configure
        end
      end
    end
  end
end
