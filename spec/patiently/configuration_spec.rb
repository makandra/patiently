# frozen_string_literal: true

describe Patiently::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "defaults the timeout to 5 seconds" do
      expect(config.timeout).to eq(5)
    end

    it "defaults the retry intervals to [0.05]" do
      expect(config.retry_intervals).to eq([0.05])
    end

    it "defaults min_retries to 1" do
      expect(config.min_retries).to eq(1)
    end

    it "defaults max_retries to nil (unlimited)" do
      expect(config.max_retries).to be_nil
    end
  end

  describe "#retry_intervals" do
    it "wraps a bare number in an array" do
      config.retry_intervals = 0.2
      expect(config.retry_intervals).to eq([0.2])
    end

    it "accepts a backoff array" do
      config.retry_intervals = [0.05, 0.1, 0.2]
      expect(config.retry_intervals).to eq([0.05, 0.1, 0.2])
    end
  end

  describe "#retry_interval" do
    before { config.retry_intervals = [0.05, 0.1, 0.2] }

    it "returns the interval at the given retry index" do
      expect(config.retry_interval(0)).to eq(0.05)
      expect(config.retry_interval(1)).to eq(0.1)
      expect(config.retry_interval(2)).to eq(0.2)
    end

    it "reuses the last interval once the array is exhausted" do
      expect(config.retry_interval(3)).to eq(0.2)
      expect(config.retry_interval(99)).to eq(0.2)
    end
  end

  describe "#reset!" do
    it "restores every default" do
      config.timeout = 10
      config.retry_intervals = [1]
      config.min_retries = 5
      config.max_retries = 5

      config.reset!

      expect(config.timeout).to eq(5)
      expect(config.retry_intervals).to eq([0.05])
      expect(config.min_retries).to eq(1)
      expect(config.max_retries).to be_nil
    end
  end
end

describe Patiently do
  it "has a version number" do
    expect(Patiently::VERSION).not_to be_nil
  end

  describe ".config" do
    it "returns a memoized Configuration" do
      expect(Patiently.config).to be_a(Patiently::Configuration)
      expect(Patiently.config).to be(Patiently.config)
    end
  end

  describe ".configure" do
    it "yields the configuration for block-style setup" do
      Patiently.configure { |c| c.timeout = 42 }
      expect(Patiently.config.timeout).to eq(42)
    end
  end
end
