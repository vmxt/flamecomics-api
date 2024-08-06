require 'sinatra'
require 'rack/cors'
require 'httparty'
require_relative 'router/routes'

PORT = 8000
DOWN = false

configure do
  use Rack::Cors do
    allow do
      origins '*'
      resource '*',
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head]
    end
  end
end

before do
  content_type :json
end

if DOWN
  before do
    halt 500, { status: 500, message: 'API is down.' }.to_json
  end
end

use Routes

not_found do
  { error: 'Route not found' }.to_json
end

error do
  status 500
  { error: env['sinatra.error'].message || 'Internal server error' }.to_json
end

if __FILE__ == $0
  Sinatra::Application.run! port: PORT
end
