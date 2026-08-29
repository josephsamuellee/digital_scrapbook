require "test_helper"

class Memory::JpegDimensionsTest < ActiveSupport::TestCase
  test "reads width and height from a JPEG without magick" do
    width, height = Memory::JpegDimensions.read(file_fixture("sample.jpg"))

    assert_operator width, :>, 0
    assert_operator height, :>, 0
  end

  test "returns nil for a non-image file" do
    path = Memory.memories_root.join("notes.txt")
    FileUtils.mkdir_p(path.dirname)
    path.write("not a jpeg")

    assert_nil Memory::JpegDimensions.read(path)
  end
end
