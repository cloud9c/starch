Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "documents#index"

  resource :session do
    get :verify
    post :verify
  end

  get "search" => "search#index"

  resources :subscriptions
  resources :documents do
    member do
      get :preview
    end
  end

  get "feed" => "documents#feed"

  mount MissionControl::Jobs::Engine, at: "/jobs"
end
