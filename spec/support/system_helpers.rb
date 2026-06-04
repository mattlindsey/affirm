module SystemHelpers
  def sign_in_as_test_user
    user = FactoryBot.create(:user, email: "system_test_#{SecureRandom.hex(4)}@example.com")
    visit test_sign_in_path(user_id: user.id)
    user
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
