Rails.application.routes.draw do
  get "settings/index"
  get "settings/update"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  # Settings routes
  get "settings", to: "settings#index", as: :settings
  post "settings", to: "settings#update"


  # Welcome screen routes
  get "welcome" => "welcome#index", as: :welcome
  post "welcome/mood" => "welcome#create_mood", as: :welcome_mood

  resources :affirmations, only: [ :index, :destroy ]
  get "gratitude" => "gratitude#index", as: :gratitude
  get "gratitude/random" => "gratitude#random", as: :gratitude_random
  get "gratitude/prompt" => "gratitude#prompt", as: :gratitude_prompt
  get "gratitude/create" => "gratitude#create", as: :create_gratitude
  post "gratitude" => "gratitude#store", as: :store_gratitude
  get "affirmations/random" => "affirmations#random", as: :random_affirmation
  get "affirmations/ai" => "affirmations#ai", as: :ai_affirmation
  get  "settings", to: "settings#index"
  post "settings", to: "settings#update"
end
