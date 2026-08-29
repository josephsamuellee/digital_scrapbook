class AppearancesController < ApplicationController
  def update
    value = params[:appearance].to_s
    if Appearance.supported?(value)
      cookies.permanent[:appearance] = {
        value: Appearance.normalize(value),
        same_site: :lax
      }
    end

    redirect_back fallback_location: root_path
  end
end
