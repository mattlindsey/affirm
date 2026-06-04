module Auth
  class ProcessOauthCallbackService
    def self.call(auth_hash)
      uid   = auth_hash.uid
      email = auth_hash.info.email&.downcase
      name  = auth_hash.info.name

      user = User.find_by(google_uid: uid) || User.find_by(email: email)

      if user
        user.update!(google_uid: uid) if user.google_uid.blank?
      else
        user = User.create!(email: email, name: name, google_uid: uid)
      end

      user
    end
  end
end
