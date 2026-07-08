# AGENTS.md

Conventions for working on the `patiently` gem. Read this before changing code,
dependencies, or CI.

## What this gem is

`patiently` retries a block until it stops raising (`patiently`) or returns
truthy (`patiently_until`, alias `patiently_wait_until`). It was extracted from a
`spec/support/patiently.rb` helper that used to be copy-pasted into many test
suites.

## Hard rules

- **No runtime dependencies.** Do not add RSpec, Capybara, Rails or
  ActiveSupport as a runtime dependency. The gem must work in any Ruby project.
  RSpec/Capybara are dev-only (for the self-tests).
- **Ruby >= 2.7.** Keep the code compatible with 2.7 syntax. `required_ruby_version`
  in the gemspec is the source of truth.
- **Ask before committing** (repo-wide preference).

## Ruby versions & the lockfile

- `.ruby-version` pins **2.7.8** (our support floor). Locally you can use any
  Ruby (`rbenv shell 2.7.8`, or just your default 3.x) — both are expected to pass.
- CI (`.github/workflows/test.yml`) runs a **matrix** across 2.7 / 3.0 / 3.2 / 3.4
  and `head`. We do NOT use gemika/appraisals — one `Gemfile`, one `Gemfile.lock`.
- `Gemfile.lock` **is committed** and was generated under **Ruby 2.7.8 with
  bundler 2.1.4** so `BUNDLED WITH` stays readable on every matrix Ruby. If you
  change dependencies, regenerate the lock under the oldest supported Ruby:
  `RBENV_VERSION=2.7.8 bundle _2.1.4_ install` — otherwise a newer bundler pin
  breaks the 2.7 CI job.

## Running tests

```bash
bundle exec rspec        # or: bundle exec rake spec  (the CI entrypoint)
```

Testing notes:
- Time-freeze detection is tested by **stubbing the private `monotonic_time`**
  helper, not by mocking `Time`/`Process.clock_gettime` globally.
- Some examples wait **real** (sub-second) time on purpose; that is acceptable
  here. Keep any real waits well under a second and stub `sleep` where timing
  isn't the thing under test.
- Keep the suite dependency-light: no embedded Rails app, no nested RSpec runs.

## Public API & semantics (don't break without a version bump)

- Mix in with `include Patiently::Helpers`.
- Config lives on `Patiently.config` (`timeout`, `retry_intervals`,
  `min_retries`, `max_retries`) or `Patiently.configure { |c| ... }`.
- `min_retries` / `max_retries` count **re-attempts** (invocations after the
  first). `min_retries = 1` reproduces the original "try at least twice"
  behavior. `max_retries = nil` means unlimited.
- `retry_intervals` is a backoff array; the last element is reused once exhausted.
- Errors: `Patiently::Error` (base) and `Patiently::FrozenInTime`. Do NOT reach
  for Capybara's error classes.
- Optional RSpec glue is `require "patiently/rspec"` — keep it a thin
  `config.include(Patiently::Helpers, type: :feature)` and nothing more.

## Packaging (house style, mirrors capybara-lockstep)

The gemspec ships **every tracked file except `spec/`, `test/`, `features/`** —
so `Gemfile`, `Gemfile.lock`, `.github/`, the gemspec and `bin/` are included in
the published `.gem` on purpose. `.gitignore` keeps IDE/build cruft (`.idea`,
`tmp/`, `pkg/`, `.rspec_status`) out of git and therefore out of the gem.
