require "test_helper"

class MemoriesTest < ActionDispatch::IntegrationTest
  test "add memory allocates a draft and opens edit" do
    assert_difference -> { Memory.count }, 1 do
      post memories_path
    end

    memory = Memory.order(:id).last
    assert_redirected_to edit_memory_path(memory)

    follow_redirect!
    assert_response :success
    assert_select "h1", "Edit Memory"
    assert_select "label", "Title"
    assert_select "label", "Start"
    assert_select "label", "End"
    assert_select "label", "Subtitle"
    assert_match "No pictures yet", response.body
    assert_select "button", "View Presentation"
    assert_select "button", "Add Page"
    assert_select ".save-state", "Saved"
  end

  test "add memory warns when an unfinished draft already exists" do
    post memories_path
    assert_no_difference -> { Memory.count } do
      post memories_path
    end

    assert_response :unprocessable_entity
    assert_match "An unfinished Memory already exists.", response.body
    assert_select "a", "Continue Draft"
    assert_select "button", "Create Another"
  end

  test "create another allocates a second draft without removing the first" do
    post memories_path
    first = Memory.order(:id).last

    post memories_path, params: { create_another: true }
    second = Memory.order(:id).last

    assert_equal 2, Memory.count
    assert_predicate first.source_pathname, :file?
    assert_predicate second.source_pathname, :file?
    assert_redirected_to edit_memory_path(second)
  end

  test "metadata persist does not rename the directory" do
    post memories_path
    memory = Memory.order(:id).last
    directory = memory.directory_name

    patch memory_path(memory), params: {
      memory: {
        title: "Taiwan 2026",
        start_date: "2026-02-03",
        end_date: "2026-02-17",
        subtitle: "Taiwan and Hong Kong"
      }
    }

    memory.reload
    assert_redirected_to edit_memory_path(memory)
    assert_equal directory, memory.directory_name
    assert_equal "Taiwan 2026", memory.title
    assert_equal "Taiwan 2026", memory.document.title
    assert_equal Date.new(2026, 2, 3), memory.start_date
    assert_equal "Taiwan and Hong Kong", memory.subtitle
  end

  test "continue draft opens the most recently modified incomplete draft" do
    older = Memory::Allocator.create!
    newer = Memory::Allocator.create!
    past = 2.days.ago.to_time
    older.source_pathname.utime(past, past)

    get continue_memories_path
    assert_redirected_to edit_memory_path(newer)
  end

  test "view presentation stays on edit and lists blocking requirements" do
    post memories_path
    memory = Memory.order(:id).last

    get edit_memory_path(memory, view_presentation: 1)
    assert_response :success
    assert_select ".readiness-errors"
    assert_select "li", "Add a title."
    assert_select "li", "Add a valid start date."
    assert_select "li", "Add at least one Memory page."
    assert_select "li", "Add at least one picture."
    assert_select "li", "Choose a key photo."
  end

  test "add page creates a blank heading rather than guessed content" do
    memory = create_draft

    patch memory_path(memory), params: editor_params(memory, intent: "add_page")
    assert_redirected_to edit_memory_path(memory, page: 1)

    memory.reload
    page = memory.document.pages.last
    assert_equal 1, memory.document.pages.size
    assert_equal "", page.heading
    assert_equal "", page.body
    markdown = memory.source_pathname.read
    assert_no_match(/Untitled/, markdown)
    assert_no_match(/#{Date.current.iso8601}/, markdown)
  end

  test "delete requires confirmation before the page is removed" do
    memory = create_draft
    patch memory_path(memory), params: editor_params(memory, intent: "add_page")
    memory.reload

    patch memory_path(memory), params: editor_params(memory, intent: "delete_page", page: 1)
    memory.reload
    assert_equal 1, memory.document.pages.size
    assert_redirected_to edit_memory_path(memory, page: 1, confirming_delete: 1)

    patch memory_path(memory), params: editor_params(memory, intent: "delete_page", page: 1, confirm_delete: "1")
    memory.reload
    assert_equal 0, memory.document.pages.size
  end

  test "deleting a page does not delete referenced image files" do
    memory = create_draft
    image = memory.directory_pathname.join("IMG_1.jpg")
    image.write("fake")
    Memory::Store.write(
      memory.document.add_blank_page.replace_page(0, heading: "", body: "![x](IMG_1.jpg)"),
      memory: memory
    )

    patch memory_path(memory), params: editor_params(memory.reload, intent: "delete_page", page: 1, confirm_delete: "1")
    memory.reload

    assert_equal 0, memory.document.pages.size
    assert_predicate image, :file?
  end

  test "move earlier and later change persisted page order" do
    memory = create_draft
    Memory::Store.write(
      memory.document.with(pages: [
        Memory::Page.new(heading: "First", body: "one"),
        Memory::Page.new(heading: "Second", body: "two")
      ]),
      memory: memory
    )

    patch memory_path(memory), params: editor_params(memory.reload, intent: "move_later", page: 1)
    memory.reload
    assert_equal ["Second", "First"], memory.document.pages.map(&:heading)

    patch memory_path(memory), params: editor_params(memory, intent: "move_earlier", page: 2)
    memory.reload
    assert_equal ["First", "Second"], memory.document.pages.map(&:heading)
  end

  test "selected page editor does not expose the complete Memory markdown" do
    memory = create_draft
    Memory::Store.write(
      memory.document.with(title: "Taiwan 2026", pages: [Memory::Page.new(heading: "Day 1", body: "- Dinner")]),
      memory: memory
    )

    get edit_memory_path(memory, page: 1)
    assert_response :success
    assert_select "textarea#memory_page_body", text: "- Dinner"
    assert_select "textarea", count: 1
    assert_no_match(/^id: /m, response.body)
    assert_select "input[name='memory[page_heading]'][value=?]", "Day 1"
  end

  test "H2 typed in a page body does not create another page and is sanitized" do
    memory = create_draft
    patch memory_path(memory), params: editor_params(memory, intent: "add_page")
    memory.reload

    patch memory_path(memory), params: editor_params(
      memory,
      page: 1,
      fields: { page_heading: "Day 1", page_body: "- Hello\n\n## Not a new page\n" }
    )
    follow_redirect!

    memory.reload
    assert_equal 1, memory.document.pages.size
    assert_equal "Not a new page", memory.document.pages.first.body.strip.split("\n").last
    assert_match(/Level-2 headings define Memory Pages/, response.body)
  end

  test "switching pages persists pending page content" do
    memory = create_draft
    patch memory_path(memory), params: editor_params(memory, intent: "add_page")
    memory.reload

    patch memory_path(memory), params: editor_params(
      memory,
      page: 1,
      select_page: "title",
      fields: { page_heading: "Day 1", page_body: "- Persisted notes" }
    )
    assert_redirected_to edit_memory_path(memory)

    memory.reload
    assert_equal "Day 1", memory.document.pages.first.heading
    assert_equal "- Persisted notes", memory.document.pages.first.body
  end

  test "incomplete drafts can persist authored pages" do
    memory = create_draft
    patch memory_path(memory), params: editor_params(memory, intent: "add_page")
    memory.reload
    patch memory_path(memory), params: editor_params(
      memory,
      page: 1,
      fields: { page_heading: "", page_body: "- Draft notes" }
    )

    memory.reload
    refute_predicate memory, :present_ready?
    assert_equal "- Draft notes", memory.document.pages.first.body
  end

  test "stale editor fingerprint is rejected without overwriting markdown" do
    memory = create_draft
    original = memory.source_pathname.read

    patch memory_path(memory), params: {
      source_fingerprint: "not-the-current-digest",
      memory: { title: "Should not save" }
    }

    assert_response :conflict
    assert_match "Memory changed outside the editor. Reload before continuing.", response.body
    assert_equal original, memory.source_pathname.read
    memory.reload
    assert_nil memory.title
  end

  test "json autosave reports saved and returns a new fingerprint" do
    memory = create_draft

    patch memory_path(memory), params: editor_params(memory, fields: { title: "Taiwan 2026" }), as: :json
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal "saved", body["status"]
    assert_equal "Saved", body["saved_label"]
    assert_equal memory.reload.source_fingerprint, body["fingerprint"]
    assert_equal "Taiwan 2026", memory.title
  end

  private

  def create_draft
    post memories_path
    Memory.order(:id).last
  end

  def editor_params(record, intent: nil, page: "title", select_page: nil, confirm_delete: nil, fields: {})
    {
      source_fingerprint: record.reload.source_fingerprint,
      page: page,
      intent: intent,
      select_page: select_page,
      confirm_delete: confirm_delete,
      memory: fields
    }.compact
  end
end
