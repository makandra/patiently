# frozen_string_literal: true

module Patiently
  # Holds the global defaults for {Patiently::Helpers#patiently}. Access the
  # shared instance via +Patiently.config+.
  class Configuration
    DEFAULT_TIMEOUT = 5
    DEFAULT_RETRY_INTERVALS = [0.05].freeze
    DEFAULT_MIN_RETRIES = 1
    DEFAULT_MAX_RETRIES = nil # nil = unlimited

    attr_writer :timeout, :retry_intervals, :min_retries, :max_retries

    def initialize
      reset!
    end

    # How long (in seconds) `patiently` keeps retrying before giving up.
    def timeout
      @timeout.nil? ? DEFAULT_TIMEOUT : @timeout
    end

    # An array of sleep durations (in seconds) used between retries. The value
    # at index N is used before the (N+1)-th retry; once the array is exhausted
    # its last element is reused for all further retries. This allows a backoff,
    # e.g. `[0.05, 0.05, 0.05, 0.1]`. A bare number is accepted and wrapped in
    # an array.
    def retry_intervals
      intervals = @retry_intervals.nil? ? DEFAULT_RETRY_INTERVALS : @retry_intervals
      Array(intervals)
    end

    # The minimum number of *retries* (re-invocations after the first call)
    # `patiently` performs before it is allowed to give up, even if the timeout
    # has already elapsed. `1` reproduces the historical "try at least twice"
    # behavior.
    def min_retries
      @min_retries.nil? ? DEFAULT_MIN_RETRIES : @min_retries
    end

    # The maximum number of *retries* `patiently` performs before giving up,
    # regardless of the timeout. `nil` means unlimited.
    def max_retries
      @max_retries
    end

    # Returns the sleep duration for the given (zero-based) retry index.
    def retry_interval(retry_index)
      intervals = retry_intervals
      intervals[retry_index] || intervals.last
    end

    # Restores all defaults. Handy in test suites.
    def reset!
      @timeout = nil
      @retry_intervals = nil
      @min_retries = nil
      @max_retries = nil
    end
  end
end
