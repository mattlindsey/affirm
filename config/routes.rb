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

  # Daily Flow routes
  get "daily_flow", to: "daily_flow#start", as: :daily_flow
  get "daily_flow/start", to: "daily_flow#start", as: :daily_flow_start
  get "daily_flow/check_in", to: "daily_flow#check_in", as: :daily_flow_check_in
  post "daily_flow/check_in", to: "daily_flow#save_check_in", as: :daily_flow_save_check_in
  get "daily_flow/affirmation", to: "daily_flow#affirmation", as: :daily_flow_affirmation
  get "daily_flow/gratitude", to: "daily_flow#gratitude", as: :daily_flow_gratitude
  post "daily_flow/gratitude", to: "daily_flow#save_gratitude", as: :daily_flow_save_gratitude
  get "daily_flow/reflection", to: "daily_flow#reflection", as: :daily_flow_reflection
  post "daily_flow/reflection", to: "daily_flow#save_reflection", as: :daily_flow_save_reflection
  get "daily_flow/completion", to: "daily_flow#completion", as: :daily_flow_completion

  # Settings routes
  get "settings", to: "settings#index", as: :settings
  post "settings", to: "settings#update"

  get "checkins" => "checkins#index", as: :checkins

  resources :affirmations, only: [ :index, :destroy ]
  get "gratitude" => "gratitude#index", as: :gratitude
  get "gratitude/random" => "gratitude#random", as: :gratitude_random
  get "gratitude/prompt" => "gratitude#prompt", as: :gratitude_prompt
  get "reflections" => "reflections#index", as: :reflections
  get "affirmations/random" => "affirmations#random", as: :random_affirmation
  get "affirmations/ai" => "affirmations#ai", as: :ai_affirmation
end
