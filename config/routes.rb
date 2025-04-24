Rails.application.routes.draw do
  get "errors/show"
  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "documents#index"

  resource :session do
    post :verify
  end
  resolve("Session") { [ :session ] }

  resources :subscriptions

  resources :documents do
    member do
      get :preview
      post :read
      get :toolbar
    end

    collection do
      post :archive_all
      post :read_all
    end
  end

  resources :document_states, only: [ :create, :update ]

  get "later" => "documents#later", as: :later
  get "archive" => "documents#archive", as: :archive
  get "search" => "documents#search", as: :search
  get "feed" => "documents#feed", as: :feed

  namespace :my do
    get :navigation
  end

  mount MissionControl::Jobs::Engine, at: "/jobs"

  match "/:code",
        to: "errors#show",
        via: :all,
        constraints: {
          code: Regexp.new(
            ErrorsController::VALID_STATUS_CODES.join("|")
          )
        }

  get "/privacy" => "public#privacy", as: :privacy
end
