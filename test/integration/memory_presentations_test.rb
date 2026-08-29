require "test_helper"
require "open3"

class MemoryPresentationsTest < ActionDispatch::IntegrationTest
  test "view presentation stays on edit when the Memory is incomplete" do
    memory = create_draft

    patch memory_path(memory), params: editor_params(memory).merge(view_presentation: "1")
    assert_redirected_to edit_memory_path(memory, view_presentation: 1)

    follow_redirect!
    assert_select ".readiness-errors"
    assert_select "li", "Add a title."
    assert_select "li", "Add a valid start date."
    assert_select "li", "Add at least one Memory page."
    assert_select "li", "Add at least one picture."
    assert_select "li", "Choose a key photo."
  end

  test "incomplete PRESENT GET redirects to edit with readiness" do
    memory = create_draft

    get memory_path(memory)
    assert_redirected_to edit_memory_path(memory, view_presentation: 1)
  end

  test "view presentation opens PRESENT for a ready Memory" do
    memory = create_ready_memory

    patch memory_path(memory), params: editor_params(memory).merge(view_presentation: "1")
    assert_redirected_to memory_path(memory)
  end

  test "PRESENT opens on a generated title page" do
    memory = create_ready_memory

    get memory_path(memory)
    assert_response :success
    assert_select "body.is-present"
    assert_select ".present-title h1", "Taiwan 2026"
    assert_select ".present-kicker", "Taiwan and Hong Kong"
    assert_select ".present-position", "1 / 2"
    assert_select "a.present-next"
    assert_select "span.present-prev.is-disabled"
    assert_select "[data-controller=presentation]"
    assert_select "[data-presentation-next-url-value=?]", memory_path(memory, p: 1)
    assert_select "[data-presentation-prev-url-value=?]", ""
  end

  test "title page uses a date line when subtitle is blank" do
    memory = create_ready_memory(subtitle: nil)

    get memory_path(memory)
    assert_select ".present-kicker", "February 3–17, 2026"
  end

  test "authored pages follow H2 order and count the title" do
    memory = create_ready_memory(pages: [
      Memory::Page.new(heading: "February 4", body: "![Taipei](IMG_1234.jpg)\n\n- Arrived"),
      Memory::Page.new(heading: "February 5", body: "- Zoo")
    ])

    get memory_path(memory, p: 1)
    assert_select "h2", "February 4"
    assert_select ".present-position", "2 / 3"
    assert_select "img[src*='_present']"
    assert_select "li", /Arrived/
    assert_select ".present-nav a.present-prev"
    assert_select ".present-nav a.present-next"
    assert_select ".present-canvas a.present-prev", count: 0
    assert_select ".present-canvas a.present-next", count: 0

    get memory_path(memory, p: 2)
    assert_select "h2", "February 5"
    assert_select ".present-position", "3 / 3"
    assert_select "li", /Zoo/
  end

  test "end state links back to timeline and edit" do
    memory = create_ready_memory

    get memory_path(memory, p: 2)
    assert_response :success
    assert_select "a", "Back to Timeline"
    assert_select "a", "Edit Memory"
    assert_select "a.present-prev[href=?]", memory_path(memory, p: 1)
    assert_select "span.present-next.is-disabled"
    assert_select ".present-position:not(.present-position-empty)", count: 0
  end

  test "PRESENT GET does not invoke image processing" do
    memory = create_ready_memory

    Open3.stub :capture3, ->(*_) { flunk "GET must not invoke Open3" } do
      get memory_path(memory)
      assert_response :success
      get memory_path(memory, p: 1)
      assert_response :success
      get root_path
      assert_response :success
    end
  end

  private

  def create_draft
    post memories_path
    Memory.order(:id).last
  end

  def create_ready_memory(subtitle: "Taiwan and Hong Kong", pages: nil)
    write_ready_memory(
      subtitle: subtitle,
      pages: pages || [
        Memory::Page.new(heading: "February 4", body: "![Taipei](IMG_1234.jpg)\n\n- Arrived in Taipei")
      ]
    )
  end

  def editor_params(record, intent: nil, page: "title", fields: {})
    {
      source_fingerprint: record.reload.source_fingerprint,
      page: page,
      intent: intent,
      memory: fields
    }.compact
  end
end
