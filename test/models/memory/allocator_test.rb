require "test_helper"

class Memory::AllocatorTest < ActiveSupport::TestCase
  test "allocates a stable id and NNN-RANDOM directory before a title exists" do
    memory = Memory::Allocator.create!

    assert_match(/\A\d{3}-\d{10}\z/, memory.directory_name)
    assert_equal format("%03d", memory.id), memory.directory_name.split("-").first
    assert_equal "memories/#{memory.directory_name}/memory.md", memory.source_path
    assert_predicate memory.source_pathname, :file?

    document = Memory::Markdown.parse(memory.source_pathname.read)
    assert_equal memory.id, document.id
    assert_nil document.title
  end

  test "assigns the next id from sqlite and filesystem prefixes" do
    first = Memory::Allocator.create!
    second = Memory::Allocator.create!

    assert_equal first.id + 1, second.id
    assert_operator second.id, :>, first.id
  end
end
