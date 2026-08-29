require "test_helper"

class Memory::TimelineTest < ActiveSupport::TestCase
  test "positions a date as a fraction of the calendar year" do
    expected = (Date.new(2026, 2, 3).yday - 1).to_f / 364

    assert_in_delta expected, Memory::Timeline.position(Date.new(2026, 2, 3)), 1e-9
  end

  test "uses 366 days for leap years" do
    leap = Date.new(2024, 2, 29)

    assert_equal 366, Date.new(2024, 12, 31).yday
    assert_in_delta 59.0 / 365, Memory::Timeline.position(leap), 1e-9
    refute_in_delta Memory::Timeline.position(Date.new(2025, 3, 1)),
      Memory::Timeline.position(Date.new(2024, 3, 1)),
      1e-9
  end

  test "places a multi-day Memory by start and end day within the year" do
    memory = write_ready_memory(
      start_date: Date.new(2026, 2, 3),
      end_date: Date.new(2026, 2, 17)
    )
    placement = Memory::Timeline.build.first.placements.first

    assert_equal :span, placement.kind
    assert_in_delta Memory::Timeline.position(Date.new(2026, 2, 3)), placement.start_pct, 1e-9
    assert_in_delta Memory::Timeline.position(Date.new(2026, 2, 17)), placement.end_pct, 1e-9
    assert_in_delta (placement.start_pct + placement.end_pct) / 2.0, placement.mid_pct, 1e-9
    assert_equal Date.new(2026, 2, 3), memory.start_date
    assert_equal Date.new(2026, 2, 17), memory.end_date
  end

  test "treats a single day as a point marker without changing dates" do
    memory = write_ready_memory(
      title: "Birthday",
      start_date: Date.new(2026, 6, 1),
      end_date: Date.new(2026, 6, 1)
    )
    placement = Memory::Timeline.build.first.placements.first

    assert_equal :point, placement.kind
    assert_in_delta placement.start_pct, placement.end_pct, 1e-9
    assert_equal Date.new(2026, 6, 1), memory.start_date
    assert_equal Date.new(2026, 6, 1), memory.end_date
  end

  test "a very short span keeps exact date percentages" do
    write_ready_memory(
      title: "Weekend",
      start_date: Date.new(2026, 1, 1),
      end_date: Date.new(2026, 1, 2)
    )
    placement = Memory::Timeline.build.first.placements.first

    assert_equal :span, placement.kind
    assert_in_delta Memory::Timeline.position(Date.new(2026, 1, 1)), placement.start_pct, 1e-9
    assert_in_delta Memory::Timeline.position(Date.new(2026, 1, 2)), placement.end_pct, 1e-9
    assert_operator placement.end_pct - placement.start_pct, :<, 0.01
  end

  test "splits a cross-year Memory and labels the longer year" do
    memory = write_ready_memory(
      title: "New Year",
      start_date: Date.new(2025, 12, 20),
      end_date: Date.new(2026, 1, 10)
    )
    years = Memory::Timeline.build.to_h { |year| [year.year, year.placements.first] }

    assert_equal [2026, 2025], Memory::Timeline.build.map(&:year)
    assert_equal memory.id, years[2025].memory.id
    assert_equal memory.id, years[2026].memory.id
    assert years[2025].primary
    refute years[2026].primary
    assert_equal :span, years[2025].kind
    assert_includes years[2025].title, "New Year"
    refute years[2026].compact_thumb
  end

  test "equal cross-year duration prefers the more recent year as primary" do
    write_ready_memory(
      title: "Even split",
      start_date: Date.new(2025, 12, 20),
      end_date: Date.new(2026, 1, 12)
    )
    years = Memory::Timeline.build.to_h { |year| [year.year, year.placements.first] }

    assert_equal 12, (Date.new(2025, 12, 31) - Date.new(2025, 12, 20)).to_i + 1
    assert_equal 12, (Date.new(2026, 1, 12) - Date.new(2026, 1, 1)).to_i + 1
    assert years[2026].primary
    refute years[2025].primary
  end

  test "Q4 continuation keeps a compact thumb without a competing primary label" do
    write_ready_memory(
      title: "Winter",
      start_date: Date.new(2025, 12, 20),
      end_date: Date.new(2026, 3, 31)
    )
    years = Memory::Timeline.build.to_h { |year| [year.year, year.placements.first] }

    assert years[2026].primary
    refute years[2025].primary
    assert years[2025].compact_thumb
    assert_in_delta Memory::Timeline.position(Date.new(2025, 12, 31)), years[2025].end_pct, 1e-9
  end

  test "earlier-starting overlapping Memories receive the first label lane" do
    write_ready_memory(
      title: "Memory A",
      start_date: Date.new(2026, 1, 1),
      end_date: Date.new(2026, 3, 1)
    )
    write_ready_memory(
      title: "Memory B",
      start_date: Date.new(2026, 2, 1),
      end_date: Date.new(2026, 4, 1),
      key_photo: "IMG_5678.jpg"
    )
    placements = Memory::Timeline.build.first.placements.sort_by { |placement| placement.document.title }

    assert_equal 0, placements.find { |placement| placement.title == "Memory A" }.lane
    assert_equal 1, placements.find { |placement| placement.title == "Memory B" }.lane
  end

  test "omits unparseable Memories from presentable and Continue Draft" do
    write_ready_memory
    corrupt = Memory::Allocator.create!
    corrupt.source_pathname.write("not a memory")

    logged = []
    Rails.logger.stub :error, ->(message) { logged << message } do
      years = Memory::Timeline.build
      drafts = Memory.incomplete

      assert_equal 1, years.size
      assert_equal "Taiwan 2026", years.first.placements.first.title
      assert_empty drafts
      assert logged.any? { |message| message.to_s.include?(corrupt.id.to_s) }
    end
  end
end
