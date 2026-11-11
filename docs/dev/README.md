# Contributing to hanami-settings-stores

Thank you for your interest in contributing to hanami-settings-stores. This guide will help you get started with
development.

By submitting a contribution, you acknowledge that you have read and agree to our [policies] and that your
contribution is licensed under the [MIT License][license].

## Ways to Contribute

- **Bug reports** — Found a problem? [Open an issue][issues] with steps to reproduce
- **Code** — Bug fixes, new stores, or improvements to existing ones
- **Documentation** — Typo fixes, better examples, or new guides
- **Testing** — Expand test coverage or improve existing specs
- **Security vulnerabilities** — Please report these privately per our [security policy][security]

## Quick Start

```bash
# Install mise (recommended)
curl https://mise.run | sh

# Install toolchain and run all checks
mise install
mise run lint

# Run tests
mise run spec

# Format and lint
mise run format
mise run lint
```

Without mise, run scripts directly from `bin/`:

```bash
./bin/spec
./bin/format/ruby
./bin/lint/ruby
```

## Development Workflow

1. Create a branch for your changes
2. Make your changes following the [code style guide][code-style]
3. Run `mise run lint` and `mise run spec` to verify everything passes
4. Submit a pull request

## Common Tasks

| Task   | Command           | Description      |
|--------|-------------------|------------------|
| Test   | `mise run spec`   | Run tests        |
| Format | `mise run format` | Format all files |
| Lint   | `mise run lint`   | Lint all files   |
| Build  | `mise run build`  | Build the gem    |

## Guides

| Guide                      | Topics                                 |
|----------------------------|----------------------------------------|
| [Development Tasks][tasks] | Available commands and toolchain       |
| [Code Style][code-style]   | Formatting, linting, code organization |
| [Testing][testing]         | Test structure and conventions         |

[code-style]: code-style.md
[issues]: https://aaronmallen.dev/aaron/hanami-settings-stores/issues
[license]: ../../LICENSE
[policies]: ../policy/README.md
[security]: ../policy/security.md
[tasks]: tasks.md
[testing]: testing.md
