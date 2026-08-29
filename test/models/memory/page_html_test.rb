require "test_helper"

class Memory::PageHtmlTest < ActiveSupport::TestCase
  test "renders bullet lists and emphasis without exposing Markdown markers as a heading" do
    html = Memory::PageHtml.render("- Arrived in **Taipei**\n- Dinner with *family*")

    assert_includes html, "<ul>"
    assert_includes html, "<li>Arrived in <strong>Taipei</strong></li>"
    assert_includes html, "<em>family</em>"
    assert_no_match(/##/, html)
  end

  test "escapes HTML in commentary" do
    html = Memory::PageHtml.render("<script>alert(1)</script>")

    assert_includes html, "&lt;script&gt;"
    refute_includes html, "<script>"
  end
end
