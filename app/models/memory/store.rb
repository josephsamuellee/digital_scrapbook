require "digest"
require "fileutils"

class Memory::Store
  class WriteError < StandardError; end

  def self.write(document, memory:)
    path = memory.source_pathname
    dir = path.dirname
    FileUtils.mkdir_p(dir)
    tmp = dir.join("memory.md.tmp")
    markdown = Memory::Markdown.serialize(document)

    begin
      File.open(tmp, File::WRONLY | File::CREAT | File::TRUNC) do |io|
        io.write(markdown)
        io.flush
        io.fsync
      end
      File.rename(tmp, path)
    rescue SystemCallError, IOError
      FileUtils.rm_f(tmp) if tmp.file?
      raise WriteError, "Could not save Memory."
    end

    index!(memory, document, path)
  rescue ActiveRecord::ActiveRecordError => error
    Rails.logger.error(
      "SQLite index failed after Markdown write for Memory #{document.id}: #{error.class}: #{error.message}"
    )
    raise if memory.new_record?

    memory
  end

  def self.reindex_if_stale(memory, document)
    path = memory.source_pathname
    return memory unless path.exist?

    digest = Digest::SHA256.hexdigest(path.binread)
    return memory if memory.source_fingerprint == digest

    index!(memory, document, path)
  end

  def self.index!(memory, document, path)
    memory.assign_attributes(
      title: document.title,
      subtitle: document.subtitle,
      key_photo: document.key_photo,
      start_date: document.start_date,
      end_date: document.end_date,
      source_fingerprint: Digest::SHA256.hexdigest(File.binread(path)),
      source_modified_at: path.mtime
    )
    memory.save!
    memory
  end
  private_class_method :index!
end
