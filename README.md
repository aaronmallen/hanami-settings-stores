# Hanami::Settings::Stores

Pluggable settings stores for [Hanami](https://hanamirb.org).

Fetch settings from password managers like 1Password and Bitwarden, or from a local JSON, TOML, or
YAML file.

## Requirements

- [1Password CLI (`op`)](https://developer.1password.com/docs/cli/get-started/) for `OnePasswordStore`
- [Bitwarden CLI (`bw`)](https://bitwarden.com/help/cli/) for `BitwardenStore`

`CompositeStore` and `FileStore` need nothing beyond the gem.

## Installation

### Using Gem.coop

Add to your Gemfile:

```ruby
gem "hanami-settings-stores", source: "https://beta.gem.coop/@aaron"
```

### Using Rubygems

Add to your Gemfile:

```ruby
gem "hanami-settings-stores", source: "https://rubygems.org"
```

## Usage

### OnePasswordStore

```ruby
# config/app.rb

require "hanami-settings-stores"

module MyApp
  class App < Hanami::App
    config.settings_store = Hanami::Settings::CompositeStore.new(
      Hanami::Settings::EnvStore.new,
      Hanami::Settings::OnePasswordStore.new(vault: "Production")
    )
  end
end
```

Fetch settings from 1Password items. Define mappings with `op_setting` in your settings class:

```ruby
# config/settings.rb

module MyApp
  class Settings < Hanami::Settings
    # Looks up field "database_url" on item "MyApp"
    op_setting :database_url, item: "MyApp", constructor: Types::String

    # Looks up field "secret_key" on a different item
    op_setting :api_key, item: "ExternalService", key: :secret_key, constructor: Types::String

    # Regular settings still work — these come from ENV via the default store
    setting :some_flag, default: false, constructor: Types::Params::Bool
  end
end
```

### BitwardenStore

```ruby
# config/app.rb

require "hanami-settings-stores"

module MyApp
  class App < Hanami::App
    config.settings_store = Hanami::Settings::CompositeStore.new(
      Hanami::Settings::EnvStore.new,
      Hanami::Settings::BitwardenStore.new
    )
  end
end
```

Fetch settings from Bitwarden items. Define mappings with `bw_setting` in your settings class:

```ruby
# config/settings.rb

module MyApp
  class Settings < Hanami::Settings
    bw_setting :database_url, item: "MyApp", constructor: Types::String
    bw_setting :api_key, item: "ExternalService", key: :secret_key, constructor: Types::String

    setting :some_flag, default: false, constructor: Types::Params::Bool
  end
end
```

### FileStore

```ruby
# config/app.rb

require "hanami-settings-stores"

module MyApp
  class App < Hanami::App
    config.settings_store = Hanami::Settings::CompositeStore.new(
      Hanami::Settings::EnvStore.new,
      Hanami::Settings::FileStore.new("config/settings.yml")
    )
  end
end
```

Read settings from a local JSON, TOML, or YAML file. Name the file with a `.json`, `.toml`, `.yaml`,
or `.yml` extension so the store knows how to parse it:

```yaml
# config/settings.yml

database_url: postgres://localhost/myapp
session_secret: <%= ENV.fetch("SESSION_SECRET") %>
pool_size: 5
```

```ruby
# config/settings.rb

module MyApp
  class Settings < Hanami::Settings
    setting :database_url, constructor: Types::String
    setting :session_secret, constructor: Types::String
    setting :pool_size, constructor: Types::Params::Integer
  end
end
```

Settings match file keys by name, so `:database_url` reads the `database_url` key. Only top level
keys resolve; nested values come back whole, as a hash with symbol keys.

The file runs through ERB before parsing, so it can read from ENV or call Ruby. This also means the
file can run any code it contains. Keep it under your own control, and keep real secrets in ENV or a
password manager store.

The store reads and parses the file once, on the first fetch, then memoizes it. Later edits to the
file need a restart.

Because the file is parsed rather than read as text, values keep their types: `pool_size` above
arrives as the integer `5`, not `"5"`. YAML files are parsed in safe mode, with `Date`, `DateTime`,
`Symbol`, and `Time` permitted, and aliases enabled:

```yaml
# config/settings.yml

adapter: :postgres
launched_on: 2026-01-01
expires_at: 2026-01-01 12:30:00
```

A file that does not exist, or that is empty, gives an empty store, so an optional file can sit in a
`CompositeStore` without a guard. A file that parses to something other than a mapping raises a
`TypeError`.

Pass a block instead of a path to resolve the path lazily, on the first fetch — useful when the path
depends on config that is not yet set when the store is built:

```ruby
config.settings_store = Hanami::Settings::CompositeStore.new(
  Hanami::Settings::EnvStore.new,
  Hanami::Settings::FileStore.new { Hanami.app.root.join("config/settings/#{Hanami.env}.yml") },
  Hanami::Settings::FileStore.new { Hanami.app.root.join("config/settings/default.yml") }
)
```

### CompositeStore

Chain multiple stores with fallback resolution. The first store to return a value wins.
Settings resolve from ENV first, falling back to another store for anything not found.

## Stores

| Store              | Status    |
|--------------------|-----------|
| `CompositeStore`   | Available |
| `FileStore`        | Available |
| `OnePasswordStore` | Available |
| `BitwardenStore`   | Available |

## Development

```sh
bundle install
mise run spec
mise run ruby
```

## License

[MIT](LICENSE)
