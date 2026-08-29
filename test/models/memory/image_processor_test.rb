require "test_helper"
require "open3"

class Memory::ImageProcessorTest < ActiveSupport::TestCase
  setup do
    @directory = Memory.memories_root.join("001-0000000001")
    FileUtils.mkdir_p(@directory)
    @processor = Memory::ImageProcessor.new(directory: @directory)
  end

  test "collision-safe names suffix IMG_1234 then IMG_1234_2" do
    @directory.join("IMG_1234.jpg").write("kept")

    stem, ext = @processor.unique_stem("IMG_1234.jpg", :jpeg)
    assert_equal "IMG_1234_2", stem
    assert_equal ".jpg", ext
  end

  test "sanitizes processing errors for the browser" do
    directory = @directory
    message = Memory::ImageProcessor.sanitize_error(
      "magick: unable to open image `#{directory.join("IMG_1234.jpg")}': no decode delegate\nheif-convert: extra detail",
      directory: directory
    )

    assert_match(/image tool/, message)
    refute_match(/\bmagick\b/i, message)
    refute_match(/heif-convert/i, message)
    refute_includes message, directory.to_s
    refute_includes message, "/Users"
  end

  test "rejects unsupported formats before processing" do
    error = assert_raises(Memory::ImageProcessor::Error) do
      @processor.process(uploaded_named("notes.png", "not-an-image"))
    end
    assert_equal "unsupported image format", error.message
    refute @directory.join("notes.png").exist?
  end

  test "JPEG upload preserves the original and writes semantic derivatives" do
    require_magick
    source = write_jpeg("source.jpg", width: 640, height: 480)

    result = @processor.process(uploaded_named("IMG_1234.jpg", source))

    assert_equal "IMG_1234.jpg", result.original_name
    assert_equal "IMG_1234_present.jpg", result.present_name
    assert_equal "IMG_1234_thumb.jpg", result.thumb_name
    assert_equal "![IMG_1234](IMG_1234.jpg)", result.markdown
    assert_equal File.binread(source), @directory.join("IMG_1234.jpg").binread
    assert @directory.join("IMG_1234_present.jpg").file?
    assert @directory.join("IMG_1234_thumb.jpg").file?
    refute_match(/_300ppi/, result.present_name)
  end

  test "presentation JPEG uses approximately quality 90" do
    require_magick
    result = @processor.process(uploaded_named("photo.jpg", write_jpeg("source.jpg", width: 400, height: 300)))
    quality = identify_format("%Q", @directory.join(result.present_name)).to_i

    assert_operator quality, :>=, 85
    assert_operator quality, :<=, 95
  end

  test "PRESENT long edge is capped at 2560 without changing aspect ratio" do
    require_magick
    result = @processor.process(uploaded_named("wide.jpg", write_jpeg("wide.jpg", width: 3000, height: 2000)))
    width, height = identify_format("%w %h", @directory.join(result.present_name)).split.map(&:to_i)

    assert_equal 2560, width
    assert_in_delta 2000.0 / 3000, height.to_f / width, 0.02
    assert_operator [width, height].max, :<=, 2560
  end

  test "smaller JPEGs are not upscaled to 2560" do
    require_magick
    result = @processor.process(uploaded_named("small.jpg", write_jpeg("small.jpg", width: 100, height: 80)))
    width, height = identify_format("%w %h", @directory.join(result.present_name)).split.map(&:to_i)

    assert_equal [100, 80], [width, height]
  end

  test "thumbnail is generated smaller than PRESENT while preserving aspect ratio" do
    require_magick
    result = @processor.process(uploaded_named("photo.jpg", write_jpeg("source.jpg", width: 1600, height: 1000)))
    present_w, present_h = identify_format("%w %h", @directory.join(result.present_name)).split.map(&:to_i)
    thumb_w, thumb_h = identify_format("%w %h", @directory.join(result.thumb_name)).split.map(&:to_i)

    assert_operator [thumb_w, thumb_h].max, :<=, Memory::ImageProcessor::THUMB_LONG_EDGE
    assert_operator thumb_w * thumb_h, :<, present_w * present_h
    assert_in_delta present_w.to_f / present_h, thumb_w.to_f / thumb_h, 0.05
  end

  test "a colliding JPEG name receives a deterministic suffix and does not overwrite" do
    require_magick
    first = write_jpeg("first.jpg", width: 120, height: 80)
    @directory.join("IMG_1234.jpg").binwrite(File.binread(first))
    original_digest = Digest::SHA256.hexdigest(@directory.join("IMG_1234.jpg").binread)

    result = @processor.process(uploaded_named("IMG_1234.jpg", write_jpeg("second.jpg", width: 80, height: 80)))

    assert_equal "IMG_1234_2.jpg", result.original_name
    assert_equal "IMG_1234_2_present.jpg", result.present_name
    assert_equal "IMG_1234_2_thumb.jpg", result.thumb_name
    assert_equal original_digest, Digest::SHA256.hexdigest(@directory.join("IMG_1234.jpg").binread)
    assert @directory.join("IMG_1234_2.jpg").file?
  end

  test "HEIC upload keeps the original and writes a JPEG master plus derivatives" do
    require_magick
    require_heif_convert
    heic = write_heic("IMG_5678.HEIC")

    result = @processor.process(uploaded_named("IMG_5678.HEIC", heic, type: "image/heic"))

    assert_equal "IMG_5678.HEIC", result.original_name
    assert_equal "IMG_5678.jpg", result.markdown_name
    assert_equal "![IMG_5678](IMG_5678.jpg)", result.markdown
    assert @directory.join("IMG_5678.HEIC").file?
    assert @directory.join("IMG_5678.jpg").file?
    assert @directory.join("IMG_5678_present.jpg").file?
    assert @directory.join("IMG_5678_thumb.jpg").file?
    assert_equal File.binread(heic), @directory.join("IMG_5678.HEIC").binread
  end

  private

  def uploaded_named(name, source, type: "image/jpeg")
    path = source.is_a?(Pathname) || File.exist?(source.to_s) ? source : @directory.join("upload-#{name}")
    unless source.is_a?(Pathname) || File.exist?(source.to_s)
      File.binwrite(path, source)
    end
    Rack::Test::UploadedFile.new(path.to_s, type, true, original_filename: name)
  end

  def write_jpeg(name, width:, height:)
    path = @directory.join("tmp-#{name}")
    stdout, stderr, status = Open3.capture3("magick", "-size", "#{width}x#{height}", "xc:#336699", path.to_s)
    flunk(stderr.presence || stdout) unless status.success?
    path
  end

  def write_heic(name)
    path = @directory.join("tmp-#{name}")
    stdout, stderr, status = Open3.capture3("magick", "-size", "32x24", "xc:#cc5533", path.to_s)
    skip "could not create a HEIC fixture with magick" unless status.success? && path.file?
    path
  end

  def identify_format(template, path)
    stdout, stderr, status = Open3.capture3("magick", "identify", "-format", template, path.to_s)
    flunk(stderr.presence || stdout) unless status.success?
    stdout
  end
end
