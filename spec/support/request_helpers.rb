module RequestHelpers
  def sign_in_test_user
    user = FactoryBot.create(:user)
    post login_path, params: { email: user.email, password: "password123" }
    user
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
