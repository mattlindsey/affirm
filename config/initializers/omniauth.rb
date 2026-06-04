Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV.fetch("GOOGLE_CLIENT_ID", "placeholder"),
           ENV.fetch("GOOGLE_CLIENT_SECRET", "placeholder"),
           scope: "email,profile"
end
