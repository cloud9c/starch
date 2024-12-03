Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "landing#index"

  resource :session
  get "session/callback", to: "sessions#callback", as: :session_callback
end
