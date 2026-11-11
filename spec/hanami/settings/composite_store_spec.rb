# frozen_string_literal: true

RSpec.describe Hanami::Settings::CompositeStore do
  subject(:store) { described_class.new(*stores) }

  let(:primary) { {database_url: "postgres://localhost/myapp"} }
  let(:fallback) { {database_url: "postgres://fallback/myapp", session_secret: "supersecret"} }
  let(:stores) { [primary, fallback] }

  describe "#fetch" do
    it "returns the value from the first store that has the key" do
      expect(store.fetch(:database_url)).to eq("postgres://localhost/myapp")
    end

    it "falls back to subsequent stores when the key is missing" do
      expect(store.fetch(:session_secret)).to eq("supersecret")
    end

    it "raises KeyError when no store has the key and no default is given" do
      expect { store.fetch(:missing_key) }.to raise_error(KeyError, /missing_key/)
    end

    it "returns the default value when no store has the key" do
      expect(store.fetch(:missing_key, "default")).to eq("default")
    end

    it "yields to the block when no store has the key and a block is given" do
      expect(store.fetch(:missing_key) { |k| "default_#{k}" }).to eq("default_missing_key")
    end

    it "prefers the default argument over the block" do
      expect(store.fetch(:missing_key, "default") { "block" }).to eq("default")
    end
  end
end
