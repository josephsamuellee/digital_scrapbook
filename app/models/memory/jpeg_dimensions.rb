class Memory::JpegDimensions
  SOF_MARKERS = [0xC0, 0xC1, 0xC2, 0xC3].freeze

  def self.read(path)
    return unless path && File.file?(path)

    File.open(path, "rb") do |io|
      return unless io.read(2) == "\xFF\xD8".b

      loop do
        byte = io.getbyte
        return unless byte == 0xFF

        code = io.getbyte
        while code == 0xFF
          code = io.getbyte
        end
        return unless code
        return if code == 0xD9 || code == 0xDA

        length_bytes = io.read(2)
        return unless length_bytes&.bytesize == 2

        length = length_bytes.unpack1("n")
        return if length < 2

        if SOF_MARKERS.include?(code)
          payload = io.read(length - 2)
          return unless payload&.bytesize == length - 2

          height = payload.byteslice(1, 2).unpack1("n")
          width = payload.byteslice(3, 2).unpack1("n")
          return [width, height]
        end

        io.seek(length - 2, IO::SEEK_CUR)
      end
    end
  rescue ArgumentError, EOFError, Errno::ENOENT
    nil
  end
end
