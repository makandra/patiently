# frozen_string_literal: true

require_relative "../patiently"

# Convenience integration for RSpec: makes `patiently` and `patiently_until`
# available in feature specs. If you want a different scope, skip this file and
# call `config.include(Patiently::Helpers, ...)` yourself.
RSpec.configure do |config|
  config.include(Patiently::Helpers, type: :feature)
end
