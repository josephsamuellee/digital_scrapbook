require "open3"
require "fileutils"

class Memory::ImageProcessor
  class Error < StandardError; end

  PRESENT_LONG_EDGE = 2560
  THUMB_LONG_EDGE = 320
  QUALITY = 90
  JPEG_TYPES = %w[.jpg .jpeg].freeze
  HEIC_TYPES = %w[.heic].freeze

  Result = Data.define(:original_name, :markdown_name, :present_name, :thumb_name) do
    def markdown
      "![#{File.basename(markdown_name, '.*')}](#{markdown_name})"
    end
  end

  def self.magick_available?
    command_available?("magick")
  end

  def self.heif_convert_available?
    command_available?("heif-convert")
  end

  def self.command_available?(name)
    ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |dir|
      File.executable?(File.join(dir, name))
    end
  end

  def self.sanitize_error(message, directory: nil)
    text = message.to_s.gsub(/\r\n?/, "\n").lines.map(&:strip).find(&:present?).to_s
    text = text.gsub(directory.to_s, "[memory]") if directory
    text = text.gsub(%r{(?:/[^\s]+){2,}}, "[path]")
    text = text.gsub(/\b(?:magick|heif-convert)\b/i, "image tool")
    text = text[0, 180]
    text.presence || "the image could not be processed"
  end

  def initialize(directory:)
    @directory = Pathname(directory)
  end

  def process(uploaded)
    filename = uploaded.original_filename.to_s
    kind = classify(filename)
    require_tools!(kind)
    stem, original_ext = unique_stem(filename, kind)

    FileUtils.mkdir_p(@directory)
    original_name = "#{stem}#{original_ext}"
    original_path = @directory.join(original_name)
    copy_upload(uploaded, original_path)

    jpeg_source = original_path
    markdown_name = original_name
    if kind == :heic
      markdown_name = "#{stem}.jpg"
      jpeg_source = @directory.join(markdown_name)
      convert_heic(original_path, jpeg_source)
    end

    present_name = "#{stem}_present.jpg"
    thumb_name = "#{stem}_thumb.jpg"
    write_derivative(jpeg_source, @directory.join(present_name), PRESENT_LONG_EDGE)
    write_derivative(jpeg_source, @directory.join(thumb_name), THUMB_LONG_EDGE)

    Result.new(
      original_name: original_name,
      markdown_name: markdown_name,
      present_name: present_name,
      thumb_name: thumb_name
    )
  end

  def classify(filename)
    ext = File.extname(filename).downcase
    return :jpeg if JPEG_TYPES.include?(ext)
    return :heic if HEIC_TYPES.include?(ext)

    raise Error, "unsupported image format"
  end

  def unique_stem(filename, kind)
    ext = original_ext_for(filename, kind)
    stem = sanitize_stem(File.basename(filename, ".*"))
    return [stem, ext] unless name_taken?(stem, kind, ext)

    n = 2
    loop do
      candidate = "#{stem}_#{n}"
      return [candidate, ext] unless name_taken?(candidate, kind, ext)

      n += 1
    end
  end

  private

  def require_tools!(kind)
    unless self.class.magick_available?
      raise Error, "image processing is not available on this machine"
    end
    return unless kind == :heic
    return if self.class.heif_convert_available?

    raise Error, "HEIC conversion is not available on this machine"
  end

  def original_ext_for(filename, kind)
    ext = File.extname(filename)
    return ext if ext.present?

    kind == :heic ? ".HEIC" : ".jpg"
  end

  def sanitize_stem(stem)
    cleaned = stem.to_s.gsub(/[^A-Za-z0-9._-]/, "_").gsub(/_+/, "_").gsub(/\A_+|_+\z/, "")
    cleaned.presence || "image"
  end

  def name_taken?(stem, kind, original_ext)
    names = ["#{stem}#{original_ext}", "#{stem}_present.jpg", "#{stem}_thumb.jpg"]
    names << "#{stem}.jpg" if kind == :heic
    names.any? { |name| @directory.join(name).exist? }
  end

  def copy_upload(uploaded, dest)
    if uploaded.respond_to?(:tempfile)
      FileUtils.cp(uploaded.tempfile.path, dest)
    else
      IO.copy_stream(uploaded, dest)
    end
  end

  def convert_heic(source, jpeg_dest)
    run!("heif-convert", source.to_s, jpeg_dest.to_s)
    run!(
      "magick",
      jpeg_dest.to_s,
      "-auto-orient",
      "-quality", QUALITY.to_s,
      jpeg_dest.to_s
    )
  end

  def write_derivative(source, dest, long_edge)
    run!(
      "magick",
      source.to_s,
      "-auto-orient",
      "-resize", "#{long_edge}x#{long_edge}>",
      "-quality", QUALITY.to_s,
      dest.to_s
    )
  end

  def run!(*argv)
    stdout, stderr, status = Open3.capture3(*argv)
    return stdout if status.success?

    Rails.logger.error("Image processing failed (#{argv.first}): #{stderr.presence || stdout}")
    raise Error, self.class.sanitize_error(stderr.presence || stdout, directory: @directory)
  rescue Errno::ENOENT
    Rails.logger.error("Image processing command missing: #{argv.first}")
    raise Error, "image processing is not available on this machine"
  end
end
