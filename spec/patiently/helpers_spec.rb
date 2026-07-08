# frozen_string_literal: true

describe Patiently::Helpers do
  # A minimal host object that mixes in the helpers, like a feature spec would.
  let(:host) { Class.new { include Patiently::Helpers }.new }

  # Keep the suite fast: no real sleeping unless a test opts in.
  before { allow(host).to receive(:sleep) }

  describe "#patiently" do
    it "returns the block's value when it succeeds on the first try" do
      expect(host.patiently { 42 }).to eq(42)
    end

    it "does not retry a block that succeeds" do
      calls = 0
      host.patiently { calls += 1 }
      expect(calls).to eq(1)
    end

    it "retries on exception until the block succeeds and returns its value" do
      attempts = 0
      result = host.patiently do
        attempts += 1
        raise "not yet" if attempts < 3

        :done
      end

      expect(attempts).to eq(3)
      expect(result).to eq(:done)
    end

    it "retries on non-StandardError exceptions (e.g. RSpec expectation failures)" do
      attempts = 0
      host.patiently do
        attempts += 1
        raise RSpec::Expectations::ExpectationNotMetError, "nope" if attempts < 2
      end

      expect(attempts).to eq(2)
    end

    it "re-raises the block's exception once the timeout and min_retries are exhausted" do
      Patiently.config.timeout = 0.1
      Patiently.config.retry_intervals = 0
      allow(host).to receive(:sleep).and_call_original

      expect { host.patiently { raise "boom" } }.to raise_error("boom")
    end

    describe "min_retries" do
      it "retries at least min_retries times before giving up, even after the timeout" do
        Patiently.config.timeout = 0 # timeout elapses immediately
        Patiently.config.min_retries = 3

        attempts = 0
        expect do
          host.patiently do
            attempts += 1
            raise "boom"
          end
        end.to raise_error("boom")

        # first call + 3 retries
        expect(attempts).to eq(4)
      end
    end

    describe "max_retries" do
      it "gives up after max_retries even if the timeout has not elapsed" do
        Patiently.config.timeout = 100 # never times out
        Patiently.config.max_retries = 2

        attempts = 0
        expect do
          host.patiently do
            attempts += 1
            raise "boom"
          end
        end.to raise_error("boom")

        # first call + 2 retries
        expect(attempts).to eq(3)
      end

      it "retries forever (until success) when max_retries is nil" do
        Patiently.config.timeout = 100
        Patiently.config.max_retries = nil

        attempts = 0
        host.patiently do
          attempts += 1
          raise "boom" if attempts < 25
        end

        expect(attempts).to eq(25)
      end
    end

    describe "retry intervals / backoff" do
      it "sleeps according to the configured backoff array, reusing the last value" do
        Patiently.config.timeout = 100
        Patiently.config.retry_intervals = [0.1, 0.2, 0.3]

        slept = []
        allow(host).to receive(:sleep) { |seconds| slept << seconds }

        attempts = 0
        host.patiently do
          attempts += 1
          raise "boom" if attempts < 5 # 4 retries
        end

        expect(slept).to eq([0.1, 0.2, 0.3, 0.3])
      end
    end

    describe "custom timeout argument" do
      it "overrides the configured timeout" do
        Patiently.config.timeout = 100
        Patiently.config.retry_intervals = 0
        allow(host).to receive(:sleep).and_call_original

        expect { host.patiently(0.05) { raise "boom" } }.to raise_error("boom")
      end

      it "honors a positional timeout of 0 instead of falling back to the default" do
        # Guards against `timeout ||= config.timeout` swallowing a truthy 0.
        Patiently.config.timeout = 100 # would loop far longer if 0 were replaced

        attempts = 0
        expect do
          host.patiently(0) do
            attempts += 1
            raise "boom"
          end
        end.to raise_error("boom")

        # first call + min_retries(1)
        expect(attempts).to eq(2)
      end
    end

    describe "frozen-in-time detection" do
      it "raises Patiently::FrozenInTime when the monotonic clock never advances" do
        allow(host).to receive(:monotonic_time).and_return(123.0)

        expect do
          host.patiently { raise "boom" }
        end.to raise_error(Patiently::FrozenInTime, /frozen/)
      end
    end

    describe "nested blocks" do
      it "only retries the outer block; the inner block runs once per outer attempt" do
        Patiently.config.timeout = 100
        outer = 0
        inner = 0

        host.patiently do
          outer += 1
          host.patiently do
            inner += 1
            raise "boom" if outer < 3
          end
        end

        expect(outer).to eq(3)
        expect(inner).to eq(3) # not retried independently
      end

      it "resets the nesting flag so a later patiently call still retries" do
        host.patiently { :ok }

        attempts = 0
        host.patiently do
          attempts += 1
          raise "boom" if attempts < 2
        end

        expect(attempts).to eq(2)
      end
    end
  end

  describe "#patiently_until" do
    it "returns true once the block becomes truthy" do
      attempts = 0
      result = host.patiently_until do
        attempts += 1
        attempts >= 3
      end

      expect(result).to be(true)
      expect(attempts).to eq(3)
    end

    it "returns false when the block stays falsey until the timeout" do
      Patiently.config.timeout = 0.1
      Patiently.config.retry_intervals = 0
      allow(host).to receive(:sleep).and_call_original

      expect(host.patiently_until { false }).to be(false)
    end

    it "lets a real exception propagate instead of returning false" do
      Patiently.config.timeout = 0.1
      Patiently.config.retry_intervals = 0
      allow(host).to receive(:sleep).and_call_original

      expect { host.patiently_until { raise "real error" } }.to raise_error("real error")
    end

    it "accepts a custom timeout" do
      Patiently.config.timeout = 100
      Patiently.config.retry_intervals = 0
      allow(host).to receive(:sleep).and_call_original

      expect(host.patiently_until(0.05) { false }).to be(false)
    end

    it "is aliased as patiently_wait_until" do
      expect(host.patiently_wait_until { true }).to be(true)
    end
  end
end
