Rails.application.routes.draw do
  # #region agent log
  post "__debug_log", to: ->(env) {
    body = env["rack.input"].read.to_s
    File.open("/Users/josephlee/Documents/digital_scrapbook/.cursor/debug-396a12.log", "a") { |f| f.puts(body.lines.first.to_s.chomp) }
    [204, { "Content-Type" => "text/plain" }, []]
  }
  # #endregion

  get "up" => "rails/health#show", as: :rails_health_check

  post "appearance", to: "appearances#update", as: :appearance
  resources :memories, only: %i[new create show edit update] do
    collection { get :continue }
    resources :images, only: :create, module: :memories
    get "assets/*filename", to: "memories/assets#show", as: :asset, format: false
  end

  root "timeline#index"
end
