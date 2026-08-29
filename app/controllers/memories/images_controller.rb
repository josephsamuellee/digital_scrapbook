class Memories::ImagesController < ApplicationController
  def create
    @memory = Memory.find(params[:memory_id])
    unless @memory.source_readable?
      render json: { status: "error", message: "This Memory's Markdown file is missing." }, status: :unprocessable_entity
      return
    end

    if params[:source_fingerprint].blank? || Memory::Store.stale?(@memory, params[:source_fingerprint])
      render json: { status: "conflict", message: MemoriesController::STALE_MESSAGE }, status: :conflict
      return
    end

    uploaded = params[:image]
    unless uploaded.respond_to?(:original_filename) && uploaded.respond_to?(:tempfile)
      render json: { status: "error", message: "Choose a picture to upload." }, status: :unprocessable_entity
      return
    end

    result = Memory::ImageProcessor.new(directory: @memory.directory_pathname).process(uploaded)
    document = @memory.document
    key_photo = document.key_photo
    if key_photo.blank?
      Memory::Store.write(
        document.with(key_photo: result.markdown_name),
        memory: @memory,
        expected_fingerprint: params[:source_fingerprint]
      )
      @memory.reload
      key_photo = result.markdown_name
    end

    render json: {
      markdown: result.markdown,
      fingerprint: @memory.source_fingerprint,
      key_photo: key_photo
    }
  rescue Memory::ImageProcessor::Error => error
    render json: {
      status: "error",
      message: "Image processing failed: #{error.message}"
    }, status: :unprocessable_entity
  rescue Memory::Store::StaleError
    render json: { status: "conflict", message: MemoriesController::STALE_MESSAGE }, status: :conflict
  rescue Memory::Store::WriteError
    render json: { status: "error", message: "Could not save Memory." }, status: :unprocessable_entity
  end
end
