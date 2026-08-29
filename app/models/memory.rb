class Memory < ApplicationRecord
  def self.data_root
    Rails.application.config.x.data_root
  end

  def self.memories_root
    data_root.join("memories")
  end

  def self.with_parsed_documents(records = all)
    records.filter_map do |memory|
      next unless memory.source_readable?

      begin
        document = memory.document
        Memory::Store.reindex_if_stale(memory, document)
        [memory, document]
      rescue Memory::Markdown::ParseError, Errno::ENOENT => error
        Rails.logger.error("Memory #{memory.id} could not be loaded: #{error.message}")
        nil
      end
    end
  end

  def self.presentable(records = all)
    with_parsed_documents(records).select do |memory, document|
      Memory::Readiness.new(document, directory: memory.directory_pathname).ready?
    end
  end

  def self.incomplete
    with_parsed_documents.filter_map do |memory, document|
      next if Memory::Readiness.new(document, directory: memory.directory_pathname).ready?

      memory
    end
  end

  def self.most_recent_incomplete
    incomplete.max_by { |memory| memory.source_mtime || memory.updated_at }
  end

  def source_pathname
    self.class.data_root.join(source_path)
  end

  def directory_pathname
    source_pathname.dirname
  end

  def directory_name
    directory_pathname.basename.to_s
  end

  def source_mtime
    return unless source_pathname.exist?

    source_pathname.mtime
  end

  def source_readable?
    source_pathname.file?
  end

  def document
    Memory::Markdown.parse(source_pathname.read)
  end

  def present_ready?
    Memory::Readiness.new(document, directory: directory_pathname).ready?
  rescue Memory::Markdown::ParseError, Errno::ENOENT => error
    Rails.logger.error("Memory #{id} is not PRESENT-ready: #{error.message}")
    false
  end

  def incomplete?
    !present_ready?
  end

  def original_jpeg_names
    return [] unless directory_pathname.directory?

    directory_pathname.children.filter_map do |path|
      next unless path.file?

      name = path.basename.to_s
      next unless name.match?(/\.(jpg|jpeg)\z/i)
      next if name.match?(/_(?:present|thumb)\.jpg\z/i)

      name
    end.sort
  end
end
