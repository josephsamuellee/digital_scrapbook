module Appearance
  VALUES = %w[dark light].freeze
  DEFAULT = "dark"

  module_function

  def supported?(value)
    VALUES.include?(value.to_s)
  end

  def normalize(value)
    supported?(value) ? value.to_s : DEFAULT
  end

  def from_cookie(value)
    normalize(value.presence || DEFAULT)
  end
end
