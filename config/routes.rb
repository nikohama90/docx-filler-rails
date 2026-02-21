Rails.application.routes.draw do
  root "templates#new"

  resources :templates, only: [:new, :create, :show] do
    post :generate, on: :member
  end
end
