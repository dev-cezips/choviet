Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  # Root route - posts index as the main feed
  root "posts#index"

  # Feed routes
  get "feed", to: "posts#feed"

  # Marketplace shortcut
  get "marketplace", to: "posts#index", defaults: { type: "marketplace" }

  resources :posts do
    resource :like, only: [ :create, :destroy ]
    resource :favorite, only: [ :create, :destroy ]
    # Individual image deletion
    delete "images/:image_id", to: "posts#destroy_image", as: :destroy_image
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

  # Standalone chat rooms index (keeping for backward compatibility)
  resources :chat_rooms, only: [ :index ]

  # New 1:1 chat system (V1)
  resources :conversations, only: [ :index, :show ] do
    resources :conversation_messages, only: [ :create ]
  end

  # Conversation message reports
  resources :conversation_messages, only: [] do
    resources :reports, only: [ :new, :create ]
  end

  # DM shortcut from posts
  post "/posts/:id/dm", to: "conversations#create_from_post", as: :dm_post

  # Message reports
  resources :messages, only: [] do
    resources :reports, only: [ :new, :create ]
  end

  # /me - stable URL for current user profile (Turbo Native deep link)
  get "me", to: "users#me", as: :me

  # /me namespace for current user resources
  namespace :me do
    resources :inquiries, only: [ :index, :show, :update ]
  end

  resources :users, only: [ :show ] do
    resources :reports, only: [ :new, :create ]
    resources :inquiries, only: [ :new, :create ]
    member do
      get :listings
      get :favorites
    end
  end

  # Blocking system
  resources :blocks, only: [ :create, :destroy ]

  # Push notifications
  resources :push_endpoints, only: [ :create, :destroy ]

  # API routes for native apps
  namespace :api do
    namespace :v1 do
      resources :push_endpoints, only: [ :create ] do
        collection do
          delete :destroy
        end
      end
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
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"

    resources :reports, only: [ :index, :show ] do
      member do
        patch :resolve
        patch :dismiss
      end
      collection do
        post :batch_action
      end
    end
  end

  # Locale switching
  get "/locale/:locale", to: "application#change_locale", as: :set_locale

  # Static pages
  get "privacy", to: "pages#privacy"
  get "terms", to: "pages#terms"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Apple App Site Association for Universal Links
  get ".well-known/apple-app-site-association", to: "well_known#apple_app_site_association"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
