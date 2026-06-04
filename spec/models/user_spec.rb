require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

    it "is valid with email and password" do
      expect(user).to be_valid
    end

    it "downcases email before validation" do
      user.email = "TEST@EXAMPLE.COM"
      user.valid?
      expect(user.email).to eq("test@example.com")
    end

    it "rejects a password shorter than 8 characters" do
      user.password = "short"
      user.password_confirmation = "short"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "requires password_confirmation when password is present" do
      user.password_confirmation = nil
      expect(user).not_to be_valid
    end

    it "is invalid when password and confirmation do not match" do
      user.password_confirmation = "different"
      expect(user).not_to be_valid
    end

    context "when Google-only account" do
      subject(:google_user) { build(:user, :google_only) }

      it "is valid without a password" do
        expect(google_user).to be_valid
      end
    end

    context "when neither password_digest nor google_uid is present" do
      it "adds a base error" do
        blank_user = User.new(email: "blank@example.com")
        blank_user.valid?
        expect(blank_user.errors[:base]).to be_present
      end
    end
  end

  describe "#generate_token_for(:password_reset)" do
    let(:saved_user) { create(:user) }

    it "generates a non-empty token" do
      token = saved_user.generate_token_for(:password_reset)
      expect(token).to be_present
    end

    it "resolves back to the user within 2 hours" do
      token = saved_user.generate_token_for(:password_reset)
      found = User.find_by_token_for(:password_reset, token)
      expect(found).to eq(saved_user)
    end

    it "is invalidated after the password changes" do
      token = saved_user.generate_token_for(:password_reset)
      saved_user.update!(password: "newpassword1", password_confirmation: "newpassword1")
      found = User.find_by_token_for(:password_reset, token)
      expect(found).to be_nil
    end
  end
end
