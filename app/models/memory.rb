class Memory < ApplicationRecord
  def self.data_root
    Rails.application.config.x.data_root
  end

  def self.memories_root
    data_root.join("memories")
  end

  def self.incomplete
    all.select { |memory| memory.incomplete? }
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
end
