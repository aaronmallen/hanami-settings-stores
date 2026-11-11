# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe Hanami::Settings::FileStore do
  subject(:store) { described_class.new(write("settings.yml", yaml)) }

  let(:tmpdir) { Dir.mktmpdir }

  let(:yaml) do
    <<~YAML
      database_url: postgres://localhost/myapp
      session_secret: <%= "super" + "secret" %>
      pool_size: 5
    YAML
  end

  after { FileUtils.remove_entry(tmpdir) }

  def write(name, contents)
    File.join(tmpdir, name).tap { |path| File.write(path, contents) }
  end

  describe "#initialize" do
    it "raises ArgumentError when given neither a path nor a block" do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError when given both a path and a block" do
      path = write("settings.yml", yaml)

      expect { described_class.new(path) { path } }.to raise_error(ArgumentError)
    end

    it "does not read the file" do
      allow(File).to receive(:read).and_call_original
      described_class.new(write("settings.yml", yaml))

      expect(File).not_to have_received(:read)
    end
  end

  describe "#fetch" do
    it "returns the value for a symbol name" do
      expect(store.fetch(:database_url)).to eq("postgres://localhost/myapp")
    end

    it "returns the value for a string name" do
      expect(store.fetch("database_url")).to eq("postgres://localhost/myapp")
    end

    it "preserves non-string values" do
      expect(store.fetch(:pool_size)).to eq(5)
    end

    it "evaluates ERB in the file" do
      expect(store.fetch(:session_secret)).to eq("supersecret")
    end

    it "reads the file once" do
      allow(File).to receive(:read).and_call_original
      store.fetch(:database_url)
      store.fetch(:session_secret)

      expect(File).to have_received(:read).once
    end

    it "raises KeyError when the key is missing and no default is given" do
      expect { store.fetch(:missing_key) }.to raise_error(KeyError, /missing_key/)
    end

    it "returns the default value when the key is missing" do
      expect(store.fetch(:missing_key, "default")).to eq("default")
    end

    it "yields to the block when the key is missing and a block is given" do
      expect(store.fetch(:missing_key) { |key| "default_#{key}" }).to eq("default_missing_key")
    end

    it "raises ArgumentError for an unsupported extension" do
      store = described_class.new(write("settings.ini", "database_url = postgres://localhost/myapp"))

      expect { store.fetch(:database_url) }.to raise_error(ArgumentError, /settings\.ini/)
    end

    context "with a JSON file" do
      subject(:store) { described_class.new(write("settings.json", json)) }

      let(:json) { '{"database_url": "postgres://localhost/myapp", "pool_size": 5, "redis": {"url": "redis://"}}' }

      it "parses the file" do
        expect(store.fetch(:database_url)).to eq("postgres://localhost/myapp")
      end

      it "preserves non-string values" do
        expect(store.fetch(:pool_size)).to eq(5)
      end

      it "returns nested values as hashes with symbol keys" do
        expect(store.fetch(:redis)).to eq(url: "redis://")
      end
    end

    context "with a TOML file" do
      subject(:store) { described_class.new(write("settings.toml", toml)) }

      let(:toml) do
        <<~TOML
          database_url = "postgres://localhost/myapp"
          pool_size = 5

          [redis]
          url = "redis://"
        TOML
      end

      it "parses the file" do
        expect(store.fetch(:database_url)).to eq("postgres://localhost/myapp")
      end

      it "preserves non-string values" do
        expect(store.fetch(:pool_size)).to eq(5)
      end

      it "returns nested values as hashes with symbol keys" do
        expect(store.fetch(:redis)).to eq(url: "redis://")
      end
    end

    context "with a .yaml file" do
      subject(:store) { described_class.new(write("settings.yaml", yaml)) }

      it "parses the file" do
        expect(store.fetch(:database_url)).to eq("postgres://localhost/myapp")
      end
    end

    context "with dates, times, and symbols in a YAML file" do
      subject(:store) { described_class.new(write("settings.yml", yaml)) }

      let(:yaml) do
        <<~YAML
          expires_on: 2026-01-01
          released_at: 2026-01-01 12:30:00
          adapter: :postgres
        YAML
      end

      it "parses dates" do
        expect(store.fetch(:expires_on)).to eq(Date.new(2026, 1, 1))
      end

      it "parses times" do
        expect(store.fetch(:released_at)).to be_a(Time)
      end

      it "parses symbols" do
        expect(store.fetch(:adapter)).to eq(:postgres)
      end
    end

    context "with an empty YAML file" do
      subject(:store) { described_class.new(write("settings.yml", "# just a comment\n")) }

      it "raises KeyError for any key" do
        expect { store.fetch(:database_url) }.to raise_error(KeyError)
      end

      it "returns the default value" do
        expect(store.fetch(:database_url, "default")).to eq("default")
      end
    end

    context "with YAML aliases" do
      subject(:store) { described_class.new(write("settings.yml", yaml)) }

      let(:yaml) do
        <<~YAML
          defaults: &defaults
            host: localhost
          primary:
            <<: *defaults
        YAML
      end

      it "resolves the alias" do
        expect(store.fetch(:primary)).to eq(host: "localhost")
      end
    end

    context "when the file does not exist" do
      subject(:store) { described_class.new(File.join(tmpdir, "missing.yml")) }

      it "behaves as an empty store" do
        expect(store.fetch(:database_url, "default")).to eq("default")
      end

      it "raises KeyError when no default is given" do
        expect { store.fetch(:database_url) }.to raise_error(KeyError)
      end
    end

    context "when the file does not contain a mapping" do
      subject(:store) { described_class.new(write("settings.yml", "- one\n- two\n")) }

      it "raises TypeError naming the file" do
        expect { store.fetch(:database_url) }.to raise_error(TypeError, /settings\.yml.*Array/)
      end
    end
  end

  describe "#path" do
    it "returns the given path" do
      path = write("settings.yml", yaml)

      expect(described_class.new(path).path).to eq(path)
    end

    it "resolves the path from the given block" do
      path = write("settings.yml", yaml)

      expect(described_class.new { path }.path).to eq(path)
    end

    it "calls the block once" do
      resolved = 0
      store = described_class.new { resolved += 1 }
      store.path
      store.path

      expect(resolved).to eq(1)
    end

    it "does not call the block until the path is needed" do
      expect { described_class.new { raise "should not be called" } }.not_to raise_error
    end
  end

  describe "with a CompositeStore" do
    subject(:composite) { Hanami::Settings::CompositeStore.new({}, store) }

    it "resolves settings that earlier stores do not have" do
      expect(composite.fetch(:database_url)).to eq("postgres://localhost/myapp")
    end
  end
end
