module SystemHelpers
  def sign_in_as_test_user
    user = FactoryBot.create(:user, email: "system_test_#{SecureRandom.hex(4)}@example.com")
    visit login_path
    fill_in "email", with: user.email
    fill_in "password", with: "password123"
    click_button "Sign in"
    user
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
