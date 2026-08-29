class Memory::Page
  attr_reader :heading, :body

  def initialize(heading: "", body: "")
    @heading = heading.to_s
    @body = body.to_s
  end

  def ==(other)
    other.is_a?(self.class) && heading == other.heading && body == other.body
  end
end
