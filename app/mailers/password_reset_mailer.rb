class PasswordResetMailer < ApplicationMailer
  def reset(user)
    @user  = user
    @token = user.generate_token_for(:password_reset)
    @url   = edit_password_reset_url(token: @token)
    mail(to: @user.email, subject: "Reset your Affirm password")
  end
end
