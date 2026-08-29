class Memories::AssetsController < ApplicationController
  def show
    memory = Memory.find(params[:memory_id])
    filename = requested_filename
    return head :not_found unless filename

    path = memory.directory_pathname.join(filename)
    return head :not_found unless path.file?

    real_file = path.realpath
    real_dir = memory.directory_pathname.realpath
    unless real_file.to_s.start_with?(real_dir.to_s + File::SEPARATOR)
      return head :not_found
    end

    send_file real_file, disposition: "inline"
  end

  private

  def requested_filename
    raw = params[:filename]
    raw = raw.join("/") if raw.is_a?(Array)
    raw = raw.to_s
    return if raw.blank? || raw.include?("\0")
    return if raw.include?("..") || raw.include?("/") || raw.include?("\\")
    return if raw != File.basename(raw)

    raw
  end
end
