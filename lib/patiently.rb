# frozen_string_literal: true

require_relative "patiently/version"
require_relative "patiently/errors"
require_relative "patiently/configuration"
require_relative "patiently/helpers"

module Patiently
  class << self
    # The global configuration object. See Patiently::Configuration.
    def config
      @config ||= Configuration.new
    end

    # Yields the configuration object for block-style setup:
    #
    #   Patiently.configure do |config|
    #     config.timeout = 10
    #   end
    def configure
      yield config
    end
  end
end
