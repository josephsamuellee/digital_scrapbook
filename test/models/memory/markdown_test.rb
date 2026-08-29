require "test_helper"

class Memory::MarkdownTest < ActiveSupport::TestCase
  test "serializes an incomplete draft with only a stable id" do
    markdown = Memory::Markdown.serialize(Memory::Document.new(id: 1))

    assert_match(/\A---\n/, markdown)
    assert_match(/^id: 1$/, markdown)
    assert_no_match(/^title:/, markdown)
    assert_no_match(/^# /, markdown)
  end

  test "parses YAML front matter including portable metadata and H2 pages" do
    markdown = <<~MARKDOWN
      ---
      id: 42
      title: Taiwan 2026
      start_date: 2026-02-03
      end_date: 2026-02-17
      key_photo: IMG_1234.jpg
      subtitle: Taiwan and Hong Kong
      ---

      # Taiwan 2026

      Taiwan and Hong Kong

      ## February 4

      ![Taipei](IMG_1234.jpg)

      - Arrived in Taipei

      ## February 5

      - Taipei Zoo
    MARKDOWN

    document = Memory::Markdown.parse(markdown)

    assert_equal 42, document.id
    assert_equal "Taiwan 2026", document.title
    assert_equal Date.new(2026, 2, 3), document.start_date
    assert_equal Date.new(2026, 2, 17), document.end_date
    assert_equal "IMG_1234.jpg", document.key_photo
    assert_equal "Taiwan and Hong Kong", document.subtitle
    assert_equal 2, document.pages.size
    assert_equal "February 4", document.pages.first.heading
    assert_includes document.pages.first.body, "![Taipei](IMG_1234.jpg)"
    assert_equal "February 5", document.pages.last.heading
  end

  test "round-trip preserves semantic Memory content" do
    original = Memory::Document.new(
      id: 42,
      title: "Taiwan 2026",
      start_date: Date.new(2026, 2, 3),
      end_date: Date.new(2026, 2, 17),
      key_photo: "IMG_1234.jpg",
      subtitle: "Taiwan and Hong Kong",
      pages: [
        Memory::Page.new(heading: "February 4", body: "![Taipei](IMG_1234.jpg)\n\n- Arrived in Taipei"),
        Memory::Page.new(heading: "", body: "- Untitled page")
      ]
    )

    parsed = Memory::Markdown.parse(Memory::Markdown.serialize(original))

    assert_equal original, parsed
  end

  test "round-trip preserves an empty draft" do
    original = Memory::Document.new(id: 7)

    assert_equal original, Memory::Markdown.parse(Memory::Markdown.serialize(original))
  end

  test "rejects Markdown without front matter" do
    assert_raises(Memory::Markdown::ParseError) do
      Memory::Markdown.parse("# Taiwan\n")
    end
  end
end
