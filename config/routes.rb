Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  post "appearance", to: "appearances#update", as: :appearance
  resources :memories, only: :new

  root "timeline#index"
end
