# frozen_string_literal: true

require "json"
require "open3"

module Hanami
  class Settings
    # A settings store backed by Bitwarden.
    #
    # Uses mappings defined via {BitwardenStore::Mixin#bw_setting} on your Settings class to
    # resolve setting values from Bitwarden items. Requires the `bw` CLI to be installed and
    # authenticated.
    #
    # Item fields are cached in memory after the first fetch for each item.
    #
    # @example
    #   # config/settings.rb
    #   class Settings < Hanami::Settings
    #     bw_setting :database_url, item: "MyApp", constructor: Types::String
    #     bw_setting :api_key, item: "ExternalService", key: :secret_key, constructor: Types::String
    #   end
    #
    #   # config/app.rb
    #   config.settings_store = Hanami::Settings::CompositeStore.new(
    #     Hanami::Settings::EnvStore.new,
    #     Hanami::Settings::BitwardenStore.new
    #   )
    #
    # @api public
    # @since 0.1.0
    class BitwardenStore
      # DSL extension for {Hanami::Settings} that adds the {#bw_setting} method.
      #
      # Automatically included when this file is required.
      #
      # @api public
      # @since 0.1.0
      module Mixin
        # @api private
        module ClassMethods
          # Returns the Bitwarden mappings for this settings class.
          #
          # @return [Hash{Symbol => Hash}]
          # @api private
          def bw_mappings
            @bw_mappings ||= {}
          end

          # Defines a setting backed by a Bitwarden item field.
          #
          # @param name [Symbol] the setting name
          # @param item [String] the Bitwarden item name or ID
          # @param key [Symbol, String] the field name (defaults to the setting name)
          # @param options [Hash] additional options passed to `Dry::Configurable#setting`
          #
          # @api public
          # @since 0.1.0
          def bw_setting(name, item:, key: name, **options)
            bw_mappings[name] = {item: item.to_s, key: key.to_s}
            setting(name, **options)
          end
        end

        # @api private
        def self.prepended(base)
          base.extend(ClassMethods)
        end

        # @api private
        def initialize(store = EMPTY_STORE)
          store.bw_mappings = self.class.bw_mappings if store.respond_to?(:bw_mappings=)
          super
        end
      end

      def initialize
        @bw_mappings = {}
        @cache = {}
      end

      # Sets the Bitwarden mappings from the settings class.
      #
      # @param mappings [Hash{Symbol => Hash}]
      # @api private
      attr_writer :bw_mappings

      # Fetches a setting value using its Bitwarden mapping.
      #
      # @param name [String, Symbol] the setting name
      # @param args [Array] optional default value
      # @yield [name] optional block for default value
      # @return [String] the field value
      # @raise [KeyError] if the field is not found and no default is given
      #
      # @api public
      # @since 0.1.0
      def fetch(name, *args, &block)
        mapping = @bw_mappings[name.to_sym]

        unless mapping
          return args.first unless args.empty?
          return yield(name) if block

          raise KeyError, "key not found: #{name.inspect}"
        end

        item_fields(mapping[:item]).fetch(mapping[:key], *args, &block)
      end

      private

      # @api private
      def item_fields(item_name)
        @cache[item_name] ||= load_item_fields(item_name)
      end

      # @api private
      def load_item_fields(item_name)
        stdout, stderr, status = Open3.capture3("bw", "get", "item", item_name)
        raise "Bitwarden CLI error: #{stderr.strip}" unless status.success?

        item = JSON.parse(stdout)
        item.fetch("fields", []).each_with_object({}) do |field, hash|
          name = field["name"]
          hash[name] = field["value"] unless name.nil? || name.empty?
        end
      end
    end
  end
end

Hanami::Settings.prepend(Hanami::Settings::BitwardenStore::Mixin)
