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
    assert_select "a", "View Presentation"
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
end
