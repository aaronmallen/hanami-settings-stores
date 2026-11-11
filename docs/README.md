# hanami-settings-stores Documentation

Pluggable settings stores that fetch secrets from password managers like 1Password and Bitwarden, for use with
`Hanami::Settings`. Chain multiple stores with fallback resolution using `CompositeStore`, so your app can resolve
settings from ENV first and fall back to a password manager for anything not found.

## Documentation Index

- [Contributing & Development Guide][dev]
- [Policies and Governance][policy]

[dev]: dev/README.md
[policy]: policy/README.md
