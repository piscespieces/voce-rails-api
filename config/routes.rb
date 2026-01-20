require 'sidekiq/web'

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  # Mount Sidekiq web interface
  mount Sidekiq::Web => '/sidekiq'

  resources :notes, only: [:index, :create, :update, :destroy, :show] do
    post :forward, on: :member
  end
  resources :webhooks do
    collection do
      post :test
    end
  end

  get '/profile', to: 'profile#show'
end
