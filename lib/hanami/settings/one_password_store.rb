# frozen_string_literal: true

require "json"
require "open3"

module Hanami
  class Settings
    # A settings store backed by 1Password.
    #
    # Uses mappings defined via {OnePasswordStore::Mixin#op_setting} on your Settings class to
    # resolve setting values from 1Password items. Requires the `op` CLI to be installed and
    # authenticated.
    #
    # Item fields are cached in memory after the first fetch for each item.
    #
    # @example
    #   # config/settings.rb
    #   class Settings < Hanami::Settings
    #     op_setting :database_url, item: "MyApp", constructor: Types::String
    #     op_setting :api_key, item: "ExternalService", key: :secret_key, constructor: Types::String
    #   end
    #
    #   # config/app.rb
    #   config.settings_store = Hanami::Settings::CompositeStore.new(
    #     Hanami::Settings::EnvStore.new,
    #     Hanami::Settings::OnePasswordStore.new(vault: "Production")
    #   )
    #
    # @api public
    # @since 0.1.0
    class OnePasswordStore
      # DSL extension for {Hanami::Settings} that adds the {#op_setting} method.
      #
      # Automatically included when this file is required.
      #
      # @api public
      # @since 0.1.0
      module Mixin
        # @api private
        module ClassMethods
          # Returns the 1Password mappings for this settings class.
          #
          # @return [Hash{Symbol => Hash}]
          # @api private
          def op_mappings
            @op_mappings ||= {}
          end

          # Defines a setting backed by a 1Password item field.
          #
          # @param name [Symbol] the setting name
          # @param item [String] the 1Password item name or ID
          # @param key [Symbol, String] the field label (defaults to the setting name)
          # @param options [Hash] additional options passed to `Dry::Configurable#setting`
          #
          # @api public
          # @since 0.1.0
          def op_setting(name, item:, key: name, **options)
            op_mappings[name] = {item: item.to_s, key: key.to_s}
            setting(name, **options)
          end
        end

        # @api private
        def self.prepended(base)
          base.extend(ClassMethods)
        end

        # @api private
        def initialize(store = EMPTY_STORE)
          store.op_mappings = self.class.op_mappings if store.respond_to?(:op_mappings=)
          super
        end
      end

      # @param vault [String] the 1Password vault name or ID
      def initialize(vault:)
        @vault = vault
        @op_mappings = {}
        @cache = {}
      end

      # Sets the 1Password mappings from the settings class.
      #
      # @param mappings [Hash{Symbol => Hash}]
      # @api private
      attr_writer :op_mappings

      # Fetches a setting value using its 1Password mapping.
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
        mapping = @op_mappings[name.to_sym]

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
        stdout, stderr, status = Open3.capture3("op", "item", "get", item_name, "--vault", @vault, "--format", "json")
        raise "1Password CLI error: #{stderr.strip}" unless status.success?

        item = JSON.parse(stdout)
        item.fetch("fields", []).each_with_object({}) do |field, hash|
          label = field["label"]
          hash[label] = field["value"] unless label.nil? || label.empty?
        end
      end
    end
  end
end

Hanami::Settings.prepend(Hanami::Settings::OnePasswordStore::Mixin)
