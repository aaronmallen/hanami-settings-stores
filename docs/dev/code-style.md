# Code Style

This document describes the formatting and organization conventions used in hanami-settings-stores. Most formatting is
handled automatically by tools — you generally just need to run `mise run format` before committing.

The code organization rules (class structure, method ordering) are the main things to keep in mind when writing new
code.

## Running Formatters and Linters

```bash
mise run format       # Format all files
mise run lint         # Lint all files
```

## Formatting Rules

Code formatting is enforced using [RuboCop](https://rubocop.org). Configuration is in `.config/.rubocop.yml`, which
inherits from a shared base config. General formatting rules are enforced by [EditorConfig](https://editorconfig.org)
via `.editorconfig`.

| Setting                | Value | Source       | Description               |
|------------------------|-------|--------------|---------------------------|
| `max_line_length`      | 120   | EditorConfig | Maximum line width        |
| `indent_size`          | 2     | EditorConfig | Spaces per indentation    |
| `indent_style`         | space | EditorConfig | Spaces, not tabs          |
| `charset`              | utf-8 | EditorConfig | File encoding             |
| `end_of_line`          | lf    | EditorConfig | Unix-style line endings   |
| `insert_final_newline` | true  | EditorConfig | Trailing newline required |

## Linting

Code is linted using RuboCop with the `rubocop-rspec` and `rubocop-ordered_methods` plugins. Markdown is linted with
`markdownlint-cli2` and all files are checked against EditorConfig rules. All lints must pass without offenses.

## Code Organization

### Class-Level Ordering

Order items within a class by:

1. **Constants**: All constant declarations first
2. **Class methods**: Public class methods, then private class methods (alphabetically within each group)
3. **Initialization**: `initialize` method
4. **Public instance methods**: Alphabetically ordered
5. **Private instance methods**: Alphabetically ordered, after the `private` keyword

```ruby
class MyStore
  # 1. Constants
  DEFAULT_TIMEOUT = 30
  MAX_RETRIES = 3

  # 2. Class methods - public
  def self.build(config)
  end

  def self.default
  end

  # 3. Initialization
  def initialize(timeout: DEFAULT_TIMEOUT)
    @timeout = timeout
  end

  # 4. Public instance methods (alphabetical)
  def fetch(key, *args)
  end

  def store(key, value)
  end

  private

  # 5. Private instance methods (alphabetical)
  def normalize_key(key)
  end

  def validate!(key)
  end
end
```

### Module Ordering

When a class includes or extends modules, order them at the top of the class body before constants:

1. **`extend`** declarations
2. **`include`** declarations
3. **`prepend`** declarations

### Method Ordering

Method ordering is enforced by the `rubocop-ordered_methods` plugin. Methods within each visibility group (public,
private, protected) should be ordered **alphabetically**, with the exception of `initialize` which always comes first
among public instance methods.

In test files, fall back to describing methods in the order they appear in the source. See [testing][testing] for
test-specific conventions.

[testing]: testing.md
