# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v0.1.2] - 2026-11-11

### Added

- `FileStore.new` accepts a block returning the path, resolved lazily on the first fetch
- `FileStore#path`, which resolves and memoizes the path

### Changed

- Moved the project and CI to [Forgejo].
- `FileStore` parses YAML with `Date`, `DateTime`, `Symbol`, and `Time` permitted, so files
  containing dates, times, or symbols no longer raise `Psych::DisallowedClass`
- **Breaking:** `FileStore` keys are now symbols, so nested values come back as hashes with symbol
  keys rather than string keys
- **Breaking:** `FileStore` reads the file on the first fetch rather than when the store is built
- **Breaking:** `FileStore` treats a missing file as an empty store instead of raising
  `Errno::ENOENT`, and raises `TypeError` when the file parses to something other than a mapping

## [v0.1.1] - 2026-08-20

### Added

- `FileStore` with json, toml, and yaml support

### Removed

- removed unnecessary `hanami` gem as a runtime dependency

## [v0.1.0] - 2026-03-17

Initial release.

[Forgejo]: https://aaronmallen.dev/aaron/hanami-settings-stores
[Unreleased]: https://aaronmallen.dev/aaron/hanami-settings-stores/compare/0.1.2...HEAD
[v0.1.2]: https://aaronmallen.dev/aaron/hanami-settings-stores/src/tag/0.1.2
[v0.1.1]: https://aaronmallen.dev/github-archive/hanami-settings-stores/compare/0.1.0...0.1.1
[v0.1.0]: https://aaronmallen.dev/github-archive/hanami-settings-stores/releases/tag/0.1.0
