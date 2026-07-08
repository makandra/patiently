<p>
  <a href="https://makandra.de/">
    <picture>
      <source media="(prefers-color-scheme: light)" srcset="media/makandra-with-bottom-margin.light.svg">
      <source media="(prefers-color-scheme: dark)" srcset="media/makandra-with-bottom-margin.dark.svg">
      <img align="right" width="25%" alt="makandra" src="media/makandra-with-bottom-margin.light.svg">
    </picture>
  </a>

  <picture>
    <source media="(prefers-color-scheme: light)" srcset="media/logo.light.shapes.svg">
    <source media="(prefers-color-scheme: dark)" srcset="media/logo.dark.shapes.svg">
    <img width="200" alt="patiently" role="heading" aria-level="1" src="media/logo.light.shapes.svg">
  </picture>
</p>

`patiently` retries a block of code until it stops raising an exception (or
returns a truthy value). It is most useful in tests that need to wait for an
eventually-consistent condition — a background job to finish, an AJAX request to
update the DOM, a file to appear — without sprinkling `sleep` calls everywhere.

It has **no runtime dependencies**: it does not require RSpec, Capybara, Rails or
ActiveSupport.

## Installation

Add it to your `Gemfile` and run `bundle install`:

```ruby
gem "patiently"
```

Patiently does not depend on RSpec, but if you use it, wire the helpers into your
specs. Either require the bundled integration, which includes the helpers into
feature and system specs:

```ruby
# spec/spec_helper.rb (or rails_helper.rb)
require "patiently/rspec"
```

or include the helpers yourself with whatever scope you like:

```ruby
RSpec.configure do |config|
  config.include(Patiently::Helpers, type: :feature)
  config.include(Patiently::Helpers, type: :system)
end
```

## Usage

Mix the helpers into any class:

```ruby
include Patiently::Helpers
```

This gives you two methods.

### `patiently`

Runs the block and, if it raises, keeps retrying until it succeeds or the
patience window is exhausted. On success it returns the block's value; on failure
it re-raises the block's last exception.

```ruby
patiently do
  expect(page).to have_content("Saved!")
end
```

`patiently` retries on **any** exception (including non-`StandardError`s such as
RSpec's `ExpectationNotMetError`), which is what makes it work with test
assertions.

You can pass a custom timeout (in seconds) as the first argument, overriding the
global default:

```ruby
patiently(10) do
  expect(page).to have_content("Slow import finished")
end
```

### `patiently_until`

Retries the block until it returns a truthy value, then returns `true`. If the
block is still falsey when the window elapses, it returns `false`. A *real*
exception raised inside the block still propagates.

```ruby
patiently_until { user.reload.confirmed? } # => true / false
```

This is handy for building custom matchers that retry internally while keeping
their own failure message. It also accepts a custom timeout:

```ruby
patiently_until(10) { import.reload.done? }
```

`patiently_wait_until` is available as an alias for `patiently_until`.

### Nested blocks

When you call `patiently` (or `patiently_until`) while already inside a
`patiently` block on the same thread, the inner block simply runs once — only the
**outermost** block is retried. This prevents an inner retry loop from repeatedly
re-running expensive setup and lets the outer block drive the timing.

## Configuration

Configure global defaults via `Patiently.config`:

```ruby
Patiently.config.timeout = 5              # seconds before giving up
Patiently.config.retry_intervals = [0.05] # sleep durations between retries
Patiently.config.min_retries = 1          # always retry at least this often
Patiently.config.max_retries = nil        # cap on retries (nil = unlimited)
```

Or use a block:

```ruby
Patiently.configure do |config|
  config.timeout = 10
end
```

| Option            | Default  | Meaning |
| ----------------- | -------- | ------- |
| `timeout`         | `5`      | How long (in seconds) to keep retrying before giving up. |
| `retry_intervals` | `[0.05]` | Sleep durations (seconds) between retries. See "Backoff" below. |
| `min_retries`     | `1`      | The minimum number of *retries* performed before giving up, even if the timeout has already elapsed. |
| `max_retries`     | `nil`    | The maximum number of *retries* before giving up, regardless of the timeout. `nil` means unlimited. |

Both `min_retries` and `max_retries` count **retries** — re-invocations *after*
the first call. So `min_retries = 1` means the block runs at least twice before
`patiently` is allowed to give up.

`patiently` gives up (and re-raises the block's exception) when either:

- the timeout has elapsed **and** at least `min_retries` retries have happened, or
- `max_retries` retries have happened (when `max_retries` is set).

### Backoff

`retry_intervals` may be an array, used as a backoff schedule. The value at index
N is the sleep before the (N+1)-th retry; once the array is exhausted, its last
element is reused for all further retries:

```ruby
Patiently.config.retry_intervals = [0.05, 0.05, 0.05, 0.1]
# sleeps 0.05, 0.05, 0.05, then 0.1, 0.1, 0.1, ...
```

## Frozen time detection

If the monotonic clock does not advance between retries — which usually means time
has been mocked or frozen (Timecop, Rails' `travel`/`freeze_time`, …) —
`patiently` would loop forever. Instead it raises `Patiently::FrozenInTime` so you
notice and travel time explicitly.

## Errors

- `Patiently::Error` — base class for all errors raised by this gem.
- `Patiently::FrozenInTime` — raised when time appears to be frozen (see above).

## Development

After checking out the repo, run `bin/setup` to install dependencies, then run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt.

To release a new version, update the version number in
`lib/patiently/version.rb`, then run `bundle exec rake release`.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/makandra/patiently.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
