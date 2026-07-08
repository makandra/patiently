# frozen_string_literal: true

require_relative "lib/patiently/version"

Gem::Specification.new do |spec|
  spec.name = "patiently"
  spec.version = Patiently::VERSION
  spec.authors = ["Henning Koch"]
  spec.email = ["henning.koch@makandra.de"]

  spec.summary = "Retry a block until it stops raising (or returns truthy)"
  spec.description = "Patiently retries a block of code until it stops raising an exception " \
                     "or returns a truthy value, useful for waiting on eventually-consistent " \
                     "conditions in tests. Has no runtime dependencies."
  spec.homepage = "https://github.com/makandra/patiently"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  # Mirrors capybara-lockstep: ship everything tracked except the test suite.
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      f.match(%r{\A(?:test|spec|features)/})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
