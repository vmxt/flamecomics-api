require 'roda'
require 'rack/cors'
require 'json'
require_relative 'router/routes'

class FlamecomicsAPI < Roda
  plugin :json
  plugin :all_verbs

  use Rack::Cors do |config|
    config.allow do |allow|
      allow.origins '*'
      allow.resource '*', headers: :any, methods: %i[get post put patch delete options head]
    end
  end

  route do |r|
    r.run Routes
  end
end
