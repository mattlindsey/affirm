class Rack::Attack
  throttle("logins/email", limit: 10, period: 15.minutes) do |req|
    req.params["email"]&.downcase if req.path == "/login" && req.post?
  end

  self.throttled_responder = lambda do |_req|
    body = <<~HTML
      <!DOCTYPE html>
      <html>
        <head><title>Too many requests</title></head>
        <body>
          <h1>Too many sign-in attempts</h1>
          <p>Your account has been temporarily locked after too many failed attempts.
             Please wait 15 minutes before trying again, or use
             <a href="/password_reset">forgot password</a> to regain access.</p>
        </body>
      </html>
    HTML
    [ 429, { "Content-Type" => "text/html; charset=utf-8" }, [ body ] ]
  end
end
