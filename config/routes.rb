Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "documents#index"

  resource :session do
    get :verify
    post :verify
  end

  resources :subscriptions

  resources :documents do
    member do
      get :preview
      post :read
      get :toolbar
    end
  end

  get "later" => "documents#later", as: :later
  get "archive" => "documents#archive", as: :archive
  get "search" => "documents#search", as: :search
  get "feed" => "documents#feed", as: :feed

  namespace :my do
    get :navigation
  end

  mount MissionControl::Jobs::Engine, at: "/jobs"
end
