class User < ApplicationRecord
  has_secure_password validations: false

  has_one  :setting,         dependent: :destroy
  has_many :conversations,   dependent: :destroy
  has_many :affirmations,    dependent: :destroy
  has_many :gratitudes,      dependent: :destroy
  has_many :mood_check_ins,  dependent: :destroy
  has_many :reflections,     dependent: :destroy

  generates_token_for :password_reset, expires_in: 2.hours do
    password_digest
  end

  before_validation :downcase_email

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, confirmation: true, allow_nil: true
  validates :password_confirmation, presence: true, if: -> { password.present? }
  validate  :password_or_google_uid_present

  private

  def downcase_email
    self.email = email&.downcase
  end

  def password_or_google_uid_present
    return if password_digest.present? || google_uid.present?
    errors.add(:base, "must have either a password or a linked Google account")
  end
end
