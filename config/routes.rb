Rails.application.routes.draw do
  get "errors/show"
  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "public#index"
  get "/privacy" => "public#privacy", as: :privacy
  get "/sign_in" => "public#sign_in", as: :sign_in
  get "/redirect" => "public#redirect", as: :redirect

  resource :session do
    get :code
    post :verify
    get :verify
    get :authenticated
  end
  resolve("Session") { [ :session ] }

  resource :user
  resolve("User") { [ :user ] }

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

  get "inbox" => "documents#index", as: :inbox
  get "later" => "documents#later", as: :later
  get "archive" => "documents#archive", as: :archive
  get "search" => "documents#search", as: :search
  get "feed" => "documents#feed", as: :feed

  mount MissionControl::Jobs::Engine, at: "/jobs"

  match "/:code",
        to: "errors#show",
        via: :all,
        constraints: {
          code: Regexp.new(
            ErrorsController::VALID_STATUS_CODES.join("|")
          )
        }
end
