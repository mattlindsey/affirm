Rails.application.routes.draw do
  # Authentication
  get    "login"                        => "sessions#new",          as: :login
  post   "login"                        => "sessions#create"
  post   "login/guest"                  => "sessions#guest_login",  as: :guest_login
  delete "logout"                       => "sessions#destroy",       as: :logout
  get    "signup"                       => "registrations#new",      as: :signup
  post   "signup"                       => "registrations#create"
  get    "password_reset"               => "password_resets#new",    as: :password_reset
  post   "password_reset"               => "password_resets#create"
  get    "password_reset/edit"          => "password_resets#edit",   as: :edit_password_reset
  patch  "password_reset"               => "password_resets#update"
  get    "/auth/google_oauth2/callback" => "sessions#omniauth"
  get    "/auth/failure"                => "sessions#oauth_failure"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.test?
    get "test/sign_in/:user_id", to: "test/sessions#create", as: :test_sign_in
  end

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
  get    "settings",         to: "settings#index",          as: :settings
  post   "settings",         to: "settings#update"
  delete "settings/api_key", to: "settings#destroy_api_key", as: :settings_api_key

  get "checkins" => "checkins#index", as: :checkins

  resources :conversations, only: %i[index show create] do
    resources :messages, only: %i[create]
  end

  resources :affirmations, only: [ :index, :create, :destroy ]
  get "gratitude" => "gratitude#index", as: :gratitude
  get "gratitude/random" => "gratitude#random", as: :gratitude_random
  get "gratitude/prompt" => "gratitude#prompt", as: :gratitude_prompt
  get "reflections" => "reflections#index", as: :reflections
  get "affirmations/random" => "affirmations#random", as: :random_affirmation
  get "affirmations/ai" => "affirmations#ai", as: :ai_affirmation
end
