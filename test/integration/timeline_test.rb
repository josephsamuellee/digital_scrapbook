require "test_helper"
require "open3"

class TimelineTest < ActionDispatch::IntegrationTest
  test "empty timeline shows title, empty copy, add memory, and appearance control" do
    get root_path

    assert_response :success
    assert_select "h1", "Our Memories"
    assert_select "p", "No memories yet."
    assert_select "button", "Add Memory"
    assert_select "a", text: "Continue Draft", count: 0
    assert_select "[data-appearance-control]"
    assert_select ".year-axis", count: 0
  end

  test "default appearance is dark" do
    get root_path

    assert_response :success
    assert_select "html[data-theme=dark]"
  end

  test "appearance toggle persists in the browser without an account" do
    post appearance_path, params: { appearance: "light" }
    assert_redirected_to root_path

    follow_redirect!
    assert_select "html[data-theme=light]"

    get root_path
    assert_select "html[data-theme=light]"
  end

  test "incomplete drafts are omitted from the timeline and offer continue draft" do
    post memories_path
    get root_path

    assert_response :success
    assert_select "p", "No memories yet."
    assert_select ".year-axis", count: 0
    assert_select "a", "Continue Draft"
    assert_select "button", "Add Memory"
  end

  test "a ready Memory appears on its year with thumb, title, and PRESENT link" do
    memory = write_ready_memory

    get root_path

    assert_response :success
    assert_select "p", text: "No memories yet.", count: 0
    assert_select ".year-axis[data-year='2026']", count: 1
    assert_select ".memory-title", "Taiwan 2026"
    assert_select ".memory-item[href=?]", memory_path(memory)
    assert_select ".memory-item[data-kind=span]"
    assert_select ".memory-item[data-primary=true]"
    assert_select "img.memory-thumb[src*='_thumb']"
    assert_select "img[src*='_present']", count: 0
    assert_select ".memory-title", text: /February/, count: 0
    assert_no_match(/2026-02-03/, response.body)
    assert_select "nav.timeline-actions"
    assert_operator response.body.index("year-axis"), :<, response.body.index("timeline-actions")
  end

  test "years are reverse chronological and empty years are omitted" do
    write_ready_memory(
      title: "Taiwan 2026",
      start_date: Date.new(2026, 2, 3),
      end_date: Date.new(2026, 2, 17)
    )
    write_ready_memory(
      title: "Boston",
      start_date: Date.new(2024, 6, 1),
      end_date: Date.new(2024, 6, 10),
      key_photo: "IMG_5678.jpg"
    )

    get root_path

    years = css_select(".year-axis").map { |node| node["data-year"] }
    assert_equal %w[2026 2024], years
    assert_select ".year-axis[data-year='2025']", count: 0
    unless Date.current.year == 2024 || Date.current.year == 2026
      assert_select ".year-axis[data-year=?]", Date.current.year.to_s, count: 0
    end
  end

  test "current empty year is not rendered just because it is the current year" do
    write_ready_memory(
      title: "Boston",
      start_date: Date.new(2024, 6, 1),
      end_date: Date.new(2024, 6, 10)
    )

    get root_path

    assert_select ".year-axis[data-year='2024']"
    if Date.current.year != 2024
      assert_select ".year-axis[data-year=?]", Date.current.year.to_s, count: 0
    end
  end

  test "single-day Memories use a point marker" do
    write_ready_memory(
      title: "Birthday",
      start_date: Date.new(2026, 6, 1),
      end_date: Date.new(2026, 6, 1)
    )

    get root_path

    assert_select ".memory-item[data-kind=point]"
    assert_select ".memory-point"
    assert_select ".memory-span", count: 0
  end

  test "incomplete drafts stay off the Timeline when a ready Memory exists" do
    write_ready_memory
    post memories_path

    get root_path

    assert_select ".memory-title", "Taiwan 2026"
    assert_select ".year-axis", count: 1
    assert_select "a", "Continue Draft"
    assert_select ".memory-title", count: 1
  end

  test "cross-year Memories appear in both years with one primary label" do
    memory = write_ready_memory(
      title: "Winter",
      start_date: Date.new(2025, 12, 20),
      end_date: Date.new(2026, 3, 31)
    )

    get root_path

    assert_select ".year-axis[data-year='2026'] .memory-item.is-primary .memory-title", "Winter"
    assert_select ".year-axis[data-year='2025'] .memory-item.is-q4-continuation"
    assert_select ".year-axis[data-year='2025'] .memory-title", count: 0
    assert_select ".year-axis[data-year='2025'] img.memory-thumb"
    assert_select ".year-axis[data-year='2025'] .memory-item[href=?]", memory_path(memory)
    assert_select ".year-axis[data-year='2026'] .memory-item[href=?]", memory_path(memory)
  end

  test "Timeline GET does not invoke image processing" do
    write_ready_memory

    Open3.stub :capture3, ->(*_) { flunk "GET must not invoke Open3" } do
      get root_path
      assert_response :success
    end
  end

  test "a corrupt Memory does not prevent the Timeline from rendering others" do
    write_ready_memory
    corrupt = Memory::Allocator.create!
    corrupt.source_pathname.write("not a memory")

    logged = []
    Rails.logger.stub :error, ->(message) { logged << message } do
      get root_path
    end

    assert_response :success
    assert_select ".memory-title", "Taiwan 2026"
    assert_select "a", text: "Continue Draft", count: 0
    assert logged.any? { |message| message.to_s.include?(corrupt.id.to_s) }
  end

  test "a missing thumb still renders the Memory title" do
    write_ready_memory(thumb: false)

    get root_path

    assert_select ".memory-title", "Taiwan 2026"
    assert_select "img.memory-thumb", count: 0
  end
end
