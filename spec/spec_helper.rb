# frozen_string_literal: true

require "patiently"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Expose the DSL globally so specs can use bare `describe` instead of `RSpec.describe`.
  config.expose_dsl_globally = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Every example starts from pristine defaults.
  config.before do
    Patiently.config.reset!
  end
end
