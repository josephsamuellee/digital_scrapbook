class Memory::Document
  attr_reader :id, :title, :start_date, :end_date, :key_photo, :subtitle, :pages

  def initialize(id:, title: nil, start_date: nil, end_date: nil, key_photo: nil, subtitle: nil, pages: [])
    @id = Integer(id)
    @title = blank_to_nil(title)
    @start_date = start_date
    @end_date = end_date
    @key_photo = blank_to_nil(key_photo)
    @subtitle = blank_to_nil(subtitle)
    @pages = Array(pages)
  end

  def with(**attrs)
    self.class.new(
      id: attrs.fetch(:id, id),
      title: attrs.fetch(:title, title),
      start_date: attrs.fetch(:start_date, start_date),
      end_date: attrs.fetch(:end_date, end_date),
      key_photo: attrs.fetch(:key_photo, key_photo),
      subtitle: attrs.fetch(:subtitle, subtitle),
      pages: attrs.fetch(:pages, pages)
    )
  end

  def ==(other)
    other.is_a?(self.class) &&
      id == other.id &&
      title == other.title &&
      start_date == other.start_date &&
      end_date == other.end_date &&
      key_photo == other.key_photo &&
      subtitle == other.subtitle &&
      pages == other.pages
  end

  private

  def blank_to_nil(value)
    value.presence
  end
end
