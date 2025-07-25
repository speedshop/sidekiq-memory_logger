# frozen_string_literal: true

require_relative "lib/sidekiq/memory_logger/memory_logger/version"

Gem::Specification.new do |spec|
  spec.name = "sidekiq-memory-logger"
  spec.version = Sidekiq::MemoryLogger::VERSION
  spec.authors = ["Nate Berkopec"]
  spec.email = ["nate.berkopec@gmail.com"]

  spec.summary = "Sidekiq server middleware for logging memory usage per job"
  spec.description = "A Sidekiq server middleware that tracks RSS memory usage for each job and provides configurable logging and reporting options"
  spec.homepage = "https://github.com/speedshop/sidekiq-memory_logger"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/speedshop/sidekiq-memory_logger"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "get_process_mem"
  spec.add_dependency "sidekiq"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
