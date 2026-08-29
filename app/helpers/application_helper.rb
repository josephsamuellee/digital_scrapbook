module ApplicationHelper
  def current_appearance
    Appearance.from_cookie(cookies[:appearance])
  end
end
