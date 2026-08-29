require "test_helper"

class Memory::ReconcilerTest < ActiveSupport::TestCase
  test "external Markdown metadata wins and is logged" do
    memory = Memory::Allocator.create!
    Memory::Store.write(memory.document.with(title: "Taiwan"), memory: memory)
    memory.source_pathname.write(
      Memory::Markdown.serialize(memory.document.with(title: "Taiwan 2026"))
    )
    stable_id = memory.id

    logged = capture_logs { Memory::Reconciler.run }
    memory.reload

    assert_equal "Taiwan 2026", memory.title
    assert_equal stable_id, memory.id
    assert logged.any? { |message| message.include?("Reindexed Memory #{stable_id}") }
  end

  test "renamed directory updates source_path by stable id" do
    memory = Memory::Allocator.create!
    Memory::Store.write(memory.document.with(title: "Moved"), memory: memory)
    stable_id = memory.id
    new_dir = Memory.memories_root.join("#{format("%03d", stable_id)}-9999999999")
    FileUtils.mv(memory.directory_pathname, new_dir)

    logged = capture_logs { Memory::Reconciler.run }
    memory.reload

    assert_equal stable_id, memory.id
    assert_equal "memories/#{new_dir.basename}/memory.md", memory.source_path
    assert_equal "Moved", memory.title
    assert logged.any? { |message| message.include?("source path") }
  end

  test "orphan Memory directory is imported from Markdown" do
    dir = Memory.memories_root.join("042-1111111111")
    FileUtils.mkdir_p(dir)
    dir.join("memory.md").write(
      Memory::Markdown.serialize(Memory::Document.new(id: 42, title: "Orphan"))
    )

    logged = capture_logs { Memory::Reconciler.run }
    imported = Memory.find(42)

    assert_equal "Orphan", imported.title
    assert_equal "memories/042-1111111111/memory.md", imported.source_path
    assert logged.any? { |message| message.include?("Imported Memory 42") }
  end

  test "duplicate YAML ids are not merged by title" do
    memory = Memory::Allocator.create!
    Memory::Store.write(memory.document.with(title: "Original"), memory: memory)
    copy = Memory.memories_root.join("#{format("%03d", memory.id)}-2222222222")
    FileUtils.mkdir_p(copy)
    copy.join("memory.md").write(
      Memory::Markdown.serialize(memory.document.with(title: "Copy should not win"))
    )

    logged = capture_logs { Memory::Reconciler.run }
    memory.reload

    assert_equal "Original", memory.title
    assert_not_equal "memories/#{copy.basename}/memory.md", memory.source_path
    assert_nil Memory.find_by(source_path: "memories/#{copy.basename}/memory.md")
    assert logged.any? { |message| message.include?("Ambiguous Memory #{memory.id}") }
  end

  test "does not steal a path owned by another Memory" do
    first = Memory::Allocator.create!
    second = Memory::Allocator.create!
    Memory::Store.write(first.document.with(title: "First"), memory: first)
    Memory::Store.write(second.document.with(title: "Second"), memory: second)
    first.source_pathname.delete
    second.source_pathname.write(
      Memory::Markdown.serialize(Memory::Document.new(id: first.id, title: "Stolen"))
    )

    logged = capture_logs { Memory::Reconciler.run }

    assert_equal first.source_path, first.reload.source_path
    assert_equal "First", first.title
    assert_equal "Second", second.reload.title
    assert logged.any? { |message| message.include?("conflicts with Memory #{second.id}") }
  end

  test "does not regenerate missing Markdown from SQLite" do
    memory = Memory::Allocator.create!
    Memory::Store.write(memory.document.with(title: "Kept"), memory: memory)
    memory.source_pathname.delete

    logged = capture_logs { Memory::Reconciler.run }

    refute_predicate memory.source_pathname, :exist?
    assert_equal "Kept", memory.reload.title
    assert logged.any? { |message| message.include?("not regenerating from SQLite") }
  end

  test "invalid Markdown is skipped and does not block other Memories" do
    valid = Memory::Allocator.create!
    Memory::Store.write(valid.document.with(title: "Valid"), memory: valid)
    corrupt = Memory::Allocator.create!
    corrupt.source_pathname.write("not a memory")

    logged = capture_logs { Memory::Reconciler.run }

    assert_equal "Valid", valid.reload.title
    assert_nil corrupt.reload.title
    assert logged.any? { |message| message.include?(corrupt.directory_name) }
  end

  test "later reconciliation restores SQLite after index failure" do
    memory = Memory::Allocator.create!
    Memory::Store.write(memory.document.with(title: "Before"), memory: memory)
    updated = memory.document.with(title: "After Markdown write")

    Memory::Store.stub :index!, ->(*) { raise ActiveRecord::StatementInvalid, "sqlite down" } do
      Memory::Store.write(updated, memory: memory)
    end

    assert_match(/title: After Markdown write/, memory.source_pathname.read)
    assert_equal "Before", memory.reload.title

    Memory::Reconciler.run
    assert_equal "After Markdown write", memory.reload.title
  end

  private

  def capture_logs
    messages = []
    logger = ->(message) { messages << message.to_s }
    Rails.logger.stub :info, logger do
      Rails.logger.stub :error, logger do
        yield
      end
    end
    messages
  end
end
