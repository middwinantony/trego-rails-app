Rails.application.routes.draw do
  # API-only application.
  # All routes must live under /api/v1.
  # Do NOT add non-versioned routes.
  namespace :api do
    namespace :v1 do
      # Authentication
      namespace :auth do
        post :signup
        post :login
      end
      # post "auth/signup", to: "auth#signup"
      # post "auth/login", to: "auth#login"

      # Users
      resources :users, only: [:show]

      # Rides (Rider-facing)
      resources :rides, only: %i[create show] do
        member do
          patch :accept
          patch :start
          patch :complete
          patch :cancel
        end
      end

      # admin
      namespace :admin do
        get 'stats/index', to: 'stats#index'
      end

      # driver specific
      namespace :driver do
        resources :rides, only: [:index] do
          member do
            post :accept
            post :start
            post :complete
          end
        end
      end

      get "/rides/available", to: "driver/rides#index"
      post "/rides/:id/accept", to: "driver/rides#accept"
    end
  end
  ##
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
