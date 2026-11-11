# frozen_string_literal: true

require "date"
require "erb"

module Hanami
  class Settings
    # A settings store backed by a local JSON, TOML, or YAML file.
    #
    # The file is read lazily, on the first fetch, and its contents are then memoized. Its contents
    # run through ERB first, so a file can interpolate Ruby. A file that does not exist, or that is
    # empty, results in an empty store.
    #
    # Only top level keys resolve. Keys are compared as symbols, so a setting named `:database_url`
    # matches the `database_url` key in the file.
    #
    # @example
    #   # config/settings.yml
    #   database_url: postgres://localhost/myapp
    #   session_secret: <%= ENV.fetch("SESSION_SECRET") %>
    #
    #   # config/app.rb
    #   config.settings_store = Hanami::Settings::CompositeStore.new(
    #     Hanami::Settings::EnvStore.new,
    #     Hanami::Settings::FileStore.new("config/settings.yml")
    #   )
    #
    # @example Resolving the path lazily
    #   # Give a block to resolve the path when the settings are first fetched, rather than when the
    #   # store is created.
    #   config.settings_store = Hanami::Settings::FileStore.new { config.root.join("config/settings.yml") }
    #
    # @api public
    # @since 0.1.1
    class FileStore
      # @api private
      # @since 0.2.0
      EMPTY_SETTINGS = {}.freeze
      private_constant :EMPTY_SETTINGS

      # @api private
      # @since 0.1.1
      JSON_EXTENSIONS = %w[.json].freeze
      private_constant :JSON_EXTENSIONS

      # The classes permitted when parsing a YAML file.
      #
      # @api private
      # @since 0.2.0
      PERMITTED_CLASSES = [Date, DateTime, Symbol, Time].freeze
      private_constant :PERMITTED_CLASSES

      # @api private
      # @since 0.1.1
      TOML_EXTENSIONS = %w[.toml].freeze
      private_constant :TOML_EXTENSIONS

      # @api private
      # @since 0.1.1
      YAML_EXTENSIONS = %w[.yaml .yml].freeze
      private_constant :YAML_EXTENSIONS

      # @api private
      # @since 0.1.1
      EXTENSIONS = (JSON_EXTENSIONS + TOML_EXTENSIONS + YAML_EXTENSIONS).freeze
      private_constant :EXTENSIONS

      # Returns a new instance of the store.
      #
      # Give either a path or a block returning a path. The block is called on the first fetch,
      # which allows the path to depend on config (such as the root) that is not yet known when the
      # store is created.
      #
      # @param path [Pathname, String, nil] path to the settings file
      #
      # @yieldreturn [Pathname, String] path to the settings file
      #
      # @raise [ArgumentError] if given neither a path nor a block, or both
      #
      # @api public
      # @since 0.1.1
      def initialize(path = nil, &block)
        raise ArgumentError, "give either a path or a block returning a path" if path.nil? == block.nil?

        @path = path
        @path_resolver = block
      end

      # Fetches a setting value from the parsed file.
      #
      # @param name [String, Symbol] the setting name
      # @param args [Array] optional default value
      # @yield [name] optional block for default value
      # @return [Object] the setting value
      # @raise [ArgumentError] if the store cannot parse the file extension
      # @raise [KeyError] if the file has no such key and no default is given
      # @raise [TypeError] if the file does not contain a mapping
      #
      # @api public
      # @since 0.1.1
      def fetch(name, *args, &block)
        settings.fetch(name.to_sym, *args, &block)
      end

      # Returns the path to the settings file, resolving it from the block given at initialize-time,
      # if any.
      #
      # @return [Pathname, String]
      #
      # @api public
      # @since 0.2.0
      def path
        @path ||= @path_resolver.call
      end

      private

      def load_settings
        return EMPTY_SETTINGS unless File.exist?(path)

        contents = parse(ERB.new(File.read(path)).result)

        # An empty file (or one containing only comments) parses as `nil`.
        return EMPTY_SETTINGS if contents.nil?

        unless contents.is_a?(Hash)
          raise TypeError, "cannot parse #{path}: expected a mapping, got #{contents.class}"
        end

        contents.freeze
      end

      def parse(source)
        case File.extname(path.to_s)
        when *JSON_EXTENSIONS
          require "json"
          JSON.parse(source, symbolize_names: true)
        when *TOML_EXTENSIONS
          require "toml"
          symbolize(TOML::Parser.new(source).parsed)
        when *YAML_EXTENSIONS
          require "yaml"
          YAML.load(source, aliases: true, permitted_classes: PERMITTED_CLASSES, symbolize_names: true)
        else raise ArgumentError, "cannot parse #{path}: expected one of #{EXTENSIONS.join(", ")}"
        end
      end

      def settings
        @settings ||= load_settings
      end

      def symbolize(value)
        case value
        when Hash then value.to_h { |key, val| [key.to_sym, symbolize(val)] }
        when Array then value.map { |val| symbolize(val) }
        else value
        end
      end
    end
  end
end
