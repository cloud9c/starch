ALLOWED_IPS = Rails.application.credentials.dig(:tailscale, :allowed_ips) || []

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "home#index"

  resource :session do
    get :verify
    post :verify
  end

  get "search" => "search#index"

  resources :subscriptions
  resources :documents do
    member do
      get :preview
      post :seen
    end
  end


  if Rails.env.development?
    mount MissionControl::Jobs::Engine, at: "/jobs"
  else
    constraints lambda { |request|
      ALLOWED_IPS.include?(request.remote_ip)
    } do
      mount MissionControl::Jobs::Engine, at: "/jobs"
    end
  end
end
