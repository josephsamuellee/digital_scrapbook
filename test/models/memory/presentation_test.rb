require "test_helper"

class Memory::PresentationTest < ActiveSupport::TestCase
  setup do
    @directory = Memory.memories_root.join("001-0000000001")
    FileUtils.mkdir_p(@directory)
  end

  test "title is 1 of authored-plus-title and end is not counted" do
    document = Memory::Document.new(
      id: 1,
      title: "Taiwan 2026",
      start_date: Date.new(2026, 2, 3),
      end_date: Date.new(2026, 2, 17),
      pages: [Memory::Page.new(heading: "Day 1", body: "- Hello")]
    )
    presentation = Memory::Presentation.new(document, directory: @directory)

    title = presentation.state_at(0)
    authored = presentation.state_at(1)
    ending = presentation.state_at(2)

    assert_equal :title, title.kind
    assert_equal 1, title.position
    assert_equal 2, title.counted_total
    assert_equal "February 3–17, 2026", title.kicker
    assert_equal :authored, authored.kind
    assert_equal 2, authored.position
    assert_equal :ending, ending.kind
    assert_nil ending.position
    assert_equal 1, ending.prev_p
  end

  test "subtitle wins over a generated date line" do
    document = Memory::Document.new(
      id: 1,
      title: "Taiwan 2026",
      start_date: Date.new(2026, 2, 3),
      subtitle: "Taiwan and Hong Kong",
      pages: [Memory::Page.new]
    )
    kicker = Memory::Presentation.new(document, directory: @directory).kicker

    assert_equal "Taiwan and Hong Kong", kicker
  end

  test "two portrait images use layout B" do
    FileUtils.touch(@directory.join("a_present.jpg"))
    FileUtils.touch(@directory.join("b_present.jpg"))
    document = Memory::Document.new(
      id: 1,
      pages: [Memory::Page.new(body: "![one](a.jpg)\n![two](b.jpg)\n\n- Notes")]
    )
    presentation = Memory::Presentation.new(document, directory: @directory)

    Memory::JpegDimensions.stub :read, [80, 120] do
      state = presentation.state_at(1)
      assert_equal :b, state.layout
      assert_equal 2, state.images.size
      refute_match(/!\[/, state.commentary)
      assert_includes state.commentary, "- Notes"
    end
  end

  test "one image uses layout A and leaves extra landscape images in commentary" do
    FileUtils.touch(@directory.join("a_present.jpg"))
    FileUtils.touch(@directory.join("b_present.jpg"))
    document = Memory::Document.new(
      id: 1,
      pages: [Memory::Page.new(body: "![one](a.jpg)\n![two](b.jpg)\n\n- Notes")]
    )
    presentation = Memory::Presentation.new(document, directory: @directory)

    Memory::JpegDimensions.stub :read, [120, 80] do
      state = presentation.state_at(1)
      assert_equal :a, state.layout
      assert_equal ["a_present.jpg"], state.images.map(&:filename)
      assert_match(/!\[two\]\(b\.jpg\)/, state.commentary)
    end
  end
end
