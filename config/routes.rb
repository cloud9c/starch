Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "landing#index"

  resource :session do
    get :magic_link
    post :magic_link
  end
end
