ENV["RAILS_ENV"] ||= "test"
# Keep test Memory files out of the development data root.
ENV["SCRAPBOOK_DATA_ROOT"] ||= File.expand_path("../tmp/scrapbook-test", __dir__)
require_relative "../config/environment"
require "rails/test_help"

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
  end
end
