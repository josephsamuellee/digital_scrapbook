class Memory::Allocator
  SUFFIX_RANGE = 10**10
  MAX_SUFFIX_ATTEMPTS = 25

  def self.create!
    id = next_id
    dir_name = "#{format("%03d", id)}-#{unique_suffix(id)}"
    memory = Memory.new(
      id: id,
      source_path: "memories/#{dir_name}/memory.md"
    )
    memory = Memory::Store.write(Memory::Document.new(id: id), memory: memory)
    raise Memory::Store::WriteError, "Could not save Memory." unless memory.persisted?

    memory
  end

  def self.next_id
    sqlite_max = Memory.maximum(:id).to_i
    filesystem_max = filesystem_ids.max || 0
    [sqlite_max, filesystem_max].max + 1
  end
  private_class_method :next_id

  def self.filesystem_ids
    root = Memory.memories_root
    return [] unless root.directory?

    root.children.filter_map do |entry|
      entry.basename.to_s[/\A(\d+)-/, 1]&.to_i
    end
  end
  private_class_method :filesystem_ids

  def self.unique_suffix(id)
    MAX_SUFFIX_ATTEMPTS.times do
      suffix = format("%010d", SecureRandom.random_number(SUFFIX_RANGE))
      dir_name = "#{format("%03d", id)}-#{suffix}"
      return suffix unless Memory.memories_root.join(dir_name).exist?
    end

    raise Memory::Store::WriteError, "Could not allocate a unique Memory directory."
  end
  private_class_method :unique_suffix
end
