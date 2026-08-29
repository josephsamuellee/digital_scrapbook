class Memory::Readiness
  Message = Data.define(:key, :text)

  CHECKS = [
    [:missing_title, "Add a title."],
    [:missing_start_date, "Add a valid start date."],
    [:end_before_start, "End date must be on or after the start date."],
    [:no_authored_page, "Add at least one Memory page."],
    [:no_processed_picture, "Add at least one picture."],
    [:missing_key_photo, "Choose a key photo."]
  ].freeze

  def initialize(document, directory:)
    @document = document
    @directory = Pathname(directory)
  end

  def ready?
    messages.empty?
  end

  def messages
    CHECKS.filter_map do |key, text|
      Message.new(key: key, text: text) if failure?(key)
    end
  end

  private

  attr_reader :document, :directory

  def failure?(key)
    case key
    when :missing_title
      document.title.blank?
    when :missing_start_date
      document.start_date.blank?
    when :end_before_start
      document.start_date.present? && document.end_date.present? && document.end_date < document.start_date
    when :no_authored_page
      document.pages.empty?
    when :no_processed_picture
      processed_pictures.none?
    when :missing_key_photo
      document.key_photo.blank? || !directory.join(document.key_photo).file?
    end
  end

  def processed_pictures
    return [] unless directory.directory?

    directory.children.select { |path| path.basename.to_s.end_with?("_present.jpg") }
  end
end
