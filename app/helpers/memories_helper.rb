module MemoriesHelper
  def present_commentary_html(text)
    rewritten = text.to_s.gsub(Memory::Presentation::IMAGE) do
      alt = Regexp.last_match(1)
      file = File.basename(Regexp.last_match(2).to_s)
      stem = File.basename(file, File.extname(file))
      present = "#{stem}_present.jpg"
      display = @memory.directory_pathname.join(present).file? ? present : file
      "![#{alt}](#{present_asset_url(display)})"
    end
    sanitize Memory::PageHtml.render(rewritten), tags: %w[p ul li strong em br img], attributes: %w[src alt]
  end
end
