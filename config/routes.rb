Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  post "appearance", to: "appearances#update", as: :appearance
  resources :memories, only: %i[new create edit update] do
    collection { get :continue }
  end

  root "timeline#index"
end
