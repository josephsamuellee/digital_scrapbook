require "test_helper"

class Memory::StoreTest < ActiveSupport::TestCase
  test "writes YAML front matter with the stable id and indexes the source path" do
    memory = Memory::Allocator.create!
    document = memory.document.with(
      title: "Taiwan 2026",
      start_date: Date.new(2026, 2, 3)
    )

    Memory::Store.write(document, memory: memory)
    memory.reload

    assert_equal "Taiwan 2026", memory.title
    assert_equal Date.new(2026, 2, 3), memory.start_date
    assert_equal "memories/#{memory.directory_name}/memory.md", memory.source_path
    assert_match(/^id: #{memory.id}$/, memory.source_pathname.read)
    assert_match(/^title: Taiwan 2026$/, memory.source_pathname.read)
  end

  test "does not rename the Memory directory when the title changes" do
    memory = Memory::Allocator.create!
    directory = memory.directory_name

    Memory::Store.write(memory.document.with(title: "Taiwan + Hong Kong 2026"), memory: memory)
    memory.reload

    assert_equal directory, memory.directory_name
    assert_equal "Taiwan + Hong Kong 2026", memory.title
  end

  test "failed temporary write leaves previous Markdown and sqlite unchanged" do
    memory = Memory::Allocator.create!
    Memory::Store.write(memory.document.with(title: "Kept"), memory: memory)
    memory.reload
    previous_markdown = memory.source_pathname.read
    previous_title = memory.title

    FileUtils.mkdir_p(memory.directory_pathname.join("memory.md.tmp"))

    assert_raises(Memory::Store::WriteError) do
      Memory::Store.write(memory.document.with(title: "Discarded"), memory: memory)
    end

    memory.reload
    assert_equal previous_markdown, memory.source_pathname.read
    assert_equal previous_title, memory.title
  end

  test "reindexes sqlite from Markdown when the fingerprint is stale" do
    memory = Memory::Allocator.create!
    path = memory.source_pathname
    path.write(Memory::Markdown.serialize(memory.document.with(title: "Externally edited")))

    Memory::Store.reindex_if_stale(memory, Memory::Markdown.parse(path.read))
    memory.reload

    assert_equal "Externally edited", memory.title
  end

  test "rejects a write when the expected fingerprint does not match the file" do
    memory = Memory::Allocator.create!
    original = memory.source_pathname.read

    assert_raises(Memory::Store::StaleError) do
      Memory::Store.write(memory.document.with(title: "Nope"), memory: memory, expected_fingerprint: "stale")
    end

    assert_equal original, memory.source_pathname.read
    memory.reload
    assert_nil memory.title
  end
end
