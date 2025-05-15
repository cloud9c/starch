Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "public#index"

  controller :public do
    get "privacy", action: :privacy, as: :privacy
    get "clear_all", action: :clear_all, as: :clear_all
  end

  resource :session do
    get :code
    post :verify
    get :verify
  end
  resolve("Session") { [ :session ] }

  resource :user do
    resource :billing, only: [ :show ] do
      collection do
        get :required_checkout
        post :create_checkout_session
        get :return
        get :has_paid
      end
    end
  end
  resolve("User") { [ :user ] }

  controller :stripe do
    post "/stripe/webhook", action: :webhook
  end

  resources :subscriptions do
    collection do
      get :avatar_list
    end
  end

  resources :documents do
    member do
      get :preview
    end
  end

  controller :documents do
    get "inbox", action: :index, as: :inbox
    get "later", action: :later, as: :later
    get "archive", action: :archive, as: :archive
    get "search", action: :search, as: :search
    get "feed", action: :feed, as: :feed
  end

  resources :document_states, only: [ :create, :update ] do
    collection do
      post :read_all
      get :toolbar
    end
  end

  mount MissionControl::Jobs::Engine, at: "/jobs"

  get "errors/show"
  match "/:code",
        to: "errors#show",
        via: :all,
        constraints: {
          code: Regexp.new(
            ErrorsController::VALID_STATUS_CODES.join("|")
          )
        }
end
