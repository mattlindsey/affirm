OmniAuth.config.test_mode = true

module OmniauthHelpers
  def mock_google_auth(uid: "12345", email: "test@example.com", name: "Test User")
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(
        email: email,
        name: name
      )
    )
  end
end

RSpec.configure do |config|
  config.include OmniauthHelpers
end
