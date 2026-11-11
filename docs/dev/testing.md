# Testing

This guide covers how to write and organize tests in hanami-settings-stores. Tests live in the `spec/` directory,
mirroring the structure of `lib/`.

The goal is to test meaningful behavior without over-testing trivial code. When in doubt, focus on logic that could
break — transformations, edge cases, and error handling.

## Running Tests

```bash
mise run spec                        # Run all tests with coverage
bundle exec rspec --tag focus        # Run only focused tests
bundle exec rspec spec/path/to_spec  # Run a specific file
```

## What to Test

**Test:**

- Methods with logic (conditionals, iteration, transformations)
- Error handling and edge cases
- Fallback behavior and delegation
- Public API contracts

**Skip:**

- Simple attribute readers
- Trivial delegations with no logic
- Private methods directly (test them through public methods)

Before writing a test, ask: "Does this test verify actual logic, or just that Ruby's attribute access works?"

## Test Structure

Tests are organized using RSpec's `describe` and `context` blocks:

```ruby
# frozen_string_literal: true

RSpec.describe Hanami::Settings::CompositeStore do
  subject(:store) { described_class.new(*stores) }

  let(:stores) { [primary, fallback] }
  let(:primary) { { database_url: "postgres://localhost/myapp" } }
  let(:fallback) { { session_secret: "supersecret" } }

  describe "#fetch" do
    it "returns the value from the first store that has the key" do
      expect(store.fetch(:database_url)).to eq("postgres://localhost/myapp")
    end

    it "falls back to subsequent stores when the key is missing" do
      expect(store.fetch(:session_secret)).to eq("supersecret")
    end
  end
end
```

## Conventions

**Naming:** Test descriptions use the pattern `it "<does something>"`. Use `describe "#method_name"` for instance
methods and `describe ".method_name"` for class methods.

**Ordering:** Describe methods in the order they appear in the source class. Within a `describe` block, order
`context` blocks from the happy path to edge cases.

**Test body structure:** Use `subject` and `let` for setup. Separate setup from assertions with a blank line when
inline setup is needed:

```ruby
it "handles the edge case" do
  store = described_class.new(empty_store)

  expect { store.fetch(:missing) }.to raise_error(KeyError)
end
```

**Matchers:** Prefer specific matchers over generic ones:

```ruby
# Preferred
expect(result).to eq("value")
expect { action }.to raise_error(KeyError, /missing/)

# Avoid
expect(result == "value").to be true
```

**Shared examples:** Use shared examples for behavior common across multiple classes, but don't over-abstract. If a
shared example only applies to two specs, inline the tests instead.
