# frozen_string_literal: true

require_relative "../patiently"

# Convenience integration for RSpec: makes `patiently` and `patiently_until`
# available in feature and system specs (both drive a browser and need retries).
# If you want a different scope, skip this file and call
# `config.include(Patiently::Helpers, ...)` yourself.
RSpec.configure do |config|
  config.include(Patiently::Helpers, type: :feature)
  config.include(Patiently::Helpers, type: :system)
end
