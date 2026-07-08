# frozen_string_literal: true

module Patiently
  # Base class for all errors raised by Patiently.
  class Error < StandardError; end

  # Raised when the (monotonic) clock does not advance between retries, which
  # usually means time has been mocked/frozen (e.g. via Timecop or Rails'
  # `travel`/`freeze_time`). Retrying against a frozen clock would loop forever,
  # so we fail loudly instead.
  class FrozenInTime < Error; end
end
