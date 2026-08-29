class Memory::Markdown
  class ParseError < StandardError; end

  FRONT_MATTER = /\A---[ \t]*\r?\n(.*?)\r?\n---[ \t]*\r?\n?(.*)\z/m
  H2_BOUNDARY = /^##(?!#)(?: |$)/

  def self.parse(text)
    match = text.to_s.match(FRONT_MATTER)
    raise ParseError, "missing YAML front matter" unless match

    data = Psych.safe_load(match[1], permitted_classes: [Date], symbolize_names: false)
    raise ParseError, "front matter must be a mapping" unless data.is_a?(Hash)
    raise ParseError, "id is required" if data["id"].nil?

    Memory::Document.new(
      id: data["id"],
      title: data["title"],
      start_date: coerce_date(data["start_date"]),
      end_date: coerce_date(data["end_date"]),
      key_photo: data["key_photo"],
      subtitle: data["subtitle"],
      pages: parse_pages(match[2].to_s)
    )
  rescue Psych::Exception => error
    raise ParseError, error.message
  end

  def self.serialize(document)
    front = { "id" => document.id }
    front["title"] = document.title if document.title
    front["start_date"] = document.start_date.iso8601 if document.start_date
    front["end_date"] = document.end_date.iso8601 if document.end_date
    front["key_photo"] = document.key_photo if document.key_photo
    front["subtitle"] = document.subtitle if document.subtitle

    yaml = Psych.dump(front, line_width: -1)
    yaml = yaml.sub(/\A---\s*\n/, "").sub(/\n\.\.\.\s*\z/, "")

    parts = ["---", yaml.rstrip, "---"]
    if document.title
      parts << ""
      parts << "# #{document.title}"
      parts << ""
      parts << document.subtitle if document.subtitle
    end

    document.pages.each do |page|
      parts << ""
      parts << (page.heading.empty? ? "##" : "## #{page.heading}")
      parts << ""
      parts << page.body.rstrip unless page.body.blank?
    end

    "#{parts.join("\n").gsub(/\n{3,}/, "\n\n").rstrip}\n"
  end

  def self.parse_pages(body)
    return [] unless body.match?(H2_BOUNDARY)

    _preamble, *chunks = body.split(H2_BOUNDARY)
    chunks.map do |chunk|
      heading, sep, rest = chunk.partition("\n")
      body_text = sep.empty? ? "" : rest
      Memory::Page.new(
        heading: heading.to_s.rstrip,
        body: body_text.sub(/\A\r?\n/, "").sub(/\r?\n+\z/, "")
      )
    end
  end
  private_class_method :parse_pages

  def self.coerce_date(value)
    return if value.blank?
    return value if value.is_a?(Date)

    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end
  private_class_method :coerce_date
end
