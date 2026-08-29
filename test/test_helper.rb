ENV["RAILS_ENV"] ||= "test"
# Keep test Memory files out of the development data root.
ENV["SCRAPBOOK_DATA_ROOT"] ||= File.expand_path("../tmp/scrapbook-test", __dir__)
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

module ActiveSupport
  class TestCase
    # Memory directories live on the filesystem beside SQLite. Parallel
    # workers would collide on ID allocation and memory.md paths.
    parallelize(workers: 1)

    setup do
      isolate_scrapbook_data
    end

    private

    def isolate_scrapbook_data
      return unless ActiveRecord::Base.connection.data_source_exists?("memories")

      Memory.delete_all
      FileUtils.rm_rf(Memory.memories_root)
      FileUtils.mkdir_p(Memory.memories_root)
    end

    def require_magick
      skip "JPEG image tests require magick on PATH" unless Memory::ImageProcessor.magick_available?
    end

    def require_heif_convert
      skip "HEIC tests require heif-convert on PATH" unless Memory::ImageProcessor.heif_convert_available?
    end
  end
end
