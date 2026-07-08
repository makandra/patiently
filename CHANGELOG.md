# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Added

- Initial extraction of the `patiently` / `patiently_until` test helpers into a
  standalone, dependency-free gem.
- `include Patiently::Helpers` to gain the `patiently` and `patiently_until`
  helpers (`patiently_wait_until` is kept as an alias).
- Configurable defaults via `Patiently.config`: `timeout`, `retry_intervals`
  (with backoff), `min_retries` and `max_retries`.
- Per-call timeout argument for both `patiently` and `patiently_until`.
- `Patiently::FrozenInTime` error raised when the monotonic clock does not
  advance between retries (mocked/frozen time).
- Optional RSpec integration via `require "patiently/rspec"`.
