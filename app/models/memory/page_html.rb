require "erb"

class Memory::PageHtml
  IMAGE = /!\[([^\]]*)\]\(([^)\s]+)\)/

  def self.render(text)
    blocks = text.to_s.gsub("\r\n", "\n").split(/\n{2,}/)
    blocks.filter_map { |block| render_block(block) }.join
  end

  def self.render_block(block)
    lines = block.lines.map { |line| line.sub(/\n\z/, "") }
    list_lines = lines.select { |line| line.start_with?("- ") }
    if list_lines.any? && lines.all? { |line| line.blank? || line.start_with?("- ") }
      items = list_lines.map { |line| "<li>#{inline(line.delete_prefix("- "))}</li>" }
      return "<ul>#{items.join}</ul>"
    end

    stripped = lines.join("\n").strip
    return if stripped.blank?

    "<p>#{inline(stripped)}</p>"
  end
  private_class_method :render_block

  def self.inline(text)
    html = ERB::Util.html_escape(text)
    html = html.gsub(IMAGE) do
      alt = ::Regexp.last_match(1)
      src = ::Regexp.last_match(2)
      %(<img src="#{src}" alt="#{alt}">)
    end
    html = html.gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
    html = html.gsub(/(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)/, '<em>\1</em>')
    html.gsub("\n", "<br>")
  end
  private_class_method :inline
end
