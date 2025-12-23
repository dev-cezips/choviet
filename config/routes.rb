Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  # Root route - posts index as the main feed
  root "posts#index"

  # Marketplace shortcut
  get "marketplace", to: "posts#index", defaults: { type: "marketplace" }

  resources :posts do
    resource :like, only: [ :create, :destroy ]
    resources :chat_rooms, only: [ :create, :show ] do
      member do
        patch :update_status
        post :dismiss_review_reminder
      end
      resources :messages, only: [ :new, :create ]
      resources :reviews, only: [ :new, :create ]
    end
    resources :reports, only: [ :new, :create ]
  end

  # Review reactions
  resources :reviews, only: [] do
    resource :reaction, only: [ :create, :update, :destroy ]
  end

  # Standalone chat rooms index
  resources :chat_rooms, only: [ :index ]

  # Message reports
  resources :messages, only: [] do
    resources :reports, only: [ :new, :create ]
  end

  resources :users, only: [ :show ] do
    resources :reports, only: [ :new, :create ]
    member do
      get :listings
    end
  end

  # Profile management (for current user)
  resource :profile, controller: "users", only: [ :edit, :update ] do
    get :edit, action: :edit
    patch :update, action: :update
  end

  resources :communities do
    member do
      post :join
      delete :leave
    end
  end

  resources :categories, only: [ :index, :show ]

  # Products (standalone for Week 3)
  resources :products

  # User dashboard
  resource :dashboard, only: [ :show ], controller: "dashboard"

  # Admin routes
  namespace :admin do
    get "dashboard", to: "dashboard#index"
  end

  # Locale switching
  get "/locale/:locale", to: "application#change_locale", as: :set_locale

  # Static pages
  get "privacy", to: "pages#privacy"
  get "terms", to: "pages#terms"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
