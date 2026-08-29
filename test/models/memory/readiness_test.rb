require "test_helper"

class Memory::ReadinessTest < ActiveSupport::TestCase
  setup do
    @directory = Memory.memories_root.join("001-0000000001")
    FileUtils.mkdir_p(@directory)
  end

  test "a blank draft is incomplete" do
    readiness = Memory::Readiness.new(Memory::Document.new(id: 1), directory: @directory)

    refute_predicate readiness, :ready?
    keys = readiness.messages.map(&:key)
    assert_includes keys, :missing_title
    assert_includes keys, :missing_start_date
    assert_includes keys, :no_authored_page
    assert_includes keys, :no_processed_picture
    assert_includes keys, :missing_key_photo
  end

  test "filling a title alone is still incomplete" do
    document = Memory::Document.new(id: 1, title: "Taiwan 2026")
    keys = Memory::Readiness.new(document, directory: @directory).messages.map(&:key)

    refute_includes keys, :missing_title
    assert_includes keys, :missing_start_date
    assert_includes keys, :no_authored_page
    assert_includes keys, :no_processed_picture
    assert_includes keys, :missing_key_photo
  end

  test "end date before start date is a blocking condition" do
    document = Memory::Document.new(
      id: 1,
      title: "Taiwan 2026",
      start_date: Date.new(2026, 2, 17),
      end_date: Date.new(2026, 2, 3)
    )
    keys = Memory::Readiness.new(document, directory: @directory).messages.map(&:key)

    assert_includes keys, :end_before_start
  end
end
