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

    def write_ready_memory(
      title: "Taiwan 2026",
      start_date: Date.new(2026, 2, 3),
      end_date: Date.new(2026, 2, 17),
      subtitle: "Taiwan and Hong Kong",
      key_photo: "IMG_1234.jpg",
      pages: nil,
      thumb: true
    )
      memory = Memory::Allocator.create!
      jpeg = file_fixture("sample.jpg").binread
      stem = File.basename(key_photo, ".*")
      memory.directory_pathname.join(key_photo).binwrite(jpeg)
      memory.directory_pathname.join("#{stem}_present.jpg").binwrite(jpeg)
      memory.directory_pathname.join("#{stem}_thumb.jpg").binwrite(jpeg) if thumb
      document = memory.document.with(
        title: title,
        start_date: start_date,
        end_date: end_date,
        subtitle: subtitle,
        key_photo: key_photo,
        pages: pages || [
          Memory::Page.new(heading: "Day one", body: "![Photo](#{key_photo})\n\n- Arrived")
        ]
      )
      Memory::Store.write(document, memory: memory)
      memory.reload
    end
  end
end
