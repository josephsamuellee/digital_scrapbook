require "test_helper"
require "open3"

class MemoryImagesTest < ActionDispatch::IntegrationTest
  test "JPEG upload stores original present and thumb and returns markdown only after success" do
    memory = create_draft_with_page
    jpeg = file_fixture("sample.jpg")

    with_fake_magick do
      post memory_images_path(memory), params: {
        source_fingerprint: memory.source_fingerprint,
        image: uploaded_jpeg(jpeg, "IMG_1234.jpg")
      }
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "![IMG_1234](IMG_1234.jpg)", body["markdown"]
    assert_equal "IMG_1234.jpg", body["key_photo"]
    assert_equal memory.reload.source_fingerprint, body["fingerprint"]
    assert_equal jpeg.binread, memory.directory_pathname.join("IMG_1234.jpg").binread
    assert memory.directory_pathname.join("IMG_1234_present.jpg").file?
    assert memory.directory_pathname.join("IMG_1234_thumb.jpg").file?
    refute_match(/_300ppi/, memory.directory_pathname.join("IMG_1234_present.jpg").basename.to_s)
    refute_match(/!\[/, memory.source_pathname.read)
    assert_equal "IMG_1234.jpg", memory.reload.document.key_photo

    prefix = "ab"
    suffix = "cd"
    patch memory_path(memory), params: editor_params(
      memory,
      page: 1,
      fields: { page_body: "#{prefix}#{body["markdown"]}#{suffix}" }
    )
    memory.reload
    assert_equal "ab![IMG_1234](IMG_1234.jpg)cd", memory.document.pages.first.body
  end

  test "first upload defaults key photo and a later select can change it" do
    memory = create_draft_with_page
    jpeg = file_fixture("sample.jpg")

    with_fake_magick do
      post memory_images_path(memory), params: {
        source_fingerprint: memory.source_fingerprint,
        image: uploaded_jpeg(jpeg, "one.jpg")
      }
    end
    assert_equal "one.jpg", JSON.parse(response.body)["key_photo"]
    memory.reload
    assert_equal "one.jpg", memory.document.key_photo

    with_fake_magick do
      post memory_images_path(memory), params: {
        source_fingerprint: memory.source_fingerprint,
        image: uploaded_jpeg(jpeg, "two.jpg")
      }
    end
    assert_equal "one.jpg", JSON.parse(response.body)["key_photo"]

    patch memory_path(memory), params: editor_params(memory, fields: { key_photo: "two.jpg" })
    memory.reload
    assert_equal "two.jpg", memory.document.key_photo

    get edit_memory_path(memory, page: 1)
    assert_select "select[name='memory[key_photo]'] option[value='two.jpg'][selected]"
  end

  test "colliding JPEG names are suffixed and the original file is not overwritten" do
    memory = create_draft_with_page
    existing = memory.directory_pathname.join("IMG_1234.jpg")
    existing.binwrite("original-bytes")

    with_fake_magick do
      post memory_images_path(memory), params: {
        source_fingerprint: memory.source_fingerprint,
        image: uploaded_jpeg(file_fixture("sample.jpg"), "IMG_1234.jpg")
      }
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "![IMG_1234_2](IMG_1234_2.jpg)", body["markdown"]
    assert_equal "original-bytes", existing.read
    assert memory.directory_pathname.join("IMG_1234_2.jpg").file?
    assert memory.directory_pathname.join("IMG_1234_2_present.jpg").file?
    assert memory.directory_pathname.join("IMG_1234_2_thumb.jpg").file?
  end

  test "failed magick returns a sanitized error and does not insert markdown" do
    memory = create_draft_with_page
    original = memory.source_pathname.read
    fail_status = Open3.capture3("false").last

    Memory::ImageProcessor.stub :magick_available?, true do
      Open3.stub :capture3, lambda { |*_argv|
        ["", "magick: no decode delegate `/secret/data/memories/001/IMG_1234.jpg'", fail_status]
      } do
        post memory_images_path(memory), params: {
          source_fingerprint: memory.source_fingerprint,
          image: fixture_file_upload("sample.jpg", "image/jpeg")
        }
      end
    end

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_match(/\AImage processing failed: /, body["message"])
    refute_match(/\bmagick\b/i, body["message"])
    refute_includes body["message"], "/secret"
    refute_includes body["message"], "magick "
    assert_equal original, memory.source_pathname.read
    refute_match(/!\[/, memory.source_pathname.read)
    assert_nil memory.reload.document.key_photo
  end

  test "stale fingerprint is rejected before processing" do
    memory = create_draft_with_page

    post memory_images_path(memory), params: {
      source_fingerprint: "not-the-current-digest",
      image: fixture_file_upload("sample.jpg", "image/jpeg")
    }

    assert_response :conflict
    assert_equal 0, memory.directory_pathname.children.count { |path| path.extname.match?(/\A\.(jpg|jpeg|heic)\z/i) }
  end

  test "timeline and edit GET do not invoke image processing" do
    memory = create_draft_with_page
    memory.directory_pathname.join("IMG_1234.jpg").write("bytes")

    Open3.stub :capture3, ->(*_) { flunk "GET must not invoke Open3" } do
      get root_path
      assert_response :success
      get edit_memory_path(memory)
      assert_response :success
      get edit_memory_path(memory, page: 1)
      assert_response :success
      get memory_asset_path(memory, filename: "IMG_1234.jpg")
      assert_response :success
    end
  end

  test "asset GET serves files inside the Memory directory and rejects traversal" do
    memory = create_draft_with_page
    memory.directory_pathname.join("IMG_1234.jpg").binwrite(file_fixture("sample.jpg").binread)

    get memory_asset_path(memory, filename: "IMG_1234.jpg")
    assert_response :success
    assert_equal file_fixture("sample.jpg").binread, response.body

    get memory_asset_path(memory, filename: "../memory.md")
    assert_response :not_found

    get "/memories/#{memory.id}/assets/%2e%2e/memory.md"
    assert_response :not_found
  end

  test "page editor exposes upload at cursor and title selection does not" do
    memory = create_draft_with_page

    get edit_memory_path(memory)
    assert_response :success
    assert_select "label", text: "Add picture at editor cursor", count: 0
    assert_match "No pictures yet", response.body

    get edit_memory_path(memory, page: 1)
    assert_response :success
    assert_select "label", "Add picture at editor cursor"
    assert_select "input[type=file][data-action='change->editor#upload']:not([multiple])"
    assert_select "input[type=file][disabled]", count: 0
  end

  test "edit does not expose an image delete control" do
    memory = create_draft_with_page
    get edit_memory_path(memory, page: 1)

    assert_select "button, a", text: /delete picture|delete image|remove picture/i, count: 0
  end

  private

  def create_draft_with_page
    post memories_path
    memory = Memory.order(:id).last
    patch memory_path(memory), params: editor_params(memory, intent: "add_page")
    memory.reload
  end

  def editor_params(record, intent: nil, page: "title", fields: {})
    {
      source_fingerprint: record.reload.source_fingerprint,
      page: page,
      intent: intent,
      memory: fields
    }.compact
  end

  def uploaded_jpeg(path, name)
    Rack::Test::UploadedFile.new(path.to_s, "image/jpeg", true, original_filename: name)
  end

  def with_fake_magick
    success = Open3.capture3("true").last
    Memory::ImageProcessor.stub :magick_available?, true do
      Open3.stub :capture3, lambda { |*argv|
        dest = argv.last
        source = argv[1]
        if argv.first == "magick" && source != dest && File.file?(source.to_s)
          FileUtils.cp(source, dest)
        end
        ["", "", success]
      } do
        yield
      end
    end
  end
end
