class Memory::Timeline
  Year = Data.define(:year, :placements) do
    def lane_count
      (placements.map(&:lane).max || 0) + 1
    end

    def quarters
      {
        "Q2" => Memory::Timeline.position(Date.new(year, 4, 1)),
        "Q3" => Memory::Timeline.position(Date.new(year, 7, 1)),
        "Q4" => Memory::Timeline.position(Date.new(year, 10, 1))
      }
    end
  end

  Placement = Data.define(
    :memory,
    :document,
    :year,
    :kind,
    :primary,
    :compact_thumb,
    :start_pct,
    :end_pct,
    :mid_pct,
    :lane,
    :slice_start,
    :slice_end
  ) do
    def title
      document.title
    end

    def thumb_name
      return if document.key_photo.blank?

      "#{File.basename(document.key_photo, ".*")}_thumb.jpg"
    end

    def thumb?
      name = thumb_name
      name.present? && memory.directory_pathname.join(name).file?
    end

    def point?
      kind == :point
    end

    def span?
      kind == :span
    end

    def css_start
      css_percent(start_pct)
    end

    def css_width
      css_percent([end_pct - start_pct, 0].max)
    end

    def css_percent(value)
      "#{(value * 100).round(4)}%"
    end
  end

  Slice = Data.define(:year, :start_date, :end_date, :days)

  def self.position(date)
    days = Date.new(date.year, 12, 31).yday
    (date.yday - 1).to_f / (days - 1)
  end

  def self.build(records = Memory.all)
    by_year = Hash.new { |hash, year| hash[year] = [] }

    Memory.presentable(records).each do |memory, document|
      slices = year_slices(document.start_date, document.end_date || document.start_date)
      primary_year = primary_year_for(slices)

      slices.each do |slice|
        by_year[slice.year] << placement_for(memory, document, slice, primary_year)
      end
    end

    by_year.keys.sort.reverse.map do |year|
      Year.new(year: year, placements: assign_lanes(by_year[year]))
    end
  end

  def self.year_slices(start_date, finish)
    (start_date.year..finish.year).map do |year|
      slice_start = [start_date, Date.new(year, 1, 1)].max
      slice_end = [finish, Date.new(year, 12, 31)].min
      Slice.new(
        year: year,
        start_date: slice_start,
        end_date: slice_end,
        days: (slice_end - slice_start).to_i + 1
      )
    end
  end

  def self.primary_year_for(slices)
    slices.max_by { |slice| [slice.days, slice.year] }.year
  end

  def self.placement_for(memory, document, slice, primary_year)
    start_pct = position(slice.start_date)
    end_pct = position(slice.end_date)
    primary = slice.year == primary_year

    Placement.new(
      memory: memory,
      document: document,
      year: slice.year,
      kind: slice.start_date == slice.end_date ? :point : :span,
      primary: primary,
      compact_thumb: !primary && slice.end_date.month >= 10,
      start_pct: start_pct,
      end_pct: end_pct,
      mid_pct: (start_pct + end_pct) / 2.0,
      lane: 0,
      slice_start: slice.start_date,
      slice_end: slice.end_date
    )
  end

  def self.assign_lanes(placements)
    occupied = []
    placements.sort_by { |placement| [placement.slice_start, placement.memory.id] }.map do |placement|
      lane = occupied.index { |last_end| placement.slice_start > last_end } || occupied.length
      occupied[lane] = placement.slice_end
      placement.with(lane: lane)
    end
  end
  private_class_method :year_slices, :primary_year_for, :placement_for, :assign_lanes
end
