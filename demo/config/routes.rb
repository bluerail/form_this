Rails.application.routes.draw do
  root 'artists#index'
  resources :artists do
    get :add_album, on: :member
  end
end
