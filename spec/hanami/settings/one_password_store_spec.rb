# frozen_string_literal: true

RSpec.describe Hanami::Settings::OnePasswordStore do
  subject(:store) { described_class.new(vault: "Production") }

  let(:myapp_output) do
    {
      "fields" => [
        {"label" => "database_url", "value" => "postgres://localhost/myapp"},
        {"label" => "session_secret", "value" => "supersecret"},
        {"label" => "", "value" => "ignored"},
        {"label" => nil, "value" => "also_ignored"}
      ]
    }.to_json
  end

  let(:external_output) do
    {
      "fields" => [
        {"label" => "secret_key", "value" => "abc123"}
      ]
    }.to_json
  end

  let(:success_status) { instance_double(Process::Status, success?: true) }
  let(:failure_status) { instance_double(Process::Status, success?: false) }

  before do
    allow(Open3).to receive(:capture3)
      .with("op", "item", "get", "MyApp", "--vault", "Production", "--format", "json")
      .and_return([myapp_output, "", success_status])

    allow(Open3).to receive(:capture3)
      .with("op", "item", "get", "ExternalService", "--vault", "Production", "--format", "json")
      .and_return([external_output, "", success_status])

    store.op_mappings = {
      database_url: {item: "MyApp", key: "database_url"},
      session_secret: {item: "MyApp", key: "session_secret"},
      api_key: {item: "ExternalService", key: "secret_key"}
    }
  end

  describe "#fetch" do
    it "returns the value for a mapped setting" do
      expect(store.fetch(:database_url)).to eq("postgres://localhost/myapp")
    end

    it "resolves settings from different items" do
      expect(store.fetch(:api_key)).to eq("abc123")
    end

    it "caches fields per item" do
      store.fetch(:database_url)
      store.fetch(:session_secret)
      store.fetch(:api_key)

      expect(Open3).to have_received(:capture3).twice
    end

    it "raises KeyError when the setting has no mapping and no default is given" do
      expect { store.fetch(:unknown) }.to raise_error(KeyError)
    end

    it "returns the default value when the setting has no mapping" do
      expect(store.fetch(:unknown, "fallback")).to eq("fallback")
    end

    it "yields to the block when the setting has no mapping and a block is given" do
      expect(store.fetch(:unknown) { |k| "default_#{k}" }).to eq("default_unknown")
    end

    it "returns the default when a mapped field is not found in the item" do
      store.op_mappings = {missing_field: {item: "MyApp", key: "nonexistent"}}

      expect(store.fetch(:missing_field, "fallback")).to eq("fallback")
    end

    it "skips fields with empty labels" do
      store.op_mappings = {empty: {item: "MyApp", key: ""}}

      expect { store.fetch(:empty) }.to raise_error(KeyError)
    end

    context "when the op CLI fails" do
      before do
        allow(Open3).to receive(:capture3)
          .with("op", "item", "get", "MyApp", "--vault", "Production", "--format", "json")
          .and_return(["", "not signed in", failure_status])
      end

      it "raises an error with the CLI output" do
        expect { store.fetch(:database_url) }.to raise_error(RuntimeError, /not signed in/)
      end
    end
  end
end
