class Memory::Reconciler
  def self.run
    grouped = discovered_documents
    grouped.each do |id, files|
      apply_group(id, files)
    end
    log_missing_markdown
  end

  def self.discovered_documents
    root = Memory.memories_root
    return {} unless root.directory?

    grouped = Hash.new { |hash, id| hash[id] = [] }
    root.children.each do |dir|
      next unless dir.directory?

      path = dir.join("memory.md")
      next unless path.file?

      begin
        document = Memory::Markdown.parse(path.read)
        grouped[document.id] << [path, document]
      rescue Memory::Markdown::ParseError => error
        Rails.logger.error("Memory Markdown at #{relative_source(path)} could not be parsed: #{error.message}")
      end
    end
    grouped
  end
  private_class_method :discovered_documents

  def self.apply_group(id, files)
    if files.size > 1
      paths = files.map { |path, _| relative_source(path) }
      Rails.logger.error(
        "Ambiguous Memory #{id} has multiple Markdown sources (#{paths.join(", ")}); manual resolution required"
      )
      record = Memory.find_by(id: id)
      associated = files.find { |path, _| relative_source(path) == record&.source_path }
      apply_file(id, associated[0], associated[1]) if associated
      return
    end

    path, document = files.first
    apply_file(id, path, document)
  end
  private_class_method :apply_group

  def self.apply_file(id, path, document)
    relative = relative_source(path)
    occupant = Memory.find_by(source_path: relative)
    if occupant && occupant.id != id
      Rails.logger.error(
        "Memory #{id} at #{relative} conflicts with Memory #{occupant.id}; manual resolution required"
      )
      return
    end

    record = Memory.find_by(id: id)
    if record.nil?
      record = Memory.new(id: id, source_path: relative)
      Memory::Store.index!(record, document, path)
      Rails.logger.info("Imported Memory #{id} from #{relative}")
      return
    end

    if record.source_path != relative
      Rails.logger.info("Updated Memory #{id} source path from #{record.source_path} to #{relative}")
      record.source_path = relative
      Memory::Store.index!(record, document, path)
      return
    end

    Memory::Store.reindex_if_stale(record, document)
  end
  private_class_method :apply_file

  def self.log_missing_markdown
    Memory.find_each do |memory|
      next if memory.source_readable?

      Rails.logger.error(
        "Memory #{memory.id} Markdown is missing at #{memory.source_path}; not regenerating from SQLite"
      )
    end
  end
  private_class_method :log_missing_markdown

  def self.relative_source(path)
    path.relative_path_from(Memory.data_root).to_s
  end
  private_class_method :relative_source
end
