# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "hanami-settings-stores"
  spec.version = "0.1.2"
  spec.authors = ["Aaron Allen"]
  spec.email = ["hello@aaronmallen.me"]

  spec.summary = "Pluggable settings stores for Hanami"
  spec.description = "Settings stores that fetch values from password managers like 1Password " \
    "and Bitwarden, or from a local JSON, TOML, or YAML file, for use with Hanami::Settings."
  spec.homepage = "https://aaronmallen.dev/aaron/hanami-settings-stores"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "changelog_uri" => "#{spec.homepage}/src/branch/main/CHANGELOG.md",
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true",
    "source_code_uri" => spec.homepage
  }

  spec.files = Dir["lib/**/*", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "toml", "~> 0.3"
  spec.add_dependency "zeitwerk", "~> 2"
end
