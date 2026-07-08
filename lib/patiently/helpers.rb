# frozen_string_literal: true

module Patiently
  # Mix this into a class (or configure RSpec to include it) to gain the
  # {#patiently} and {#patiently_until} helpers:
  #
  #   include Patiently::Helpers
  module Helpers
    # Thread-local flag marking that we are already inside a `patiently` block.
    # Nested blocks are run once and let the *outer* block do the retrying.
    IN_PATIENTLY = :patiently_in_progress

    # Internal sentinel used by {#patiently_until} to signal "not truthy yet".
    RetryUntilTrue = Class.new(StandardError)

    # Runs `block`, retrying it whenever it raises, until it succeeds or the
    # patience window (timeout + min/max retries) is exhausted. Returns the
    # block's return value on success; re-raises the last exception on failure.
    #
    # When called while another `patiently` block is already running on the
    # current thread, the block is simply run once: only the outermost block is
    # retried.
    #
    # @param timeout [Numeric, nil] overrides +Patiently.config.timeout+
    # rubocop:disable Lint/RescueException
    def patiently(timeout = nil, &block)
      return block.call if Thread.current[IN_PATIENTLY]

      config = Patiently.config
      timeout ||= config.timeout
      started_at = monotonic_time
      retries = 0

      begin
        Thread.current[IN_PATIENTLY] = true
        attempt_started_at = monotonic_time
        block.call
      rescue Exception => e
        elapsed = attempt_started_at - started_at
        timed_out = elapsed > timeout && retries >= config.min_retries
        retries_exhausted = config.max_retries && retries >= config.max_retries
        raise e if timed_out || retries_exhausted

        sleep(config.retry_interval(retries))

        if monotonic_time == started_at
          raise Patiently::FrozenInTime, "time appears to be frozen, consider time travelling instead"
        end

        retries += 1
        retry
      ensure
        Thread.current[IN_PATIENTLY] = false
      end
    end
    # rubocop:enable Lint/RescueException

    # Retries `block` until it returns a truthy value or the patience window
    # elapses, then returns the final result as a boolean.
    #
    # Because `patiently` only retries on a *raise*, we raise an internal
    # sentinel while the block is falsey and translate a timed-out sentinel back
    # into `false`. A real exception inside the block is not the sentinel, so it
    # still propagates.
    #
    # @param timeout [Numeric, nil] overrides +Patiently.config.timeout+
    def patiently_until(timeout = nil, &block)
      patiently(timeout) { block.call || raise(RetryUntilTrue) }
      true
    rescue RetryUntilTrue
      false
    end
    alias patiently_wait_until patiently_until

    private

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
