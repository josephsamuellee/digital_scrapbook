class Memory::Presentation
  IMAGE = /!\[([^\]]*)\]\(([^)\s]+)\)/

  State = Data.define(
    :kind, :p, :prev_p, :next_p, :position, :counted_total, :kicker,
    :heading, :layout, :images, :commentary
  )
  ImageRef = Data.define(:alt, :filename, :portrait)

  def initialize(document, directory:)
    @document = document
    @directory = Pathname(directory)
  end

  def authored_count
    @document.pages.size
  end

  def counted_total
    authored_count + 1
  end

  def end_p
    authored_count + 1
  end

  def clamp_p(value)
    raw = value.to_i
    return 0 if value.blank?
    return 0 if raw.negative?
    return end_p if raw > end_p

    raw
  end

  def state_at(value)
    p = clamp_p(value)
    if p.zero?
      title_state
    elsif p <= authored_count
      authored_state(p)
    else
      ending_state
    end
  end

  def kicker
    return @document.subtitle if @document.subtitle.present?

    format_dates
  end

  private

  def title_state
    State.new(
      kind: :title,
      p: 0,
      prev_p: nil,
      next_p: authored_count.positive? ? 1 : end_p,
      position: 1,
      counted_total: counted_total,
      kicker: kicker,
      heading: nil,
      layout: :title,
      images: [],
      commentary: nil
    )
  end

  def authored_state(p)
    page = @document.pages[p - 1]
    layout, images, commentary = layout_for(page)
    State.new(
      kind: :authored,
      p: p,
      prev_p: p - 1,
      next_p: p + 1,
      position: p + 1,
      counted_total: counted_total,
      kicker: nil,
      heading: page.heading.presence,
      layout: layout,
      images: images,
      commentary: commentary
    )
  end

  def ending_state
    State.new(
      kind: :ending,
      p: end_p,
      prev_p: authored_count.positive? ? authored_count : 0,
      next_p: nil,
      position: nil,
      counted_total: counted_total,
      kicker: nil,
      heading: nil,
      layout: :ending,
      images: [],
      commentary: nil
    )
  end

  def layout_for(page)
    refs = page.body.to_s.scan(IMAGE).map { |alt, file| image_ref(alt, file) }.compact
    used = if refs.size >= 2 && refs.first(2).all?(&:portrait)
      2
    elsif refs.any?
      1
    else
      0
    end

    commentary = page.body.to_s.dup
    used.times { commentary.sub!(IMAGE, "") }
    commentary = commentary.gsub(/\n{3,}/, "\n\n").strip

    layout = case used
    when 2 then :b
    when 1 then :a
    else :text
    end

    [layout, refs.first(used), commentary]
  end

  def image_ref(alt, filename)
    base = File.basename(filename.to_s)
    return if base.blank? || base.include?("..")

    stem = File.basename(base, File.extname(base))
    present_name = "#{stem}_present.jpg"
    present_path = @directory.join(present_name)
    original_path = @directory.join(base)
    display = if present_path.file?
      present_name
    elsif original_path.file?
      base
    else
      present_name
    end

    dims = Memory::JpegDimensions.read(@directory.join(display))
    portrait = dims.present? && dims[1] > dims[0]
    ImageRef.new(alt: alt, filename: display, portrait: portrait)
  end

  def format_dates
    start_date = @document.start_date
    return unless start_date

    finish = @document.end_date
    if finish.nil? || finish == start_date
      "#{start_date.strftime("%B")} #{start_date.day}, #{start_date.year}"
    elsif finish.year == start_date.year && finish.month == start_date.month
      "#{start_date.strftime("%B")} #{start_date.day}–#{finish.day}, #{finish.year}"
    elsif finish.year == start_date.year
      "#{start_date.strftime("%B")} #{start_date.day}–#{finish.strftime("%B")} #{finish.day}, #{finish.year}"
    else
      "#{start_date.strftime("%B")} #{start_date.day}, #{start_date.year}–#{finish.strftime("%B")} #{finish.day}, #{finish.year}"
    end
  end
end
