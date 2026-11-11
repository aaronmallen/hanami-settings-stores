# frozen_string_literal: true

require "zeitwerk"

module Hanami
  class Settings
  end
end

Zeitwerk::Loader.new.tap do |loader|
  loader.tag = "hanami-settings-stores"
  loader.push_dir(File.join(File.dirname(__FILE__), "hanami", "settings"), namespace: Hanami::Settings)
  loader.ignore(__FILE__)
end.setup
