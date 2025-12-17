class CanonicalHost
  def initialize(app, canonical_host)
    @app = app
    @canonical_host = canonical_host
  end

  def call(env)
    request = Rack::Request.new(env)
    
    if request.host != @canonical_host
      url = "https://#{@canonical_host}#{request.fullpath}"
      return [301, { "Location" => url, "Content-Type" => "text/plain" }, ["Redirecting..."]]
    end
    
    @app.call(env)
  end
end