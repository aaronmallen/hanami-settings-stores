# frozen_string_literal: true

RSpec.describe Hanami::Settings::BitwardenStore::Mixin do
  def build_settings_class(setting_spy: ->(_name, **) {}, &block)
    Class.new do
      extend Hanami::Settings::BitwardenStore::Mixin::ClassMethods
      define_singleton_method(:setting, &setting_spy)
      class_eval(&block)
    end
  end

  describe "ClassMethods" do
    describe ".bw_setting" do
      it "registers a mapping with the given item and key" do
        klass = build_settings_class { bw_setting :database_url, item: "MyApp", key: :url }

        expect(klass.bw_mappings).to eq(database_url: {item: "MyApp", key: "url"})
      end

      it "defaults key to the setting name" do
        klass = build_settings_class { bw_setting :database_url, item: "MyApp" }

        expect(klass.bw_mappings).to eq(database_url: {item: "MyApp", key: "database_url"})
      end

      it "forwards additional options to setting" do
        received = nil
        spy = ->(_name, **opts) { received = opts }
        build_settings_class(setting_spy: spy) { bw_setting :database_url, item: "MyApp", default: "fallback" }

        expect(received).to eq(default: "fallback")
      end
    end
  end
end
